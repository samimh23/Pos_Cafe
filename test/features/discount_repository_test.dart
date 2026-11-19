import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/money/order_totals.dart';
import 'package:pos_cafe/core/staff/staff_repository.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/features/cash/data/cash_repository.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

import '../fakes.dart' show ahmedPinHash;
import '../order_helpers.dart';
import 'order_repository_test.dart' show product;

/// Discounts: always a reason, always a manager; totals, VAT and events follow.
void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late String? who;
  late OrderRepository orders;

  final express = product('p1', 'Express', 1200);
  final cappuccino = product('p2', 'Cappuccino', 3500);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    for (final (id, name, role) in [('s-ahmed', 'Ahmed', 'server'), ('s-sonia', 'Sonia', 'manager')]) {
      // PIN 1234 for both (shared test vector).
      await db
          .into(db.staffMembers)
          .insert(StaffMembersCompanion.insert(id: id, name: name, role: role, pinHash: ahmedPinHash));
    }
    who = 's-ahmed';
    orders = OrderRepository(db, outbox, staffId: () => who);
    await openTestDrawer(db);
  });
  tearDown(() => db.close());

  Future<String> sell(List<ProductRow> items) async {
    for (final p in items) {
      await orders.addProduct(p);
    }
    return (await orders.watchOpenOrder().first)!.id;
  }

  Future<List<OrderLineRow>> lines(String id) => orders.watchLines(id).first;
  Future<OrderTotals> totals(String id) async => OrderTotals.of((await lines(id)).map(amountsOf));

  test('a server offers a coffee with a manager’s approval: total, VAT, event with approvedBy', () async {
    final id = await sell([express, express, cappuccino]); // 2 × 1.200 + 3.500 = 5.900
    final expressLine = (await lines(id)).firstWhere((l) => l.name == 'Express');

    await orders.discount(id, DiscountRequest.free(reason: 'geste', lineIds: [expressLine.id], approvedBy: 's-sonia'));

    final t = await totals(id);
    expect((t.total, t.discount), (const Money(3500), const Money(2400)));
    expect(t.vat.single.ttc, const Money(3500)); // VAT on what is really paid
    final e = (await outbox.pending()).last;
    expect((e.type, e.staffId, e.approvedBy), ('order.item_discounted', 's-ahmed', 's-sonia'));
    expect(jsonDecode(e.payloadJson), {
      'reason': 'geste',
      'lines': [
        {'lineId': expressLine.id, 'type': 'free', 'value': 0},
      ],
    });
  });

  test('without a manager: refused; a manager logged in approves by themselves', () async {
    final id = await sell([express]);
    await expectLater(
      orders.discount(id, const DiscountRequest.free(reason: 'geste')),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Validation d’un gérant requise.')),
    );
    await expectLater(
      orders.discount(id, const DiscountRequest.free(reason: 'geste', approvedBy: 's-ahmed')), // not a manager
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Seul un gérant peut valider.')),
    );
    who = 's-sonia';
    await orders.discount(id, const DiscountRequest.free(reason: 'staff'));
    expect((await outbox.pending()).last.approvedBy, 's-sonia');
  });

  test('−10 % on the whole ticket; an amount on the whole ticket is split by price', () async {
    final id = await sell([express, cappuccino]); // 1.200 + 3.500
    await orders.discount(
      id,
      const DiscountRequest(type: 'percent', value: 1000, reason: 'complaint', approvedBy: 's-sonia'),
    );
    expect((await totals(id)).discount, const Money(470)); // 120 + 350

    await orders.discount(
      id,
      const DiscountRequest(type: 'amount', value: 1000, reason: 'error', approvedBy: 's-sonia'),
    );
    final ls = await lines(id);
    expect({for (final l in ls) l.name: l.discountValue}, {'Express': 255, 'Cappuccino': 745});
    expect((await totals(id)).discount, const Money(1000));
  });

  test('another coffee next to an offered one is NOT free; + on it adds a full-price line', () async {
    final id = await sell([express]);
    final first = (await lines(id)).single;
    await orders.discount(id, DiscountRequest.free(reason: 'geste', lineIds: [first.id], approvedBy: 's-sonia'));

    await orders.addProduct(express);
    await orders.setQty(first.id, 2); // + on the offered line
    final ls = await lines(id);
    expect([for (final l in ls) (l.qty, l.discountType)], [(1, 'free'), (1, null), (1, null)]);
    expect((await totals(id)).total, const Money(2400));
  });

  test('remove a discount: full price again, no approval needed', () async {
    final id = await sell([cappuccino]);
    final l = (await lines(id)).single;
    await orders.discount(
      id,
      DiscountRequest(type: 'percent', value: 5000, reason: 'staff', lineIds: [l.id], approvedBy: 's-sonia'),
    );
    await orders.removeDiscount(id, [l.id]);
    expect((await totals(id)).total, const Money(3500));
    final e = jsonDecode((await outbox.pending()).last.payloadJson);
    expect(e['lines'], [
      {'lineId': l.id, 'type': null, 'value': 0},
    ]);
  });

  test('paid lines are not discounted; the total can’t go below what was paid', () async {
    final id = await sell([express, cappuccino]);
    final ls = await lines(id);
    await orders.pay(
      id,
      PaymentRequest.card(amount: Money.zero, lineIds: [ls.firstWhere((l) => l.name == 'Express').id]),
      deviceCode: 'T1',
      drawerId: testDrawer,
    );
    await orders.discount(id, const DiscountRequest.free(reason: 'geste', approvedBy: 's-sonia'));
    final after = await lines(id);
    expect({for (final l in after) l.name: l.discountType}, {'Express': null, 'Cappuccino': 'free'});
  });

  test('wrong reason or wrong values are refused', () async {
    final id = await sell([express]);
    await expectLater(
      orders.discount(id, const DiscountRequest.free(reason: 'because', approvedBy: 's-sonia')),
      throwsA(isA<OrderException>()),
    );
    await expectLater(
      orders.discount(id, const DiscountRequest(type: 'percent', value: 0, reason: 'geste', approvedBy: 's-sonia')),
      throwsA(isA<OrderException>()),
    );
  });

  test('the closing report counts the discounts of the tickets paid in this drawer', () async {
    final id = await sell([express, cappuccino]);
    final l = (await lines(id)).firstWhere((x) => x.name == 'Express');
    await orders.discount(id, DiscountRequest.free(reason: 'geste', lineIds: [l.id], approvedBy: 's-sonia'));
    await orders.pay(id, const PaymentRequest.card(amount: Money(3500)), deviceCode: 'T1', drawerId: testDrawer);
    final s = (await CashRepository(db, outbox, drawerId: testDrawer).summary())!;
    expect((s.cardSales, s.discounts), (const Money(3500), const Money(1200)));
  });

  test('manager approval PIN: right PIN ok (nobody logged in), wrong PINs share the login lockout', () async {
    final staff = StaffRepository(db, outbox);
    final sonia = await (db.select(db.staffMembers)..where((s) => s.id.equals('s-sonia'))).getSingle();
    expect(await staff.approve(sonia, '1234'), isA<PinOk>());
    expect((await outbox.pending()).where((e) => e.type == 'staff.logged_in'), isEmpty);
    for (var i = 0; i < 4; i++) {
      expect(await staff.approve(sonia, '0000'), isA<PinWrong>());
    }
    expect(await staff.approve(sonia, '0000'), isA<PinLocked>());
    expect(await staff.login(sonia, '1234'), isA<PinLocked>()); // same lock
  });
}
