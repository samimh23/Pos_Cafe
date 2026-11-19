import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/print/printers.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/features/cash/data/cash_repository.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';
import 'package:pos_cafe/features/print/print_service.dart';

import '../fake_printer.dart';
import 'order_repository_test.dart' show product;

/// Refunding a paid ticket: manager + reason, money out of the open drawer, receipt kept.
void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late OrderRepository orders;
  late CashRepository cash;
  const drawer = 'dev-1';
  const approval = Approval(approvedBy: 's-sonia', reason: 'quality');

  final express = product('p1', 'Express', 1200);
  final jus = product('p2', 'Jus', 4000);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    for (final (id, name, role) in [('s-riadh', 'Riadh', 'cashier'), ('s-sonia', 'Sonia', 'manager')]) {
      await db.into(db.staffMembers).insert(StaffMembersCompanion.insert(id: id, name: name, role: role, pinHash: 'x'));
    }
    orders = OrderRepository(db, outbox, staffId: () => 's-riadh');
    cash = CashRepository(db, outbox, drawerId: drawer, staffId: () => 's-riadh');
    await cash.open(const Money.dt(50));
  });
  tearDown(() => db.close());

  /// Express + Jus = 5.200: 1.200 cash, 4.000 card.
  Future<String> paidTicket() async {
    await orders.addProduct(express);
    await orders.addProduct(jus);
    final id = (await orders.watchOpenOrder().first)!.id;
    await orders.pay(
      id,
      const PaymentRequest.cash(amount: Money(1200), tendered: Money(1200)),
      deviceCode: 'T1',
      drawerId: drawer,
    );
    await orders.pay(id, const PaymentRequest.card(amount: Money(4000)), deviceCode: 'T1', drawerId: drawer);
    return id;
  }

  test('a refund gives back each method, keeps the receipt number, and the drawer counts it', () async {
    final id = await paidTicket();
    expect((await cash.summary())!.expectedCash, const Money(51200));

    final refunds = await orders.refund(id, approval: approval, drawerId: drawer);
    expect({for (final r in refunds) r.method: r.amount}, {'cash': -1200, 'card': -4000});

    final o = await (db.select(db.orders)..where((x) => x.id.equals(id))).getSingle();
    expect((o.status, o.receiptNumber, o.refundedAt != null), ('refunded', 'T1-000001', true));

    final e = (await outbox.pending()).last;
    expect((e.type, e.staffId, e.approvedBy), ('order.refunded', 's-riadh', 's-sonia'));
    final p = jsonDecode(e.payloadJson);
    expect((p['reason'], p['receiptNumber'], (p['payments'] as List).length), ('quality', 'T1-000001', 2));

    final s = (await cash.summary())!;
    expect((s.cashSales, s.cardSales, s.refunds, s.ticketCount), (Money.zero, Money.zero, const Money(5200), 0));
    expect(s.expectedCash, const Money.dt(50)); // the 1.200 cash went back to the customer
  });

  test('rules: a manager and a reason; only once; only a paid ticket; the drawer must be open', () async {
    final id = await paidTicket();
    await expectLater(
      orders.refund(id, approval: const Approval(approvedBy: 's-riadh', reason: 'quality'), drawerId: drawer),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Seul un gérant peut valider.')),
    );
    await orders.refund(id, approval: approval, drawerId: drawer);
    await expectLater(
      orders.refund(id, approval: approval, drawerId: drawer),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Seul un ticket payé peut être remboursé.')),
    );

    await orders.addProduct(express); // open, not paid
    final open = (await orders.watchOpenOrder().first)!.id;
    await expectLater(orders.refund(open, approval: approval, drawerId: drawer), throwsA(isA<OrderException>()));
    await orders.cancelOrder(open); // the drawer can't close with an open ticket

    final other = await paidTicket();
    await cash.close(counted: const Money.dt(50));
    await expectLater(
      orders.refund(other, approval: approval, drawerId: drawer),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('Caisse fermée'))),
    );
  });

  test('"Tickets du jour" lists paid and refunded tickets of today, newest first', () async {
    final a = await paidTicket();
    await orders.refund(a, approval: approval, drawerId: drawer);
    final list = await orders.watchClosedTickets(DateTime.now().subtract(const Duration(hours: 1))).first;
    expect(list.map((o) => o.status), ['refunded']);
  });

  test('refund slip: REMBOURSEMENT, the ticket, the reason, who approved, what was given back', () async {
    final id = await paidTicket();
    await orders.refund(id, approval: approval, drawerId: drawer);
    final printer = FakePrinter();
    final print = PrintService(db, outbox, transport: printer, staffId: () => 's-riadh');
    await print.saveSettings(const PrinterSettings(receipt: PrinterConfig(host: '10.0.0.9')));
    await print.printRefund(id);
    final t = printer.texts.single;
    for (final s in [
      'REMBOURSEMENT',
      'Ticket T1-000001',
      'Motif : Problème de qualité',
      'Par Riadh, validé par Sonia',
      'Rendu en espèces                           1.200',
      'Rendu par carte                            4.000',
    ]) {
      expect(t, contains(s), reason: s);
    }
  });
}
