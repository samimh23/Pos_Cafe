import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../features/cash/data/cash_repository.dart';
import '../../features/order/data/order_repository.dart';
import '../db/app_database.dart';
import '../device/device_repository.dart';
import '../menu/modifiers.dart';
import '../money/money.dart';
import '../sync/outbox_repository.dart';
import 'lan_auth.dart';
import 'lan_info.dart';

/// The small server inside the main POS (Hub). Server tablets on the café Wi-Fi:
/// - receive the open tickets live (`GET /hub/live`, WebSocket), and
/// - send their actions (`POST /hub/command`): the Hub runs them on ITS database,
///   so there is one source of truth and no conflict on "table 4".
/// Only the Hub syncs tickets with the cloud.
class HubServer {
  HubServer({
    required AppDatabase db,
    required OutboxRepository outbox,
    required DeviceIdentity identity,
    required Future<LanInfo?> Function() lanInfo,
    int port = HubProtocol.port,
    DateTime Function()? clock,
  }) : _db = db,
       _outbox = outbox,
       _identity = identity,
       _lanInfo = lanInfo,
       _requestedPort = port,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final DeviceIdentity _identity;
  final Future<LanInfo?> Function() _lanInfo;
  final DateTime Function() _now;

  /// 0 = any free port (tests).
  final int _requestedPort;

  /// The port actually listened on.
  int get port => _server?.port ?? _requestedPort;

  HttpServer? _server;
  StreamSubscription<void>? _changes;
  Timer? _debounce;
  final _sockets = <WebSocket>{};
  final _tablets = StreamController<int>.broadcast();

  /// Answers already given, by request id: a request sent twice (bad Wi-Fi, retry) runs once.
  final _done = <String, Map<String, Object?>>{}; // insertion-ordered: oldest first

  /// Number of tablets connected right now (shown on the Hub).
  Stream<int> get connectedTablets => _tablets.stream;
  int get tabletCount => _sockets.length;

