import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../features/cash/data/cash_repository.dart';
import '../../features/order/data/discounts.dart';
import '../../features/order/data/order_repository.dart';
import '../../features/print/print_service.dart';
import '../db/app_database.dart';
import '../device/device_repository.dart';
import '../ids.dart';
import '../menu/modifiers.dart';
import '../money/money.dart';
import 'lan_auth.dart';
import 'lan_info.dart';

enum HubLinkState { connecting, connected, unreachable }

/// How a server tablet is connected to the Hub — shown on screen.
class HubLink {
  final HubLinkState state;

  /// "192.168.1.20:7700" when connected.
  final String? address;
  final String? error;
  const HubLink(this.state, {this.address, this.error});
  bool get connected => state == HubLinkState.connected;
}

/// Copies the Hub's open tickets into this tablet's database, so the usual
/// screens (tables, ticket) show them live. The tablet never edits them itself.
class HubMirror {
  HubMirror(this._db);
  final AppDatabase _db;

  Future<void> apply(Map<String, dynamic> snapshot) => _db.transaction(() async {
    await _db.delete(_db.payments).go();
    await _db.delete(_db.orderLines).go();
    await _db.delete(_db.orders).go();
    await _db.delete(_db.cashSessions).go();
    await _db.batch((b) {
      b.insertAll(_db.orders, [for (final o in snapshot['orders'] as List) OrderRow.fromJson(_map(o))]);
      b.insertAll(_db.orderLines, [for (final l in snapshot['lines'] as List) OrderLineRow.fromJson(_map(l))]);
      b.insertAll(_db.payments, [for (final p in snapshot['payments'] as List) PaymentRow.fromJson(_map(p))]);
      b.insertAll(_db.cashSessions, [
        for (final s in (snapshot['cashSessions'] as List? ?? const [])) CashSessionRow.fromJson(_map(s)),
      ]);
    });
  });

  static Map<String, dynamic> _map(Object? o) => (o as Map).cast<String, dynamic>();
}

/// A server tablet's link to the Hub: keeps a live connection (reconnects by
/// itself) and sends the tablet's actions to the Hub, signed with the LAN key.
class HubClient {
  HubClient({
    required DeviceIdentity identity,
    required Future<LanInfo?> Function() lanInfo,
    required HubMirror mirror,
    this.retryEvery = const Duration(seconds: 3),
    this.extraAddresses = const [],
  }) : _identity = identity,
       _lanInfo = lanInfo,
       _mirror = mirror;

  final DeviceIdentity _identity;
  final Future<LanInfo?> Function() _lanInfo;
  final HubMirror _mirror;
  final Duration retryEvery;

  /// Also tried, after the addresses the Hub reported ("127.0.0.1:7700" when both run on one PC).
  final List<String> extraAddresses;

  final _status = StreamController<HubLink>.broadcast();
  HubLink _link = const HubLink(HubLinkState.connecting);
  WebSocket? _ws;
  bool _stopped = false;
  Timer? _retry;
  Completer<void>? _wait;

  Stream<HubLink> get status => _status.stream;
  HubLink get link => _link;

