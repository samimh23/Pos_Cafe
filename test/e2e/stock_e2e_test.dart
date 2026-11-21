// End-to-end against a REAL running backend: the owner sets ingredients and recipes,
// the POS sells, the stock goes down (once, even if events are sent again).
// Skipped unless E2E_STOCK=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_STOCK=1 flutter test test/e2e/stock_e2e_test.dart
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
import 'package:pos_cafe/features/cash/data/cash_repository.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'recipes + POS sales → stock goes down; deliveries and counts',
    () async {
      final password = List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[Random.secure().nextInt(32)]).join();
      final owner = Dio(BaseOptions(baseUrl: url));
      final s =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'stock${DateTime.now().millisecondsSinceEpoch}@example.test',
              'password': password,
              'name': 'Owner',
              'businessName': 'Café Stock',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${s['accessToken']}';
      final branch = s['branches'][0]['id'];
      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Café'})).data;
      final ids = <String, String>{};
      for (final p in [('Express', 1200), ('Cappuccino', 3500)]) {
        ids[p.$1] =
            (await owner.post(
              '/v1/owner/branches/$branch/products',
              data: {'name': p.$1, 'price': p.$2, 'station': 'bar', 'categoryId': cat['id']},
            )).data['id'];
      }
      Future<Map<String, dynamic>> item(String name, String unit, int qty) async =>
          (await owner.post('/v1/owner/branches/$branch/stock/items', data: {'name': name, 'unit': unit, 'quantity': qty}))
              .data;
      final coffee = await item('Café en grains', 'g', 1000);
      final milk = await item('Lait', 'ml', 2000);
      await owner.put(
        '/v1/owner/products/${ids['Express']}/recipe',
        data: {
          'lines': [
            {'stockItemId': coffee['id'], 'qty': 8},
          ],
        },
      );
      await owner.put(
        '/v1/owner/products/${ids['Cappuccino']}/recipe',
        data: {
          'lines': [
            {'stockItemId': coffee['id'], 'qty': 8},
            {'stockItemId': milk['id'], 'qty': 150},
          ],
        },
      );
      final code = (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': 'hub'})).data['code'];

      // ── POS: sells 2 Express + 1 Cappuccino, and a cancelled ticket ──
      final db = AppDatabase(NativeDatabase.memory());
      final secrets = MemorySecretStore();
      final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
      final identity = await DeviceRepository(db, secrets, api).pair(code: code, name: 'Caisse');
      final outbox = OutboxRepository(db);
      final engine = SyncEngine(db, api, outbox, identity);
      await engine.syncNow();
      final products = {for (final p in await db.select(db.products).get()) p.name: p};
      final orders = OrderRepository(db, outbox);
      await CashRepository(db, outbox, drawerId: identity.deviceId).open(const Money.dt(20));

      await orders.addProduct(products['Express']!);
      await orders.addProduct(products['Express']!);
      await orders.addProduct(products['Cappuccino']!);
      final t1 = (await orders.watchOpenOrder().first)!.id;
      await orders.pay(
        t1,
        const PaymentRequest.card(amount: Money(5900)),
        deviceCode: identity.deviceCode,
        drawerId: identity.deviceId,
      );
      await orders.addProduct(products['Cappuccino']!);
      await orders.cancelOrder((await orders.watchOpenOrder().first)!.id);
      expect((await engine.pushPending()).rejected, 0);

      Future<Map<String, int>> quantities() async => {
        for (final i in (await owner.get('/v1/owner/branches/$branch/stock')).data['items'] as List)
          i['name'] as String: i['quantity'] as int,
      };
      expect(await quantities(), {'Café en grains': 1000 - 3 * 8, 'Lait': 2000 - 150});

      // ── Owner: delivery and count ──
      await owner.post('/v1/owner/stock/items/${milk['id']}/movements', data: {'kind': 'delivery', 'quantity': 6000});
      await owner.post('/v1/owner/stock/items/${coffee['id']}/movements', data: {'kind': 'count', 'quantity': 950});
      expect(await quantities(), {'Café en grains': 950, 'Lait': 7850});
      final history = (await owner.get('/v1/owner/stock/items/${coffee['id']}/movements')).data as List;
      expect([for (final m in history) (m['kind'], m['delta'], m['quantityAfter'])], [
        ('count', -26, 950),
        ('sale', -24, 976),
        ('count', 1000, 1000),
      ]);

      await db.close();
    },
    skip: Platform.environment['E2E_STOCK'] == null ? 'set E2E_STOCK=1 to run against a real backend' : false,
  );
}