  /// Starts listening on every network interface. Returns the port.
  Future<int> start() async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, _requestedPort);
    if (_stopped) {
      // The app closed while the port was opening: don't leave a server running.
      await server.close(force: true);
      throw StateError('Hub server stopped before it started');
    }
    _server = server;
    server.listen((req) => _handle(req).catchError((Object e) => _reply(req.response, 500, {'error': '$e'})));
    // Any change to tickets (from this POS or a tablet) → every tablet gets the new list.
    _changes = _db
        .tableUpdates(TableUpdateQuery.onAllTables([_db.orders, _db.orderLines, _db.payments, _db.cashSessions]))
        .listen((_) => _scheduleBroadcast());
    return server.port;
  }

  bool _stopped = false;

  Future<void> stop() async {
    _stopped = true;
    // Close the listening socket FIRST, synchronously: it also cancels the HTTP
    // server's idle timer, even if the rest of the shutdown never gets to run.
    final closing = _server?.close(force: true);
    _debounce?.cancel();
    await _changes?.cancel();
    for (final s in [..._sockets]) {
      await s.close();
    }
    _sockets.clear();
    await closing;
    await _tablets.close();
  }

  // ── Requests ─────────────────────────────────────────────

  Future<void> _handle(HttpRequest req) async {
    try {
      await _route(req);
    } on _HubError catch (e) {
      _reply(req.response, e.status, {'ok': false, 'error': e.message});
    }
  }

  Future<void> _route(HttpRequest req) async {
    final path = req.uri.path;
    if (path == '/hub/live' && WebSocketTransformer.isUpgradeRequest(req)) return _live(req);
    if (path == '/hub/ping' && req.method == 'GET') {
      await _authenticate(req, body: '');
      return _reply(req.response, 200, {'hubDeviceId': _identity.deviceId, 'code': _identity.deviceCode});
    }
    if (path == '/hub/command' && req.method == 'POST') {
      final body = await utf8.decoder.bind(req).join();
      final device = await _authenticate(req, body: body);
      final (status, json) = await _command(device, jsonDecode(body) as Map<String, dynamic>);
      return _reply(req.response, status, json);
    }
    return _reply(req.response, 404, {'error': 'Not found'});
  }

  Future<void> _live(HttpRequest req) async {
    final q = req.uri.queryParameters;
    try {
      await _check(
        method: 'GET',
        path: '/hub/live',
        deviceId: q['device'],
        timestamp: q['ts'],
        signature: q['sig'],
        body: '',
      );
    } on _HubError catch (e) {
      return _reply(req.response, e.status, {'error': e.message});
    }
    final ws = await WebSocketTransformer.upgrade(req);
    ws.pingInterval = const Duration(seconds: 10); // notices a tablet that left the Wi-Fi
    _sockets.add(ws);
    _tablets.add(_sockets.length);
    ws.add(jsonEncode(await snapshot()));
    ws.listen(
      (_) {},
      onDone: () {
        _sockets.remove(ws);
        if (!_tablets.isClosed) _tablets.add(_sockets.length);
      },
      cancelOnError: true,
    );
  }

  Future<LanDevice> _authenticate(HttpRequest req, {required String body}) => _check(
    method: req.method,
    path: req.uri.path,
    deviceId: req.headers.value(HubProtocol.deviceHeader),
    timestamp: req.headers.value(HubProtocol.timestampHeader),
    signature: req.headers.value(HubProtocol.signatureHeader),
    body: body,
  );

  /// Only devices of this café (signed with its LAN key), not disabled.
  Future<LanDevice> _check({
    required String method,
    required String path,
    required String? deviceId,
    required String? timestamp,
    required String? signature,
    required String body,
  }) async {
    final info = await _lanInfo();
    if (info == null) throw const _HubError(503, 'Caisse principale pas encore synchronisée.');
    final ts = int.tryParse(timestamp ?? '');
    if (deviceId == null || ts == null || signature == null) throw const _HubError(401, 'Signature manquante.');
    final ok = await LanSigner(info.lanKey).verify(
      method: method,
      path: path,
      deviceId: deviceId,
      timestampMs: ts,
      signature: signature,
      now: _now(),
      body: body,
    );
    if (!ok) throw const _HubError(401, 'Signature invalide (horloge de la tablette ou autre café).');
    final device = info.device(deviceId);
    if (device == null) throw const _HubError(403, 'Caisse inconnue. Synchronisez la caisse principale.');
    if (device.disabled) throw const _HubError(403, 'Cette caisse a été désactivée par le propriétaire.');
    return device;
  }

  // ── Commands from tablets ────────────────────────────────

  Future<(int, Map<String, Object?>)> _command(LanDevice device, Map<String, dynamic> c) async {
    final requestId = c['requestId'] as String?;
    if (requestId != null && _done.containsKey(requestId)) return (200, _done[requestId]!);

    final (status, json) = await _run(device, c);
    if (requestId != null && status == 200) {
      _done[requestId] = json;
      if (_done.length > 500) _done.remove(_done.keys.first);
    }
    return (status, json);
  }

  Future<(int, Map<String, Object?>)> _run(LanDevice device, Map<String, dynamic> c) async {
    final staffId = c['staffId'] as String?;
    if (staffId == null ||
        await (_db.select(_db.staffMembers)..where((s) => s.id.equals(staffId))).getSingleOrNull() == null) {
      return (403, _error('Personnel inconnu sur la caisse principale. Synchronisez-la.'));
    }
    // Events say WHO did it (the server logged in on the tablet).
    final repo = OrderRepository(_db, _outbox, staffId: () => staffId, clock: _now);
    try {
      switch (c['action']) {
        case 'add_product':
          final product =
              await (_db.select(_db.products)..where((p) => p.id.equals(c['productId'] as String))).getSingleOrNull();
          if (product == null) return (409, _error('Produit inconnu sur la caisse principale (menu pas à jour).'));
          await repo.addProduct(
            product,
            table: await _table(c['tableId'] as String?),
            modifiers: [
              for (final m in (c['modifiers'] as List? ?? const []))
                ModifierOption.fromJson((m as Map).cast<String, dynamic>()),
            ],
          );
        case 'set_qty':
          await repo.setQty(c['lineId'] as String, c['qty'] as int);
        case 'remove_line':
          await repo.removeLine(c['lineId'] as String);
        case 'cancel':
          await repo.cancelOrder(c['orderId'] as String);
        case 'move':
          await repo.moveOrder(c['orderId'] as String, await _table(c['tableId'] as String?));
        case 'request_bill':
          await repo.requestBill(c['orderId'] as String);
        case 'pay':
          if (!device.canTakePayments) return (403, _error('Cette caisse ne peut pas encaisser.'));
          final amount = Money(c['amount'] as int);
          final lineIds = ((c['lineIds'] as List?) ?? const []).cast<String>();
          final req =
              c['method'] == 'card'
                  ? PaymentRequest.card(amount: amount, lineIds: lineIds)
                  : PaymentRequest.cash(amount: amount, tendered: Money(c['tendered'] as int), lineIds: lineIds);
          // Cash goes into the drawer of the POS that took it (the tablet's own drawer).
          final r = await repo.pay(c['orderId'] as String, req, deviceCode: _identity.deviceCode, drawerId: device.id);
          return (
            200,
            {
              'ok': true,
              'result': {
                'receiptNumber': r.receiptNumber,
                'amount': r.amount.millimes,
                'change': r.change.millimes,
                'remaining': r.remaining.millimes,
                'total': r.total.millimes,
              },
            },
          );
        case 'cash_open' || 'cash_move' || 'cash_summary' || 'cash_close':
          return await _cash(device, staffId, c);
        default:
          return (400, _error('Action inconnue : ${c['action']}'));
      }
      return (200, {'ok': true});
    } on OrderException catch (e) {
      return (409, _error(e.message));
    }
  }

  /// A tablet's own cash drawer, kept on the main POS like its tickets.
  Future<(int, Map<String, Object?>)> _cash(LanDevice device, String staffId, Map<String, dynamic> c) async {
    if (!device.canTakePayments) return (403, _error('Cette caisse ne peut pas encaisser.'));
    final cash = CashRepository(
      _db,
      _outbox,
      drawerId: device.id,
      staffId: () => staffId,
      clock: _now,
      checkOpenTickets: false, // tickets belong to the whole café, not to this drawer
    );
    switch (c['action']) {
      case 'cash_open':
        await cash.open(Money(c['openingFloat'] as int));
      case 'cash_move':
        await cash.move(cashIn: c['type'] == 'in', amount: Money(c['amount'] as int), reason: c['reason'] as String);
      case 'cash_summary':
        return (200, {'ok': true, 'result': (await cash.summary())?.toJson()});
      case 'cash_close':
        final closing = await cash.close(counted: Money(c['counted'] as int), note: c['note'] as String?);
        return (200, {'ok': true, 'result': closing.toJson()});
    }
    return (200, {'ok': true});
  }

  Future<DiningTableRow?> _table(String? id) async {
    if (id == null) return null;
    final t = await (_db.select(_db.diningTables)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (t == null) throw const OrderException('Table inconnue sur la caisse principale.');
    return t;
  }

  Map<String, Object?> _error(String message) => {'ok': false, 'error': message};

  // ── Live tickets ─────────────────────────────────────────

  /// Open tickets with their lines and payments — a few KB even when the café is full.
  Future<Map<String, Object?>> snapshot() async {
    final orders = await (_db.select(_db.orders)..where((o) => o.status.equals('open'))).get();
    final ids = [for (final o in orders) o.id];
    final lines =
        ids.isEmpty
            ? <OrderLineRow>[]
            : await (_db.select(_db.orderLines)..where((l) => l.orderId.isIn(ids) & l.voided.equals(false))).get();
    final payments =
        ids.isEmpty ? <PaymentRow>[] : await (_db.select(_db.payments)..where((p) => p.orderId.isIn(ids))).get();
    final cashSessions = await (_db.select(_db.cashSessions)..where((s) => s.status.equals('open'))).get();
    return {
      'type': 'snapshot',
      'hub': _identity.deviceCode,
      'orders': [for (final o in orders) o.toJson()],
      'lines': [for (final l in lines) l.toJson()],
      'payments': [for (final p in payments) p.toJson()],
      // So each tablet knows whether ITS drawer is open.
      'cashSessions': [for (final s in cashSessions) s.toJson()],
    };
  }

  void _scheduleBroadcast() {
    _debounce?.cancel();
    // Several writes of one action (line + event…) → one message.
    _debounce = Timer(const Duration(milliseconds: 30), () async {
      if (_sockets.isEmpty) return;
      final msg = jsonEncode(await snapshot());
      for (final s in [..._sockets]) {
        s.add(msg);
      }
    });
  }

  void _reply(HttpResponse res, int status, Map<String, Object?> json) {
    res
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(json));
    res.close();
  }
}

class _HubError implements Exception {
  final int status;
  final String message;
  const _HubError(this.status, this.message);
}