  void start() => unawaited(_loop());

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    if (!(_wait?.isCompleted ?? true)) _wait!.complete();
    await _ws?.close();
    await _status.close();
  }

  void _set(HubLink l) {
    _link = l;
    if (!_status.isClosed) _status.add(l);
  }

  Future<void> _loop() async {
    while (!_stopped) {
      final info = await _lanInfo();
      final hub = info?.hub;
      if (info == null || hub == null) {
        _set(const HubLink(HubLinkState.unreachable, error: 'Aucune caisse principale dans ce café.'));
      } else {
        final port = hub.port ?? HubProtocol.port;
        final candidates = {for (final a in hub.addresses) '$a:$port', ...extraAddresses};
        // All addresses at once (a PC has several network cards, some unreachable): the first that answers wins.
        final first = await _firstConnection(info, candidates);
        if (_stopped) {
          await first?.$1.close();
          return;
        }
        if (first != null) await _listen(first.$1, first.$2); // returns when the connection drops
        if (!_link.connected) {
          _set(
            HubLink(
              HubLinkState.unreachable,
              error:
                  candidates.isEmpty
                      ? 'La caisse principale n’a pas encore donné son adresse.'
                      : 'Caisse principale injoignable. Vérifiez qu’elle est allumée et sur le même Wi-Fi.',
            ),
          );
        }
      }
      if (_stopped) return;
      // Cancellable wait: stop() ends it right away.
      _wait = Completer<void>();
      _retry = Timer(retryEvery, () => _wait!.complete());
      await _wait!.future;
    }
  }

  /// Tries every address in parallel; returns the first connection accepted by the Hub.
  Future<(WebSocket, String)?> _firstConnection(LanInfo info, Iterable<String> candidates) {
    final list = candidates.toList();
    if (list.isEmpty) return Future.value(null);
    final winner = Completer<(WebSocket, String)?>();
    var pending = list.length;
    for (final address in list) {
      _open(info, address).then((ws) {
        if (ws != null && !winner.isCompleted) {
          winner.complete((ws, address));
        } else {
          ws?.close(); // a slower address also answered: not needed
        }
        if (--pending == 0 && !winner.isCompleted) winner.complete(null);
      });
    }
    return winner.future;
  }

  /// Opens the signed live connection to one address, or null if it doesn't answer / refuses.
  Future<WebSocket?> _open(LanInfo info, String address) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sig = await LanSigner(
        info.lanKey,
      ).sign(method: 'GET', path: '/hub/live', deviceId: _identity.deviceId, timestampMs: ts);
      final uri = Uri.parse(
        'ws://$address/hub/live',
      ).replace(queryParameters: {'device': _identity.deviceId, 'ts': '$ts', 'sig': sig});
      return await WebSocket.connect(uri.toString()).timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  /// Copies every snapshot until the connection drops.
  Future<void> _listen(WebSocket ws, String address) async {
    ws.pingInterval = const Duration(seconds: 10);
    _ws = ws;
    _set(HubLink(HubLinkState.connected, address: address));
    try {
      await for (final msg in ws) {
        final json = jsonDecode(msg as String) as Map<String, dynamic>;
        if (json['type'] == 'snapshot') await _mirror.apply(json);
      }
    } catch (_) {
      // connection lost
    }
    _ws = null;
    _set(const HubLink(HubLinkState.connecting));
  }

  /// Sends one action to the Hub. Throws [OrderException] with a French message
  /// (refused by the Hub, or Hub unreachable).
  Future<Map<String, dynamic>> command(String action, Map<String, Object?> params, {required String? staffId}) async {
    final address = _link.address;
    final info = await _lanInfo();
    if (!_link.connected || address == null || info == null) {
      throw const OrderException('Caisse principale injoignable : la commande n’a pas été envoyée.');
    }
    final body = jsonEncode({'requestId': newId(), 'staffId': staffId, 'action': action, ...params});
    final ts = DateTime.now().millisecondsSinceEpoch;
    final sig = await LanSigner(
      info.lanKey,
    ).sign(method: 'POST', path: '/hub/command', deviceId: _identity.deviceId, timestampMs: ts, body: body);

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.postUrl(Uri.parse('http://$address/hub/command'));
      req.headers
        ..contentType = ContentType.json
        ..set(HubProtocol.deviceHeader, _identity.deviceId)
        ..set(HubProtocol.timestampHeader, '$ts')
        ..set(HubProtocol.signatureHeader, sig);
      req.write(body);
      final res = await req.close().timeout(const Duration(seconds: 5));
      final json = jsonDecode(await utf8.decoder.bind(res).join()) as Map<String, dynamic>;
      if (json['ok'] != true) throw OrderException((json['error'] as String?) ?? 'Refusé par la caisse principale.');
      return json;
    } on OrderException {
      rethrow;
    } catch (_) {
      throw const OrderException('Caisse principale injoignable : la commande n’a pas été envoyée.');
    } finally {
      client.close(force: true);
    }
  }
}

/// Order actions of a server tablet: everything goes to the Hub.
class HubOrderActions implements OrderActions {
  HubOrderActions(this._client, {required String? Function() staffId}) : _staffId = staffId;
  final HubClient _client;
  final String? Function() _staffId;

