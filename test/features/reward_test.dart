import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/app/app.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/money/order_totals.dart';
import 'package:pos_cafe/core/providers.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/features/loyalty/loyalty_reward.dart';
import 'package:pos_cafe/features/loyalty/reward_actions.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

import '../fakes.dart';
import '../order_helpers.dart';
import 'order_repository_test.dart' show product;
import 'staff_login_helper.dart';

Map<String, dynamic> rewardJson({
  String kind = 'free_product',
  String? productId = 'p1',
  int? amount,
  int points = 10,
  String name = 'Un express offert',
}) => {
  'id': 'red-1',
  'rewardName': name,
  'points': points,
  'kind': kind,
  'productId': kind == 'free_product' ? productId : null,
  'amount': amount,
  'customerName': 'Leila',
};

void main() {
  group('rewards on the ticket', () {
    late AppDatabase db;
    late OutboxRepository outbox;
    late OrderRepository orders;
    late FakePosApi api;
    late LocalRewardActions rewards;
    final express = product('p1', 'Express', 1200);
    final cappuccino = product('p2', 'Cappuccino', 3500);

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      outbox = OutboxRepository(db);
      orders = OrderRepository(db, outbox, staffId: () => 's-ahmed'); // a server: no manager needed for rewards
      api = FakePosApi();
      rewards = LocalRewardActions(api, orders);
      await db.into(db.products).insert(express.toCompanion(true));
      await openTestDrawer(db);
    });
    tearDown(() => db.close());

    Future<String> ticket(List<ProductRow> items) async {
      for (final p in items) {
        await orders.addProduct(p);
      }
      return (await orders.watchOpenOrder().first)!.id;
    }

    Future<Money> total(String id) async => OrderTotals.of((await orders.watchLines(id).first).map(amountsOf)).total;

    test('free product: checked first (nothing spent), then one unit offered, reason "loyalty", no manager', () async {
      final id = await ticket([express, cappuccino]);
      api.rewardCodes['123456'] = rewardJson();

      final seen = await rewards.check(id, '123456');
      expect(seen.reward.customerName, 'Leila');
      expect(seen.description, '1 × Express offert');
      expect(api.redeemed, isEmpty);
      expect(await total(id), const Money(4700));

      final done = await rewards.redeem(id, '123456');
      expect(done.reward.rewardName, 'Un express offert');
      expect(api.redeemed, [('123456', id)]);
      expect(await total(id), const Money(3500));
      final line = (await orders.watchLines(id).first).firstWhere((l) => l.productId == 'p1');
      expect((line.discountType, line.discountReason, line.discountApprovedBy), ('free', 'loyalty', null));
      final ev = (await db.select(db.outboxEvents).get()).lastWhere((e) => e.type == 'order.item_discounted');
      expect(ev.approvedBy, isNull);
      expect(ev.payloadJson, contains('"reason":"loyalty"'));
      expect(DiscountReasons.label('loyalty'), 'Fidélité');
      expect(DiscountReasons.labels.keys, isNot(contains('loyalty'))); // not in the cashier's discount choices
    });

    test('free product not on the ticket → refused BEFORE spending the points', () async {
      final id = await ticket([cappuccino]);
      api.rewardCodes['123456'] = rewardJson();
      await expectLater(
        rewards.redeem(id, '123456'),
        throwsA(isA<OrderException>().having((e) => e.message, 'message', contains('Ajoutez d’abord « Express »'))),
      );
      expect(api.redeemed, isEmpty);
      expect(api.rewardCodes, contains('123456')); // still usable
    });

    test('2 × Express on one line → one unit offered (amount off that line)', () async {
      final id = await ticket([express, express]);
      api.rewardCodes['123456'] = rewardJson();
      await rewards.redeem(id, '123456');
      final line = (await orders.watchLines(id).first).single;
      expect((line.qty, line.discountType, line.discountValue), (2, 'amount', 1200));
      expect(await total(id), const Money(1200));
    });

    test('amount off: spread on the items without a discount; capped at what they are worth', () async {
      final id = await ticket([express, cappuccino]);
      api.rewardCodes['111111'] = rewardJson(kind: 'amount_off', amount: 2000, name: '2 DT de remise');
      expect((await rewards.check(id, '111111')).description, 'Remise de 2.000 DT sur le ticket');
      await rewards.redeem(id, '111111');
      expect(await total(id), const Money(2700));

      final id2 = await ticket([]); // same open ticket
      expect(id2, id);
      api.rewardCodes['222222'] = rewardJson(kind: 'amount_off', amount: 5000);
      await expectLater(rewards.check(id, '222222'), throwsA(isA<OrderException>())); // every item has a discount now
    });

    test('a gift from the café goes on the ticket the same way (no points)', () async {
      final id = await ticket([express]);
      api.rewardCodes['555555'] = {...rewardJson(points: 0, name: 'Cadeau : un express'), 'gift': true};
      final seen = await rewards.check(id, '555555');
      expect((seen.reward.gift, seen.reward.points), (true, 0));
      await rewards.redeem(id, '555555');
      expect(await total(id), Money.zero);
      // Everything offered: the ticket closes at 0 DT with a receipt number.
      final r = await orders.pay(
        id,
        const PaymentRequest.cash(amount: Money.zero, tendered: Money.zero),
        deviceCode: 'T1',
        drawerId: testDrawer,
      );
      expect(r.closed, isTrue);
      expect(r.receiptNumber, 'T1-000001');
      expect(RewardCheck.fromJson(seen.toJson()).reward.gift, isTrue); // survives the trip through the main POS
    });

    test('backend answers become clear messages; offline says so', () async {
      final id = await ticket([express]);
      Future<String> msg(String code) async {
        try {
          await rewards.check(id, code);
          return '';
        } on OrderException catch (e) {
          return e.message;
        }
      }

      expect(await msg('999999'), contains('Code inconnu ou expiré'));
      expect(await msg('12ab'), 'Le code fidélité a 6 chiffres.');
      api.failWith = const ApiException('NETWORK', 'offline');
      expect(await msg('123456'), contains('Pas de connexion internet'));
      api.failWith = const ApiException('NOT_ENOUGH_POINTS', 'x', 409);
      expect(await msg('123456'), contains('plus assez de points'));
    });
  });

  testWidgets('ticket → Fidélité → code → Vérifier → Appliquer: the coffee is offered', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi()..rewardCodes['424242'] = rewardJson();
    await secrets.write(SecretKeys.deviceToken, 'token');
    await tester.runAsync(
      () => db.setKv(
        'device_identity',
        '{"deviceId":"dev-1","deviceCode":"T1","role":"hub","tenantId":"t","branchId":"b","name":"Caisse"}',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          secretStoreProvider.overrideWithValue(secrets),
          posApiProvider.overrideWithValue(api),
        ],
        child: const PosCafeApp(),
      ),
    );
    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await loginAsAhmed(tester);
    for (var i = 0; i < 20 && find.byKey(const Key('product-p1')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-total'))).data, '1.200 DT');

    await tester.tap(find.byKey(const Key('ticket-reward')));
    await settle();
    await tester.enterText(find.byKey(const Key('reward-code')), '424242');
    await tester.tap(find.byKey(const Key('reward-check')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle();
    expect(find.text('Un express offert'), findsOneWidget);
    expect(find.textContaining('Leila · 10 points'), findsOneWidget);
    expect(api.redeemed, isEmpty);

    await tester.tap(find.byKey(const Key('reward-apply')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle();
    expect(find.byKey(const Key('reward-code')), findsNothing); // dialog closed
    expect(api.redeemed.single.$1, '424242');
    expect(find.textContaining('Offert (Fidélité)'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('ticket-total'))).data, '0.000 DT');

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
