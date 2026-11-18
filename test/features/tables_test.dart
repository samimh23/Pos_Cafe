import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';
import 'package:pos_cafe/features/order/view/payment_dialog.dart';

import '../core/sync_engine_test.dart' show identity;
import '../fakes.dart';
import 'order_repository_test.dart' show product;

/// Several tickets at once (tables + counter), moving tickets, split payments.
void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late OrderRepository orders;
  late FakePosApi api;
  late DiningTableRow t1, t2, terrasse;

  final express = product('p1', 'Express', 1200);
  final croissant = product('p2', 'Croissant', 1500, vat: 700);
  final jus = product('p3', 'Jus', 4000);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    orders = OrderRepository(db, outbox);
    api = FakePosApi()..withFloor();
    await SyncEngine(db, api, outbox, identity).pullMenu();
    final tables = {for (final t in await db.select(db.diningTables).get()) t.id: t};
    (t1, t2, terrasse) = (tables['table-1']!, tables['table-2']!, tables['table-t1']!);
  });
  tearDown(() => db.close());

  Future<OrderRow> openAt(DiningTableRow? t) async => (await orders.watchOpenOrder(tableId: t?.id).first)!;
  Future<List<Map<String, dynamic>>> events(String type) async => [
    for (final e in await outbox.pending())
      if (e.type == type) jsonDecode(e.payloadJson) as Map<String, dynamic>,
  ];

  test('sync brings rooms and tables; deleted ones disappear', () async {
    expect((await db.select(db.floorAreas).get()).map((a) => a.name), containsAll(['Salle', 'Terrasse']));
    expect(await db.select(db.diningTables).get(), hasLength(5));

    api.changedTables = [
      {...api.tables.first, 'deleted': true},
      {...api.tables[1], 'name': '2 bis'},
    ];
    await SyncEngine(db, api, outbox, identity).pullMenu();
    final names = (await db.select(db.diningTables).get()).map((t) => t.name);
    expect(names, isNot(contains('1')));
    expect(names, contains('2 bis'));
  });

  test('table 1, table 2 and the counter each have their own open ticket', () async {
    await orders.addProduct(express, table: t1);
    await orders.addProduct(express, table: t1);
    await orders.addProduct(croissant, table: t2);
    await orders.addProduct(jus); // counter

    final o1 = await openAt(t1);
    expect((o1.type, o1.tableLabel), ('table', '1'));
    expect((await openAt(null)).tableId, isNull);

    final tickets = await orders.watchOpenTickets().first;
    expect(
      {for (final t in tickets) t.tableLabel: t.total},
      {'1': const Money(2400), '2': const Money(1500), null: const Money(4000)},
    );
    final opened = await events('order.opened');
    expect(opened.first, {'type': 'table', 'tableId': 'table-1', 'tableName': '1'});
    expect(opened.last, {'type': 'takeaway'});
  });

  test('move a ticket to a free table; a busy table is refused; back to the counter', () async {
    await orders.addProduct(express, table: t1);
    await orders.addProduct(croissant, table: t2);
    final o1 = await openAt(t1);

    await expectLater(
      orders.moveOrder(o1.id, t2),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'La table 2 est occupée.')),
    );

    await orders.moveOrder(o1.id, terrasse);
    expect(await orders.watchOpenOrder(tableId: t1.id).first, isNull); // table 1 is free again
    expect((await openAt(terrasse)).id, o1.id);
    expect((await events('order.table_changed')).single, {'tableId': 'table-t1', 'tableName': 'T1'});

    await orders.moveOrder(o1.id, null);
    expect((await openAt(null)).id, o1.id);
    expect((await events('order.table_changed')).last, {'tableId': null, 'tableName': null});
  });

  test('split in 2 equal shares: first share leaves the rest, second one closes with a receipt', () async {
    await orders.addProduct(express, table: t1);
    await orders.addProduct(express, table: t1);
    await orders.addProduct(croissant, table: t1); // 3.900
    final o = await openAt(t1);

    final share = shareOf(const Money(3900), 2);
    expect(share, const Money(1950));
    final first = await orders.pay(
      o.id,
      PaymentRequest.cash(amount: share, tendered: const Money.dt(5)),
      deviceCode: 'T1',
    );
    expect((first.closed, first.change, first.remaining), (false, const Money(3050), const Money(1950)));
    expect(await orders.watchPaid(o.id).first, const Money(1950));
    expect(await events('order.closed'), isEmpty);

    final second = await orders.pay(o.id, const PaymentRequest.card(amount: Money(1950)), deviceCode: 'T1');
    expect((second.closed, second.receiptNumber, second.change), (true, 'T1-000001', Money.zero));
    expect(await orders.watchOpenOrder(tableId: t1.id).first, isNull); // table free

    final payments = await events('payment.added');
    expect(payments.map((p) => (p['method'], p['amount'], p['change'])), [('cash', 1950, 3050), ('card', 1950, 0)]);
    expect((await events('order.closed')).single['total'], 3900);
  });

  test('split by items: each pays their own; paid lines are locked; can’t pay a line twice', () async {
    await orders.addProduct(express, table: t1);
    await orders.addProduct(jus, table: t1);
    final o = await openAt(t1);
    final lines = await orders.watchLines(o.id).first;
    final expressLine = lines.firstWhere((l) => l.name == 'Express');
    final jusLine = lines.firstWhere((l) => l.name == 'Jus');

    final r = await orders.pay(
      o.id,
      PaymentRequest.cash(amount: Money.zero, tendered: const Money.dt(2), lineIds: [expressLine.id]),
      deviceCode: 'T1',
    );
    expect((r.amount, r.change, r.remaining), (const Money(1200), const Money(800), const Money(4000)));
    expect((await events('payment.added')).single['lineIds'], [expressLine.id]);

    // The paid Express can't be changed or paid again.
    await expectLater(orders.setQty(expressLine.id, 2), throwsA(isA<OrderException>()));
    await expectLater(orders.removeLine(expressLine.id), throwsA(isA<OrderException>()));
    await expectLater(
      orders.pay(o.id, PaymentRequest.card(amount: Money.zero, lineIds: [expressLine.id]), deviceCode: 'T1'),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('déjà payé'))),
    );

    // A new Express goes on a NEW line (the paid one stays as it was).
    await orders.addProduct(express, table: t1);
    final now = await orders.watchLines(o.id).first;
    expect(now.where((l) => l.name == 'Express').map((l) => (l.qty, l.paymentId != null)), [(1, true), (1, false)]);

    final last = await orders.pay(
      o.id,
      PaymentRequest.card(amount: Money.zero, lineIds: [jusLine.id, now.last.id]),
      deviceCode: 'T1',
    );
    expect((last.amount, last.closed), (const Money(5200), true));
  });

  test('after a partial payment: no cancel, and no removing items below what was paid', () async {
    await orders.addProduct(express, table: t1);
    await orders.addProduct(jus, table: t1); // 5.200
    final o = await openAt(t1);
    await orders.pay(o.id, const PaymentRequest.card(amount: Money(4500)), deviceCode: 'T1');

    await expectLater(orders.cancelOrder(o.id), throwsA(isA<OrderException>()));
    final jusLine = (await orders.watchLines(o.id).first).firstWhere((l) => l.name == 'Jus');
    await expectLater(
      orders.removeLine(jusLine.id), // 5.200 − 4.000 = 1.200 < 4.500 already paid
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('4.500 DT déjà payé'))),
    );
    // Adding is always fine.
    await orders.addProduct(croissant, table: t1);
    expect((await orders.watchOpenTickets().first).single.remaining, const Money(2200));
  });

  test('wrong amounts are refused and nothing is saved', () async {
    await orders.addProduct(express, table: t1);
    final o = await openAt(t1);
    final before = (await outbox.pending()).length;

    await expectLater(
      orders.pay(o.id, const PaymentRequest.card(amount: Money(5000)), deviceCode: 'T1'),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('il reste 1.200 DT'))),
    );
    await expectLater(
      orders.pay(o.id, const PaymentRequest.cash(amount: Money(1200), tendered: Money(1000)), deviceCode: 'T1'),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('insuffisant'))),
    );
    expect(await db.select(db.payments).get(), isEmpty);
    expect((await outbox.pending()).length, before);
  });

  test('shares: the last share is never more than what is left', () {
    expect(shareOf(const Money(1000), 3), const Money(334));
    expect(shareOf(const Money(666), 2), const Money(333));
    expect(shareOf(const Money(1), 4), const Money(1));
  });
}
