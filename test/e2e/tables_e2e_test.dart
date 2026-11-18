// End-to-end against a REAL running backend: the owner sets up rooms and tables,
// the POS serves a table (move + split payment) and the counter, the owner sees it.
// Skipped unless E2E_TABLES=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_TABLES=1 flutter test test/e2e/tables_e2e_test.dart
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
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

import '../order_helpers.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'owner adds Salle 1-4 → POS: table 2 moved to 3, paid half cash / half card; counter cash → owner sees tables',
    () async {
      // ── Owner sets up the café ──
      final owner = Dio(BaseOptions(baseUrl: url));
      final password = List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[Random.secure().nextInt(32)]).join();
      final s =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'tables${DateTime.now().millisecondsSinceEpoch}@example.test',
              'password': password,
              'name': 'Owner',
              'businessName': 'Café Tables E2E',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${s['accessToken']}';
      final branch = s['branches'][0]['id'];
      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Café'})).data;
      await owner.post(
        '/v1/owner/branches/$branch/products',
        data: {'name': 'Express', 'price': 1200, 'categoryId': cat['id']},
      );
      await owner.post(
        '/v1/owner/branches/$branch/products',
        data: {'name': 'Jus', 'price': 4000, 'categoryId': cat['id']},
      );
      final salle = (await owner.post('/v1/owner/branches/$branch/areas', data: {'name': 'Salle'})).data;
      await owner.post(
        '/v1/owner/branches/$branch/tables',
        data: {
          'areaId': salle['id'],
          'names': ['1', '2', '3', '4'],
        },
      );
      final code = (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': 'hub'})).data['code'];

      // ── POS (real Flutter code) ──
      final db = AppDatabase(NativeDatabase.memory());
      final secrets = MemorySecretStore();
      final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
      final identity = await DeviceRepository(db, secrets, api).pair(code: code, name: 'Caisse');
      final outbox = OutboxRepository(db);
      final engine = SyncEngine(db, api, outbox, identity);
      await engine.pullMenu();

      final tables = {for (final t in await db.select(db.diningTables).get()) t.name: t};
      expect(tables.keys, unorderedEquals(['1', '2', '3', '4']));
      expect((await db.select(db.floorAreas).getSingle()).name, 'Salle');
      final products = {for (final p in await db.select(db.products).get()) p.name: p};
      final orders = OrderRepository(db, outbox);

      // Table 2: 2 Express + Jus = 6.400, customers move to table 3, pay half cash, half card.
      await orders.addProduct(products['Express']!, table: tables['2']);
      await orders.addProduct(products['Express']!, table: tables['2']);
      await orders.addProduct(products['Jus']!, table: tables['2']);
      final order = (await orders.watchOpenOrder(tableId: tables['2']!.id).first)!;
      await orders.moveOrder(order.id, tables['3']);
      final half = await orders.pay(
        order.id,
        const PaymentRequest.cash(amount: Money(3200), tendered: Money.dt(5)),
        deviceCode: identity.deviceCode,
      );
      expect(half.remaining, const Money(3200));
      final rest = await orders.pay(
        order.id,
        const PaymentRequest.card(amount: Money(3200)),
        deviceCode: identity.deviceCode,
      );
      expect(rest.closed, isTrue);

      // Counter: 1 Express, cash.
      await orders.addProduct(products['Express']!);
      final counter = await orders.payCounterCash(tendered: const Money.dt(2), deviceCode: identity.deviceCode);

      final pushed = await engine.pushPending();
      // ignore: avoid_print
      print(
        'POS: table ${rest.receiptNumber} 6.400 (cash+card), counter ${counter.receiptNumber}, ${pushed.pushed} events',
      );

      // ── Owner side ──
      final list = (await owner.get('/v1/owner/branches/$branch/sales/orders?status=paid')).data as List;
      // ignore: avoid_print
      print(
        'Owner sees: ${list.map((o) => '${o['receiptNumber']} table=${o['tableName']} ${o['total']} ${o['paymentMethod']}').toList()}',
      );
      final byReceipt = {for (final o in list) o['receiptNumber']: o};
      expect(byReceipt[rest.receiptNumber], containsPair('tableName', '3'));
      expect(byReceipt[rest.receiptNumber], containsPair('paymentMethod', 'mixed'));
      expect(byReceipt[rest.receiptNumber], containsPair('total', 6400));
      expect(byReceipt[counter.receiptNumber], containsPair('tableName', null));

      final summary = (await owner.get('/v1/owner/branches/$branch/sales/summary')).data;
      // ignore: avoid_print
      print('Summary: revenue ${summary['revenue']}, by method ${summary['byPaymentMethod']}');
      expect(summary['revenue'], 7600);

      expect(pushed.rejected, 0);
      await db.close();
    },
    skip: Platform.environment['E2E_TABLES'] == null ? 'set E2E_TABLES=1 to run against a real backend' : false,
  );
}