  Future<Map<String, dynamic>> _send(String action, Map<String, Object?> params) =>
      _client.command(action, params, staffId: _staffId());

  @override
  Future<void> addProduct(ProductRow p, {DiningTableRow? table, List<ModifierOption> modifiers = const []}) =>
      _send('add_product', {
        'productId': p.id,
        'tableId': table?.id,
        'modifiers': [for (final m in modifiers) m.toJson()],
      });

  @override
  Future<void> setQty(String lineId, int qty) => _send('set_qty', {'lineId': lineId, 'qty': qty});

  @override
  Future<void> removeLine(String lineId) => _send('remove_line', {'lineId': lineId});

  @override
  Future<void> cancelOrder(String orderId) => _send('cancel', {'orderId': orderId});

  @override
  Future<void> moveOrder(String orderId, DiningTableRow? to) => _send('move', {'orderId': orderId, 'tableId': to?.id});

  @override
  Future<void> requestBill(String orderId) => _send('request_bill', {'orderId': orderId});

  @override
  Future<void> discount(String orderId, DiscountRequest request) =>
      _send('discount', {'orderId': orderId, ...request.toJson()});

  @override
  Future<void> removeDiscount(String orderId, List<String> lineIds) =>
      _send('remove_discount', {'orderId': orderId, 'lineIds': lineIds});

  @override
  Future<PaymentResult> pay(
    String orderId,
    PaymentRequest req, {
    required String deviceCode,
    required String drawerId, // the main POS knows: this tablet's drawer
  }) async {
    final r =
        (await _send('pay', {
              'orderId': orderId,
              'method': req.method,
              'amount': req.amount.millimes,
              'tendered': req.tendered.millimes,
              'lineIds': req.lineIds,
            }))['result']
            as Map<String, dynamic>;
    return PaymentResult(
      receiptNumber: r['receiptNumber'] as String?,
      amount: Money(r['amount'] as int),
      change: Money(r['change'] as int),
      remaining: Money(r['remaining'] as int),
      total: Money(r['total'] as int),
    );
  }
}

/// Cash drawer of a tablet allowed to take payments: the session lives on the main POS.
class HubCashActions implements CashActions {
  HubCashActions(this._client, {required String? Function() staffId}) : _staffId = staffId;
  final HubClient _client;
  final String? Function() _staffId;

  Future<Map<String, dynamic>> _send(String action, Map<String, Object?> params) =>
      _client.command(action, params, staffId: _staffId());

  @override
  Future<void> open(Money openingFloat) => _send('cash_open', {'openingFloat': openingFloat.millimes});

  @override
  Future<void> move({required bool cashIn, required Money amount, required String reason}) =>
      _send('cash_move', {'type': cashIn ? 'in' : 'out', 'amount': amount.millimes, 'reason': reason});

  @override
  Future<CashSummary?> summary() async {
    final r = (await _send('cash_summary', {}))['result'];
    return r == null ? null : CashSummary.fromJson((r as Map).cast<String, dynamic>());
  }

  @override
  Future<CashClosing> close({required Money counted, String? note}) async => CashClosing.fromJson(
    ((await _send('cash_close', {'counted': counted.millimes, 'note': note}))['result'] as Map).cast<String, dynamic>(),
  );
}

/// A tablet prints on the main POS's printers.
class HubPrintActions implements PrintActions {
  HubPrintActions(this._client, {required String? Function() staffId}) : _staffId = staffId;
  final HubClient _client;
  final String? Function() _staffId;

  @override
  Future<SendResult> sendOrder(String orderId) async {
    final r = await _client.command('send_order', {'orderId': orderId}, staffId: _staffId());
    return SendResult(((r['printed'] as Map?) ?? const {}).cast<String, int>());
  }

  @override
  Future<void> printBill(String orderId) => _client.command('print_bill', {'orderId': orderId}, staffId: _staffId());

  @override
  Future<void> printReceipt(String orderId) =>
      _client.command('print_receipt', {'orderId': orderId}, staffId: _staffId());
}
