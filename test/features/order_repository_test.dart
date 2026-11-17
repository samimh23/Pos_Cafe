import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/menu/modifiers.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/money/order_totals.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

ProductRow product(String id, String name, int price, {int vat = 1900}) => ProductRow(
  id: id,
  categoryId: 'c1',
  name: name,
  price: price,
  vatRateBp: vat,
  station: 'bar',
  modifierGroupsJson: '[]',
  available: true,
  sortOrder: 0,
);

const shot = ModifierOption(id: 'm-shot', name: 'Extra shot', extraPrice: 500);

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late OrderRepository orders;

  final express = product('p1', 'Express', 1200);
  final croissant = product('p2', 'Croissant', 1500, vat: 700);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    orders = OrderRepository(db, outbox);
  });
  tearDown(() => db.close());

  Future<List<OrderLineRow>> lines() async {
    final open = await orders.watchOpenOrder().first;
    return open == null ? [] : orders.watchLines(open.id).first;
  }

  Future<List<String>> eventTypes() async => [for (final e in await outbox.pending()) e.type];

  test('first product opens an order; same product increases quantity', () async {
    await orders.addProduct(express);
    await orders.addProduct(express);
    await orders.addProduct(croissant);

    final l = await lines();
    expect(l.map((x) => (x.name, x.qty)), [('Express', 2), ('Croissant', 1)]);
    expect(await eventTypes(), ['order.opened', 'order.item_added', 'order.item_updated', 'order.item_added']);

    final totals = OrderTotals.of(l.map(amountsOf));
    expect(totals.total, const Money(3900));
    expect(totals.itemCount, 3);
    expect(totals.vat.map((v) => v.rateBp), [1900, 700]);
  });

  test('same product with different modifiers = separate lines, price includes modifiers', () async {
    await orders.addProduct(express);
    await orders.addProduct(express, modifiers: [shot]);
    await orders.addProduct(express, modifiers: [shot]);

    final l = await lines();
    expect(l, hasLength(2));
    final withShot = l.firstWhere((x) => x.modifiersPrice > 0);
    expect((withShot.qty, withShot.modifiersPrice), (2, 500));
    expect(OrderTotals.of(l.map(amountsOf)).total, const Money(1200 + 2 * 1700));

    final added = (await outbox.pending()).where((e) => e.type == 'order.item_added').last;
    expect(jsonDecode(added.payloadJson)['modifiers'], [shot.toJson()]);
  });

  test('quantity to 0 or remove = line voided (kept for audit, hidden from ticket)', () async {
    await orders.addProduct(express);
    await orders.addProduct(croissant);
    final l = await lines();

    await orders.setQty(l.first.id, 0);
    await orders.removeLine(l.last.id);

    expect(await lines(), isEmpty);
    expect((await db.select(db.orderLines).get()).every((x) => x.voided), isTrue);
    expect((await eventTypes()).where((t) => t == 'order.item_voided'), hasLength(2));
  });

  test('cash payment: receipt number, change, order closed, events recorded', () async {
    await orders.addProduct(express);
    await orders.addProduct(croissant);

    final r = await orders.payCash(tendered: const Money.dt(5), deviceCode: 'T1');

    expect(r.receiptNumber, 'T1-000001');
    expect(r.total, const Money(2700));
    expect(r.change, const Money(2300));
    expect(await orders.watchOpenOrder().first, isNull); // ticket is empty again

    final paid = await db.select(db.orders).getSingle();
    expect((paid.status, paid.total, paid.receiptNumber), ('paid', 2700, 'T1-000001'));
    final payment = await db.select(db.payments).getSingle();
    expect((payment.amount, payment.tendered, payment.changeGiven), (2700, 5000, 2300));

    final closed = (await outbox.pending()).last;
    expect(closed.type, 'order.closed');
    final payload = jsonDecode(closed.payloadJson);
    expect(payload['receiptNumber'], 'T1-000001');
    expect(payload['vat'], hasLength(2));

    // Next order gets the next receipt number.
    await orders.addProduct(express);
    expect((await orders.payCash(tendered: const Money(1200), deviceCode: 'T1')).receiptNumber, 'T1-000002');
  });

  test('not enough cash → refused, nothing saved', () async {
    await orders.addProduct(express);
    final before = (await outbox.pending()).length;

    await expectLater(
      orders.payCash(tendered: const Money(1000), deviceCode: 'T1'),
      throwsA(isA<OrderException>().having((e) => e.message, 'message', contains('insuffisant'))),
    );
    expect((await db.select(db.orders).getSingle()).status, 'open');
    expect(await db.select(db.payments).get(), isEmpty);
    expect((await outbox.pending()).length, before);
  });

  test('cancel the open order', () async {
    await orders.addProduct(express);
    await orders.cancelOpenOrder();
    expect(await orders.watchOpenOrder().first, isNull);
    expect((await db.select(db.orders).getSingle()).status, 'cancelled');
    expect((await eventTypes()).last, 'order.cancelled');
  });

  test('event sequence numbers stay continuous across all actions', () async {
    await orders.addProduct(express);
    await orders.addProduct(express);
    await orders.payCash(tendered: const Money(2400), deviceCode: 'T1');
    final seqs = [for (final e in await outbox.pending()) e.deviceSeq];
    expect(seqs, List.generate(seqs.length, (i) => i + 1));
  });

  group('modifier groups', () {
    final size = ModifierGroup(
      id: 'g',
      name: 'Taille',
      minSelect: 1,
      maxSelect: 1,
      options: const [ModifierOption(id: 'n', name: 'Normal'), ModifierOption(id: 'g', name: 'Grand', extraPrice: 500)],
    );
    test('required group needs a choice', () => expect(size.validate({}), contains('choisissez')));
    test('valid choice', () => expect(size.validate({'g'}), isNull));
    test('too many', () => expect(size.validate({'n', 'g'}), contains('maximum')));
    test('parse from server JSON', () {
      final groups = parseModifierGroups(
        '[{"id":"g","name":"Taille","minSelect":1,"maxSelect":1,"modifiers":[{"id":"n","name":"Normal","extraPrice":0}]}]',
      );
      expect((groups.single.name, groups.single.options.single.name), ('Taille', 'Normal'));
    });
  });
}
