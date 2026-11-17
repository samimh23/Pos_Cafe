// End-to-end against a REAL running backend: the POS sells, the owner sees it.
// Skipped unless E2E_SALES=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_SALES=1 flutter test test/e2e/sales_e2e_test.dart
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/menu/modifiers.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'POS sells 2 orders (one with an option, one cancelled) → owner dashboard shows them',
    () async {
      // ── Owner sets up the café ──
      final owner = Dio(BaseOptions(baseUrl: url));
      final s =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'sales${DateTime.now().millisecondsSinceEpoch}@example.com',
              'password': 'correct horse battery',
              'name': 'Owner',
              'businessName': 'Café Sales E2E',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${s['accessToken']}';
      final branch = s['branches'][0]['id'];
      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Café'})).data;
      for (final p in [
        {'name': 'Express', 'price': 1200},
        {'name': 'Croissant', 'price': 1500, 'vatRateBp': 700},
        {
          'name': 'Cappuccino',
          'price': 3500,
          'modifierGroups': [
            {
              'name': 'Extras',
              'minSelect': 0,
              'maxSelect': 2,
              'modifiers': [
                {'name': 'Extra shot', 'extraPrice': 500},
              ],
            },
          ],
        },
      ]) {
        await owner.post('/v1/owner/branches/$branch/products', data: {...p, 'categoryId': cat['id']});
      }
      final code = (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': 'hub'})).data['code'];

      // ── POS (real Flutter code) ──
      final db = AppDatabase(NativeDatabase.memory());
      final secrets = MemorySecretStore();
      final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
      final identity = await DeviceRepository(db, secrets, api).pair(code: code, name: 'Caisse');
      final outbox = OutboxRepository(db);
      final engine = SyncEngine(db, api, outbox, identity);
      await engine.pullMenu();
      final products = {for (final p in await db.select(db.products).get()) p.name: p};
      final orders = OrderRepository(db, outbox);

      // Order 1: 2 Express + Croissant → 3.900, paid with 5 DT
      await orders.addProduct(products['Express']!);
      await orders.addProduct(products['Express']!);
      await orders.addProduct(products['Croissant']!);
      final r1 = await orders.payCash(tendered: const Money.dt(5), deviceCode: identity.deviceCode);

      // Order 2: Cappuccino + extra shot → 4.000
      final shot = parseModifierGroups(products['Cappuccino']!.modifierGroupsJson).single.options.single;
      await orders.addProduct(products['Cappuccino']!, modifiers: [shot]);
      final r2 = await orders.payCash(tendered: const Money.dt(4), deviceCode: identity.deviceCode);

      // Order 3: cancelled
      await orders.addProduct(products['Express']!);
      await orders.cancelOpenOrder();

      final pushed = await engine.pushPending();
      // ignore: avoid_print
      print('POS: ${r1.receiptNumber} ${r1.total}, ${r2.receiptNumber} ${r2.total}, ${pushed.pushed} events pushed');

      // ── Owner dashboard ──
      final summary = (await owner.get('/v1/owner/branches/$branch/sales/summary')).data;
      // ignore: avoid_print
      print(
        'Owner sees: revenue ${summary['revenue']}, tickets ${summary['ticketCount']}, '
        'cancelled ${summary['cancelledCount']}, top ${summary['topProducts'].map((p) => '${p['name']}×${p['qty']}').toList()}',
      );
      expect(summary['revenue'], 7900);
      expect(summary['ticketCount'], 2);
      expect(summary['cancelledCount'], 1);
      expect(summary['byPaymentMethod'], [
        {'method': 'cash', 'amount': 7900, 'count': 2},
      ]);

      final list = (await owner.get('/v1/owner/branches/$branch/sales/orders?status=paid')).data as List;
      expect(list.map((o) => o['receiptNumber']), ['T1-000002', 'T1-000001']);

      final detail = (await owner.get('/v1/owner/orders/${list.first['id']}')).data;
      expect(detail['lines'].single['name'], 'Cappuccino');
      expect(detail['lines'].single['total'], 4000);

      await db.close();
    },
    skip: Platform.environment['E2E_SALES'] == null ? 'set E2E_SALES=1 to run against a real backend' : false,
  );
}
