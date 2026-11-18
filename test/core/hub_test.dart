import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/lan/hub_client.dart';
import 'package:pos_cafe/core/lan/hub_server.dart';
import 'package:pos_cafe/core/lan/lan_auth.dart';
import 'package:pos_cafe/core/lan/lan_info.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

import '../fakes.dart';

DeviceIdentity device(String id, String code, String role) =>
    DeviceIdentity(deviceId: id, deviceCode: code, role: role, tenantId: 't', branchId: 'b', name: code);

/// The Hub and server tablets talking over a REAL local network connection (127.0.0.1).
void main() {
  final hubId = device('hub-1', 'T1', 'hub');
  final tablet = device('tab-2', 'T2', 'pos'); // may NOT take payments
  final terrace = device('tab-3', 'T3', 'pos'); // may take payments
  const lanKey = 'test-lan-key-of-cafe-1';

  late AppDatabase hubDb, tabletDb, terraceDb;
  late OutboxRepository hubOutbox;
  late HubServer server;
  late LanInfo info;
  final clients = <HubClient>[];

  Future<AppDatabase> seeded() async {
    final db = AppDatabase(NativeDatabase.memory());
    final api = FakePosApi()..withFloor();
    await SyncEngine(db, api, OutboxRepository(db), hubId).pullMenu(); // menu, staff (Ahmed), tables
    return db;
  }

  LanInfo lan({String key = lanKey, bool terraceDisabled = false}) => LanInfo(
    lanKey: key,
    hub: HubAddress(deviceId: hubId.deviceId, code: 'T1', addresses: ['127.0.0.1'], port: server.port),
    devices: [
      LanDevice(id: 'hub-1', code: 'T1', name: 'Caisse', role: 'hub', canTakePayments: true, disabled: false),
      LanDevice(id: 'tab-2', code: 'T2', name: 'Tablette', role: 'pos', canTakePayments: false, disabled: false),
      LanDevice(
        id: 'tab-3',
        code: 'T3',
        name: 'Terrasse',
        role: 'pos',
        canTakePayments: true,
        disabled: terraceDisabled,
      ),
    ],
  );

  Future<HubClient> connect(DeviceIdentity who, AppDatabase db, {LanInfo? withInfo}) async {
    final c = HubClient(
      identity: who,
      lanInfo: () async => withInfo ?? info,
      mirror: HubMirror(db),
      retryEvery: const Duration(milliseconds: 100),
    )..start();
    clients.add(c);
    return c;
  }

  Future<void> eventually(Future<bool> Function() condition, {String? reason}) async {
    for (var i = 0; i < 100; i++) {
      if (await condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('timed out: ${reason ?? ''}');
  }

  setUp(() async {
    hubDb = await seeded();
    tabletDb = await seeded();
    terraceDb = await seeded();
    hubOutbox = OutboxRepository(hubDb);
    server = HubServer(db: hubDb, outbox: hubOutbox, identity: hubId, lanInfo: () async => info, port: 0);
    await server.start();
    info = lan();
  });

  tearDown(() async {
    for (final c in clients) {
      await c.stop();
    }
    clients.clear();
    await server.stop();
    await hubDb.close();
    await tabletDb.close();
    await terraceDb.close();
  });

  Future<DiningTableRow> table(AppDatabase db, String id) =>
      (db.select(db.diningTables)..where((t) => t.id.equals(id))).getSingle();
  Future<ProductRow> express(AppDatabase db) => (db.select(db.products)..where((p) => p.id.equals('p1'))).getSingle();
  Future<OrderRow?> hubOrderAt(String tableId) =>
      OrderRepository(hubDb, hubOutbox).watchOpenOrder(tableId: tableId).first;

  test(
    'a server orders on the tablet → the order is on the Hub, signed by the server; the tablet sees it live',
    () async {
      final c = await connect(tablet, tabletDb);
      await eventually(() async => c.link.connected, reason: 'tablet connects');
      expect(server.tabletCount, 1);

      final actions = HubOrderActions(c, staffId: () => 'staff-ahmed');
      await actions.addProduct(await express(tabletDb), table: await table(tabletDb, 'table-2'));
      await actions.addProduct(await express(tabletDb), table: await table(tabletDb, 'table-2'));

      // On the Hub: one ticket at table 2 with 2 Express, events by Ahmed (in the Hub's outbox).
      final order = (await hubOrderAt('table-2'))!;
      final lines = await OrderRepository(hubDb, hubOutbox).watchLines(order.id).first;
      expect(lines.map((l) => (l.name, l.qty)), [('Express', 2)]);
      final events = await hubOutbox.pending();
      expect(events.map((e) => (e.type, e.staffId)), [
        ('order.opened', 'staff-ahmed'),
        ('order.item_added', 'staff-ahmed'),
        ('order.item_updated', 'staff-ahmed'),
      ]);
      // The tablet records nothing itself: only the Hub syncs tickets.
      expect(await OutboxRepository(tabletDb).pending(), isEmpty);

      // The tablet's screen data follows the Hub.
      await eventually(() async {
        final mirrored = await OrderRepository(tabletDb, OutboxRepository(tabletDb)).watchOpenTickets().first;
        return mirrored.length == 1 && mirrored.single.total == const Money(2400) && mirrored.single.tableLabel == '2';
      }, reason: 'tablet mirror');
    },
  );

  test('the cashier adds on the Hub → every tablet sees it; a move on the tablet frees the table everywhere', () async {
    final c = await connect(tablet, tabletDb);
    await eventually(() async => c.link.connected);
    final hubRepo = OrderRepository(hubDb, hubOutbox);
    await hubRepo.addProduct(await express(hubDb), table: await table(hubDb, 'table-1'));

    final tabletRepo = OrderRepository(tabletDb, OutboxRepository(tabletDb));
    await eventually(() async => (await tabletRepo.watchOpenOrder(tableId: 'table-1').first) != null);

    final orderId = (await hubOrderAt('table-1'))!.id;
    await HubOrderActions(c, staffId: () => 'staff-ahmed').moveOrder(orderId, await table(tabletDb, 'table-3'));
    expect(await hubOrderAt('table-1'), isNull);
    expect((await hubOrderAt('table-3'))!.id, orderId);
    await eventually(() async => (await tabletRepo.watchOpenOrder(tableId: 'table-3').first) != null);
  });

  test('payment rights: the server tablet is refused; it asks for the bill; the terrace POS may pay', () async {
    final c = await connect(tablet, tabletDb);
    final t = await connect(terrace, terraceDb);
    await eventually(() async => c.link.connected && t.link.connected);
    final server2 = HubOrderActions(c, staffId: () => 'staff-ahmed');
    await server2.addProduct(await express(tabletDb), table: await table(tabletDb, 'table-4'));
    final orderId = (await hubOrderAt('table-4'))!.id;

    await expectLater(
      server2.pay(orderId, const PaymentRequest.card(amount: Money(1200)), deviceCode: 'T2'),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Cette caisse ne peut pas encaisser.')),
    );

    await server2.requestBill(orderId);
    final tickets = await OrderRepository(hubDb, hubOutbox).watchOpenTickets().first;
    expect(tickets.single.billRequested, isTrue);
    expect((await hubOutbox.pending()).last.type, 'order.bill_requested');

    final r = await HubOrderActions(
      t,
      staffId: () => 'staff-ahmed',
    ).pay(orderId, const PaymentRequest.cash(amount: Money(1200), tendered: Money.dt(2)), deviceCode: 'T3');
    // One receipt sequence for the café: the Hub's.
    expect((r.closed, r.receiptNumber, r.change), (true, 'T1-000001', const Money(800)));
    expect(await hubOrderAt('table-4'), isNull);
    await eventually(
      () async => (await OrderRepository(terraceDb, OutboxRepository(terraceDb)).watchOpenTickets().first).isEmpty,
    );
  });

  test('refusals from the Hub come back as French messages (paid line, unknown staff)', () async {
    final c = await connect(tablet, tabletDb);
    await eventually(() async => c.link.connected);
    await expectLater(
      HubOrderActions(c, staffId: () => 'staff-nobody').addProduct(await express(tabletDb)),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('Personnel inconnu'))),
    );
    await expectLater(
      HubOrderActions(c, staffId: () => 'staff-ahmed').setQty('no-such-line', 2),
      throwsA(isA<Object>()),
    );
  });

  test('security: wrong LAN key or disabled device never connects; unsigned requests are refused', () async {
    final stranger = await connect(tablet, tabletDb, withInfo: lan(key: 'another-cafe-key'));
    info = lan(terraceDisabled: true);
    final disabled = await connect(terrace, terraceDb);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(stranger.link.connected, isFalse);
    expect(disabled.link.connected, isFalse);
    expect(server.tabletCount, 0);

    final http = HttpClient();
    final req = await http.postUrl(Uri.parse('http://127.0.0.1:${server.port}/hub/command'));
    req.write(jsonEncode({'action': 'cancel', 'orderId': 'x'}));
    final res = await req.close();
    expect(res.statusCode, 401);
    http.close(force: true);
  });

  test('the same request sent twice (bad Wi-Fi retry) runs only once', () async {
    final body = jsonEncode({
      'requestId': 'req-1',
      'staffId': 'staff-ahmed',
      'action': 'add_product',
      'productId': 'p1',
      'tableId': 'table-2',
      'modifiers': [],
    });
    Future<int> send() async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final sig = await LanSigner(
        lanKey,
      ).sign(method: 'POST', path: '/hub/command', deviceId: 'tab-2', timestampMs: ts, body: body);
      final http = HttpClient();
      final req = await http.postUrl(Uri.parse('http://127.0.0.1:${server.port}/hub/command'));
      req.headers
        ..set(HubProtocol.deviceHeader, 'tab-2')
        ..set(HubProtocol.timestampHeader, '$ts')
        ..set(HubProtocol.signatureHeader, sig);
      req.write(body);
      final res = await req.close();
      await res.drain<void>();
      http.close(force: true);
      return res.statusCode;
    }

    expect([await send(), await send()], [200, 200]);
    final order = (await hubOrderAt('table-2'))!;
    expect((await OrderRepository(hubDb, hubOutbox).watchLines(order.id).first).single.qty, 1);
  });

  test('Hub unreachable → the tablet says so and the order is not sent', () async {
    final c = await connect(tablet, tabletDb);
    await eventually(() async => c.link.connected);
    await server.stop();
    await eventually(() async => !c.link.connected, reason: 'tablet notices the Hub is gone');
    await expectLater(
      HubOrderActions(c, staffId: () => 'staff-ahmed').addProduct(await express(tabletDb)),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('injoignable'))),
    );
    // Restart for tearDown.
    server = HubServer(db: hubDb, outbox: hubOutbox, identity: hubId, lanInfo: () async => info, port: 0);
    await server.start();
  });

  test('LAN signatures: right key and time pass; wrong key, changed body or old timestamp fail', () async {
    final now = DateTime.utc(2026, 11, 18, 10);
    final ts = now.millisecondsSinceEpoch;
    final s = LanSigner('k');
    final sig = await s.sign(method: 'POST', path: '/hub/command', deviceId: 'd', timestampMs: ts, body: '{}');
    Future<bool> check({String key = 'k', String body = '{}', int? at}) => LanSigner(key).verify(
      method: 'POST',
      path: '/hub/command',
      deviceId: 'd',
      timestampMs: ts,
      signature: sig,
      now: at == null ? now : DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
      body: body,
    );
    expect(await check(), isTrue);
    expect(await check(key: 'other'), isFalse);
    expect(await check(body: '{"amount":1}'), isFalse);
    expect(await check(at: ts + const Duration(minutes: 11).inMilliseconds), isFalse);
  });
}
