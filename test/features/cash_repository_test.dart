import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/features/cash/data/cash_repository.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

import 'order_repository_test.dart' show product;

/// A drawer's day: float → sales (cash and card) → cash in/out → count → gap.
void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late String? who;
  late CashRepository cash;
  late OrderRepository orders;
  const drawer = 'dev-1';

  final express = product('p1', 'Express', 1200);
  final croissant = product('p2', 'Croissant', 1500, vat: 700);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    for (final (id, name, role) in [('s-riadh', 'Riadh', 'cashier'), ('s-moaed', 'Moaed', 'server')]) {
      await db.into(db.staffMembers).insert(StaffMembersCompanion.insert(id: id, name: name, role: role, pinHash: 'x'));
    }
    who = 's-riadh';
    cash = CashRepository(db, outbox, drawerId: drawer, staffId: () => who);
    orders = OrderRepository(db, outbox, staffId: () => who);
  });
  tearDown(() => db.close());

  Future<String> sell(List<ProductRow> items) async {
    for (final p in items) {
      await orders.addProduct(p);
    }
    return (await orders.watchOpenOrder().first)!.id;
  }

  Future<List<Map<String, dynamic>>> events(String type) async => [
    for (final e in await outbox.pending())
      if (e.type == type) jsonDecode(e.payloadJson) as Map<String, dynamic>,
  ];

  test('a full day: totals, expected cash, gap; the closing is sent to the cloud', () async {
    await cash.open(const Money.dt(50));
    expect((await events('cash_session.opened')).single, {'drawerId': drawer, 'openingFloat': 50000});

    // 3.900 in cash (paid with 5 DT: only 3.900 stays in the drawer) …
    var id = await sell([express, express, croissant]);
    await orders.pay(
      id,
      const PaymentRequest.cash(amount: Money(3900), tendered: Money.dt(5)),
      deviceCode: 'T1',
      drawerId: drawer,
    );
    // … and 1.200 by card.
    id = await sell([express]);
    await orders.pay(id, const PaymentRequest.card(amount: Money(1200)), deviceCode: 'T1', drawerId: drawer);

    await cash.move(cashIn: false, amount: const Money.dt(30), reason: 'Pain du fournisseur');
    await cash.move(cashIn: true, amount: const Money.dt(10), reason: 'Monnaie');

    final s = (await cash.summary())!;
    expect(
      (s.openingFloat, s.cashSales, s.cardSales, s.cashIn, s.cashOut, s.ticketCount),
      (const Money.dt(50), const Money(3900), const Money(1200), const Money.dt(10), const Money.dt(30), 2),
    );
    expect(s.expectedCash, const Money(33900)); // 50 + 3.900 + 10 − 30
    expect(s.movements.map((m) => (m.cashIn, m.reason, m.staffName)), [
      (false, 'Pain du fournisseur', 'Riadh'),
      (true, 'Monnaie', 'Riadh'),
    ]);

    final closing = await cash.close(counted: const Money(33000), note: ' Billet abîmé ');
    expect(closing.difference, const Money(-900));
    expect((closing.closedBy, closing.note), ('Riadh', 'Billet abîmé'));
    expect((await events('cash_session.closed')).single, {
      'countedCash': 33000,
      'expectedCash': 33900,
      'difference': -900,
      'cashSales': 3900,
      'cardSales': 1200,
      'cashIn': 10000,
      'cashOut': 30000,
      'ticketCount': 2,
      'note': 'Billet abîmé',
    });
    expect(await cash.summary(), isNull); // closed

    // Drawer closed → no more payments until it is opened again.
    id = await sell([express]);
    await expectLater(
      orders.pay(id, const PaymentRequest.card(amount: Money(1200)), deviceCode: 'T1', drawerId: drawer),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('Caisse fermée'))),
    );
  });

  test('payments record their drawer; another drawer’s sales are not counted', () async {
    await cash.open(Money.zero);
    await CashRepository(db, outbox, drawerId: 'terrace', staffId: () => who).open(Money.zero);
    final id = await sell([express]);
    await orders.pay(id, const PaymentRequest.card(amount: Money(1200)), deviceCode: 'T1', drawerId: 'terrace');
    expect((await db.select(db.payments).getSingle()).drawerId, 'terrace');
    expect((await events('payment.added')).single['drawerId'], 'terrace');
    expect((await cash.summary())!.cardSales, Money.zero);
  });

  test('rules: open once, no negative float, not more cash out than in the drawer', () async {
    await expectLater(cash.open(const Money(-1)), throwsA(isA<OrderException>()));
    await cash.open(const Money.dt(20));
    await expectLater(
      cash.open(const Money.dt(20)),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'La caisse est déjà ouverte.')),
    );
    await expectLater(
      cash.move(cashIn: false, amount: const Money.dt(25), reason: 'Courses'),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('Pas assez d’espèces'))),
    );
    await expectLater(cash.move(cashIn: true, amount: const Money.dt(5), reason: '  '), throwsA(isA<OrderException>()));
  });

  test('a server can open the drawer but only a cashier or manager can take cash out or close', () async {
    who = 's-moaed';
    await cash.open(const Money.dt(20)); // first person in the morning
    await expectLater(
      cash.move(cashIn: false, amount: const Money.dt(5), reason: 'Courses'),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('gérant ou un caissier'))),
    );
    await expectLater(cash.close(counted: const Money.dt(20)), throwsA(isA<OrderException>()));
    who = 's-riadh';
    expect((await cash.close(counted: const Money.dt(20))).difference, Money.zero);
  });

  test('the main POS cannot close while tickets are open; a tablet drawer can', () async {
    await cash.open(Money.zero);
    await sell([express]); // left open at a table
    await expectLater(
      cash.close(counted: Money.zero),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('Encore 1 ticket ouvert'))),
    );
    final tablet = CashRepository(db, outbox, drawerId: 'tab', staffId: () => who, checkOpenTickets: false);
    await tablet.open(Money.zero);
    expect((await tablet.close(counted: Money.zero)).difference, Money.zero);
  });
}
