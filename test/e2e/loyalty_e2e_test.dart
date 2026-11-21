// End-to-end against a REAL running backend: the owner turns loyalty on, the POS
// prints a receipt with its signed QR, a customer claims the points, a refund takes them back.
// Skipped unless E2E_LOYALTY=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_LOYALTY=1 flutter test test/e2e/loyalty_e2e_test.dart
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
import 'package:pos_cafe/core/loyalty/receipt_code.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/print/escpos.dart';
import 'package:pos_cafe/core/print/printers.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/cash/data/cash_repository.dart';
import 'package:pos_cafe/features/loyalty/reward_actions.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';
import 'package:pos_cafe/features/print/print_service.dart';

import '../fake_printer.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'receipt QR → customer points → refund takes them back',
    () async {
      String password() => List.generate(24, (_) => 'abcdefghijkmnpqrstuvwxyz23456789'[Random.secure().nextInt(32)]).join();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final owner = Dio(BaseOptions(baseUrl: url));
      final s =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'loyalty$stamp@example.test',
              'password': password(),
              'name': 'Owner',
              'businessName': 'Café Fidélité $stamp',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${s['accessToken']}';
      final branch = s['branches'][0]['id'];
      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Café'})).data;
      await owner.post(
        '/v1/owner/branches/$branch/products',
        data: {'name': 'Cappuccino', 'price': 6500, 'station': 'bar', 'categoryId': cat['id']},
      );
      await owner.put(
        '/v1/owner/branches/$branch/loyalty',
        data: {
          'enabled': true,
          'pointsPerDinar': 1,
          'rewards': [
            {'name': '5 DT de remise', 'points': 10, 'kind': 'amount_off', 'amount': 5000},
          ],
        },
      );
      await owner.patch('/v1/owner/branches/$branch/business', data: {'listed': true, 'city': 'Sousse'});
      final sonia =
          (await owner.post(
            '/v1/owner/branches/$branch/staff',
            data: {'name': 'Sonia', 'role': 'manager', 'pin': '2580'},
          )).data;
      final code = (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': 'hub'})).data['code'];

      // ── POS ──
      final db = AppDatabase(NativeDatabase.memory());
      final secrets = MemorySecretStore();
      final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
      final identity = await DeviceRepository(db, secrets, api).pair(code: code, name: 'Caisse');
      final outbox = OutboxRepository(db);
      final engine = SyncEngine(db, api, outbox, identity);
      await engine.syncNow(); // menu + business (loyaltyEnabled)
      final printer = FakePrinter();
      final printing = PrintService(
        db,
        outbox,
        transport: printer,
        loyalty: ReceiptSigner(secrets, () => identity.deviceId),
      );
      await printing.saveSettings(const PrinterSettings(receipt: PrinterConfig(host: '192.168.1.50')));
      await CashRepository(db, outbox, drawerId: identity.deviceId).open(const Money.dt(20));
      final orders = OrderRepository(db, outbox);
      final cappuccino = (await db.select(db.products).get()).single;

      Future<(String, String)> sell() async {
        await orders.addProduct(cappuccino);
        await orders.addProduct(cappuccino);
        final id = (await orders.watchOpenOrder().first)!.id;
        await orders.pay(
          id,
          const PaymentRequest.card(amount: Money(13000)),
          deviceCode: identity.deviceCode,
          drawerId: identity.deviceId,
        );
        printer.sent.clear();
        await printing.printReceipt(id);
        final qr = decodeEscPos(printer.sent.single.$2).single.singleWhere((l) => l.startsWith('[QR] '));
        return (id, qr.substring('[QR] $webUrl/r/'.length));
      }

      final (t1, code1) = await sell();
      final (t2, code2) = await sell();
      final (_, code3) = await sell(); // left unclaimed: open it in the browser to try the claim page
      expect((await engine.pushPending()).rejected, 0);
      // ignore: avoid_print
      print('Unclaimed receipt to try in the customer app: $webUrl/r/$code3');

      // ── Customer ──
      final customer = Dio(BaseOptions(baseUrl: url, validateStatus: (_) => true));
      final c =
          (await customer.post(
            '/v1/customer/auth/signup',
            data: {'email': 'client$stamp@example.test', 'password': password(), 'name': 'Leila'},
          )).data;
      customer.options.headers['authorization'] = 'Bearer ${c['accessToken']}';

      final found = (await customer.get('/v1/public/cafes', queryParameters: {'q': 'Fidélité $stamp'})).data as List;
      expect(found.single, containsPair('city', 'Sousse'));

      final claim1 = await customer.post('/v1/customer/claims', data: {'code': code1});
      expect(claim1.data, containsPair('points', 13));
      expect(claim1.data, containsPair('balance', 13));
      expect((await customer.post('/v1/customer/claims', data: {'code': code1})).statusCode, 409);
      expect((await customer.post('/v1/customer/claims', data: {'code': code2})).data['balance'], 26);

      final points = (await customer.get('/v1/customer/points')).data as List;
      expect(points.single, containsPair('rewardsAvailable', 1));

      // ── Refund at the POS → points taken back ──
      await orders.refund(
        t2,
        approval: Approval(approvedBy: sonia['id'] as String, reason: 'quality'),
        drawerId: identity.deviceId,
      );
      expect((await engine.pushPending()).rejected, 0);
      final cafe = (await customer.get('/v1/customer/points/$branch')).data;
      expect(cafe['balance'], 13);
      expect((cafe['history'] as List).map((h) => h['points']), containsAll([13, 13, -13]));
      expect(t1, isNotEmpty);

      // ── Spending points: "5 DT de remise" (10 pts) at the counter ──
      final rewardId = ((await owner.get('/v1/owner/branches/$branch/loyalty')).data['rewards'] as List).single['id'];
      final redemption =
          (await customer.post('/v1/customer/points/$branch/redemptions', data: {'rewardId': rewardId})).data;
      expect(redemption['code'], matches(RegExp(r'^\d{6}$')));

      await orders.addProduct(cappuccino);
      final t4 = (await orders.watchOpenOrder().first)!.id;
      final rewards = LocalRewardActions(api, orders);
      final seen = await rewards.check(t4, redemption['code'] as String);
      expect(seen.reward.customerName, 'Leila');
      expect((await customer.get('/v1/customer/points/$branch')).data['balance'], 13); // nothing spent yet
      await rewards.redeem(t4, redemption['code'] as String);
      await expectLater(rewards.redeem(t4, redemption['code'] as String), throwsA(isA<OrderException>()));
      await orders.pay(
        t4,
        const PaymentRequest.card(amount: Money(1500)), // 6.500 − 5.000
        deviceCode: identity.deviceCode,
        drawerId: identity.deviceId,
      );
      expect((await engine.pushPending()).rejected, 0);
      expect((await customer.get('/v1/customer/points/$branch')).data['balance'], 3);
      final line = ((await owner.get('/v1/owner/orders/$t4')).data['lines'] as List).single;
      expect(line, containsPair('discountReason', 'loyalty'));
      expect(line, containsPair('discount', 5000));

      await db.close();
    },
    skip: Platform.environment['E2E_LOYALTY'] == null ? 'set E2E_LOYALTY=1 to run against a real backend' : false,
  );
}
