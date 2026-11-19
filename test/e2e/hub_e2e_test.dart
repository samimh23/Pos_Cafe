// End-to-end against a REAL running backend, over the REAL local network:
// a Hub and a server tablet are paired, the Hub reports its Wi-Fi address,
// the tablet finds it through the cloud and orders through it.
// Skipped unless E2E_HUB=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_HUB=1 flutter test test/e2e/hub_e2e_test.dart
@Tags(['e2e'])
library;

import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/lan/hub_client.dart';
import 'package:pos_cafe/core/lan/hub_server.dart';
import 'package:pos_cafe/core/lan/lan_info.dart';
import 'package:pos_cafe/core/lan/lan_providers.dart' show localAddresses;
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'Hub + server tablet through the cloud and the café network; owner sees the table sale',
    () async {
      // ── Owner sets up the café ──
      final owner = Dio(BaseOptions(baseUrl: url));
      final password = List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[Random.secure().nextInt(32)]).join();
      final s =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'hub${DateTime.now().millisecondsSinceEpoch}@example.test',
              'password': password,
              'name': 'Owner',
              'businessName': 'Café Hub E2E',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${s['accessToken']}';
      final branch = s['branches'][0]['id'];
      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Café'})).data;
      await owner.post(
        '/v1/owner/branches/$branch/products',
        data: {'name': 'Express', 'price': 1200, 'categoryId': cat['id']},
      );
      final salle = (await owner.post('/v1/owner/branches/$branch/areas', data: {'name': 'Salle'})).data;
      await owner.post(
        '/v1/owner/branches/$branch/tables',
        data: {
          'areaId': salle['id'],
          'names': ['1', '2', '3'],
        },
      );
      final ahmed =
          (await owner.post(
            '/v1/owner/branches/$branch/staff',
            data: {'name': 'Ahmed', 'role': 'server', 'pin': '2580'},
          )).data;
      Future<String> code(String role) async =>
          (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': role})).data['code'];

      // ── Two real POS ──
      Future<(AppDatabase, DeviceIdentity, SyncEngine, PosApi)> pos(String role, String name) async {
        final db = AppDatabase(NativeDatabase.memory());
        final secrets = MemorySecretStore();
        final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
        final identity = await DeviceRepository(db, secrets, api).pair(code: await code(role), name: name);
        return (db, identity, SyncEngine(db, api, OutboxRepository(db), identity), api);
      }

      final (hubDb, hubId, hubSync, hubApi) = await pos('hub', 'Caisse principale');
      final (tabDb, tabId, tabSync, _) = await pos('pos', 'Tablette Ahmed');
      await hubSync.syncNow(); // menu, staff, tables, LAN key, devices

      // The Hub starts its server and tells the cloud its Wi-Fi address.
      final hubOutbox = OutboxRepository(hubDb);
      final server = HubServer(
        db: hubDb,
        outbox: hubOutbox,
        identity: hubId,
        lanInfo: () async => LanInfo.decode(await hubDb.getKv(LanInfo.kvKey)),
        port: 0,
      );
      final port = await server.start();
      final addresses = await localAddresses();
      expect(addresses, isNotEmpty, reason: 'this PC needs a private IPv4 address (Wi-Fi or Ethernet)');
      await hubApi.reportLan(addresses, port);

      // The tablet learns where the Hub is FROM THE CLOUD, then connects over the network.
      await tabSync.syncNow();
      final tabInfo = LanInfo.decode(await tabDb.getKv(LanInfo.kvKey))!;
      expect(tabInfo.hub!.deviceId, hubId.deviceId);
      expect(tabInfo.hub!.addresses, addresses);
      final client = HubClient(
        identity: tabId,
        lanInfo: () async => LanInfo.decode(await tabDb.getKv(LanInfo.kvKey)),
        mirror: HubMirror(tabDb),
        retryEvery: const Duration(milliseconds: 200),
      )..start();
      for (var i = 0; i < 50 && !client.link.connected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      // ignore: avoid_print
      print('Tablet ${tabId.deviceCode} connected to Hub ${hubId.deviceCode} at ${client.link.address}');
      expect(client.link.connected, isTrue);

      // ── Service: Ahmed orders at table 2 on his tablet, asks for the bill ──
      final tables = {for (final t in await tabDb.select(tabDb.diningTables).get()) t.name: t};
      final express = await tabDb.select(tabDb.products).getSingle();
      final actions = HubOrderActions(client, staffId: () => ahmed['id'] as String);
      await actions.addProduct(express, table: tables['2']);
      await actions.addProduct(express, table: tables['2']);
      final order = (await OrderRepository(hubDb, hubOutbox).watchOpenOrder(tableId: tables['2']!.id).first)!;
      await actions.requestBill(order.id);
      await expectLater(
        actions.pay(
          order.id,
          const PaymentRequest.card(amount: Money(2400)),
          deviceCode: tabId.deviceCode,
          drawerId: tabId.deviceId,
        ),
        throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Cette caisse ne peut pas encaisser.')),
      );

      // The owner allows this tablet to take payments; both POS pick it up at their next sync.
      await owner.patch('/v1/owner/devices/${tabId.deviceId}', data: {'canTakePayments': true});
      await hubSync.syncNow();
      await HubCashActions(client, staffId: () => ahmed['id'] as String).open(const Money.dt(20));
      final paid = await actions.pay(
        order.id,
        const PaymentRequest.cash(amount: Money(2400), tendered: Money.dt(5)),
        deviceCode: tabId.deviceCode,
        drawerId: tabId.deviceId,
      );
      expect((paid.closed, paid.change), (true, const Money(2600)));

      // ── Only the Hub sends tickets to the cloud ──
      final pushed = await hubSync.pushPending();
      expect(pushed.rejected, 0);
      expect(await OutboxRepository(tabDb).pending().then((l) => l.where((e) => e.type.startsWith('order.'))), isEmpty);

      final list = (await owner.get('/v1/owner/branches/$branch/sales/orders?status=paid')).data as List;
      // ignore: avoid_print
      print(
        'Owner sees: ${list.map((o) => '${o['receiptNumber']} table=${o['tableName']} ${o['total']} by ${o['deviceCode']}')}',
      );
      expect(list.single['tableName'], '2');
      expect(list.single['total'], 2400);
      expect(list.single['receiptNumber'], paid.receiptNumber);

      final devices = (await owner.get('/v1/owner/branches/$branch/devices')).data as List;
      expect(devices.firstWhere((d) => d['role'] == 'hub')['lanAddress'], '${addresses.first}:$port');
      expect(devices.firstWhere((d) => d['role'] == 'pos')['canTakePayments'], isTrue);

      await client.stop();
      await server.stop();
      await hubDb.close();
      await tabDb.close();
    },
    skip: Platform.environment['E2E_HUB'] == null ? 'set E2E_HUB=1 to run against a real backend' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
