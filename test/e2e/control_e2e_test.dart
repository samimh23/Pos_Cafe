// End-to-end against a REAL running backend: an offered coffee approved by a
// manager, an item cancelled after "Envoyer", a refunded ticket → the owner sees it all.
// Skipped unless E2E_CONTROL=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_CONTROL=1 flutter test test/e2e/control_e2e_test.dart
@Tags(['e2e'])
library;

import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
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
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'discount + cancellation after send + refund reach the owner',
    () async {
      final owner = Dio(BaseOptions(baseUrl: url));
      final password = List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[Random.secure().nextInt(32)]).join();
      final s =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'control${DateTime.now().millisecondsSinceEpoch}@example.test',
              'password': password,
              'name': 'Owner',
              'businessName': 'Café Contrôle',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${s['accessToken']}';
      final branch = s['branches'][0]['id'];
      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Café'})).data;
      for (final p in [
        {'name': 'Express', 'price': 1200, 'station': 'bar'},
        {'name': 'Jus', 'price': 4000, 'station': 'bar'},
      ]) {
        await owner.post('/v1/owner/branches/$branch/products', data: {...p, 'categoryId': cat['id']});
      }
      final sonia =
          (await owner.post(
            '/v1/owner/branches/$branch/staff',
            data: {'name': 'Sonia', 'role': 'manager', 'pin': '2580'},
          )).data;
      final ahmed =
          (await owner.post(
            '/v1/owner/branches/$branch/staff',
            data: {'name': 'Ahmed', 'role': 'server', 'pin': '7391'},
          )).data;
      final code = (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': 'hub'})).data['code'];

      final db = AppDatabase(NativeDatabase.memory());
      final secrets = MemorySecretStore();
      final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
      final identity = await DeviceRepository(db, secrets, api).pair(code: code, name: 'Caisse');
      final outbox = OutboxRepository(db);
      final engine = SyncEngine(db, api, outbox, identity);
      await engine.syncNow();
      final products = {for (final p in await db.select(db.products).get()) p.name: p};
      final orders = OrderRepository(db, outbox, staffId: () => ahmed['id'] as String);
      await CashRepository(db, outbox, drawerId: identity.deviceId).open(const Money.dt(50));
      final manager = sonia['id'] as String;

      // Ticket 1: 2 Express + Jus; one Express offered (manager), Jus cancelled after "Envoyer".
      await orders.addProduct(products['Express']!);
      await orders.addProduct(products['Express']!);
      await orders.addProduct(products['Jus']!);
      final t1 = (await orders.watchOpenOrder().first)!.id;
      final lines = {for (final l in await orders.watchLines(t1).first) l.name: l};
      await orders.discount(
        t1,
        DiscountRequest(
          type: 'amount',
          value: 1200,
          reason: 'geste',
          lineIds: [lines['Express']!.id],
          approvedBy: manager,
        ),
      );
      await (db.update(db.orderLines)
        ..where((l) => l.id.equals(lines['Jus']!.id))).write(OrderLinesCompanion(sentAt: Value(DateTime.now())));
      await orders.removeLine(lines['Jus']!.id, approval: Approval(approvedBy: manager, reason: 'changed_mind'));
      final r1 = await orders.pay(
        t1,
        const PaymentRequest.cash(amount: Money(1200), tendered: Money.dt(2)),
        deviceCode: identity.deviceCode,
        drawerId: identity.deviceId,
      );

      // Ticket 2: a Jus, paid by card, then refunded (quality problem).
      await orders.addProduct(products['Jus']!);
      final t2 = (await orders.watchOpenOrder().first)!.id;
      await orders.pay(
        t2,
        const PaymentRequest.card(amount: Money(4000)),
        deviceCode: identity.deviceCode,
        drawerId: identity.deviceId,
      );
      await orders.refund(t2, approval: Approval(approvedBy: manager, reason: 'quality'), drawerId: identity.deviceId);

      final pushed = await engine.pushPending();
      expect(pushed.rejected, 0);

      // ── Owner side ──
      final summary = (await owner.get('/v1/owner/branches/$branch/sales/summary')).data;
      // ignore: avoid_print
      print(
        'Owner sees: revenue ${summary['revenue']}, discounts ${summary['discounts']}, refunds ${summary['refunds']}',
      );
      expect(summary['revenue'], 1200);
      expect(summary['discounts'], {'amount': 1200, 'lines': 1, 'freeItems': 0});
      expect(summary['refunds'], {'count': 1, 'amount': 4000});

      final d1 = (await owner.get('/v1/owner/orders/$t1')).data;
      final byName = {for (final l in d1['lines'] as List) l['name']: l};
      expect(byName['Express'], containsPair('discountReason', 'geste'));
      expect(byName['Express'], containsPair('discount', 1200));
      expect(byName['Jus'], containsPair('voidReason', 'changed_mind'));
      expect(d1['receiptNumber'], r1.receiptNumber);

      final refunded = (await owner.get('/v1/owner/branches/$branch/sales/orders?status=refunded')).data as List;
      expect(refunded.single, containsPair('refundReason', 'quality'));

      await db.close();
    },
    skip: Platform.environment['E2E_CONTROL'] == null ? 'set E2E_CONTROL=1 to run against a real backend' : false,
  );
}
