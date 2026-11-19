import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/print/printers.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';
import 'package:pos_cafe/features/print/print_service.dart';

import '../fake_printer.dart';
import 'order_repository_test.dart' show product;

/// Taking back something already at the bar/kitchen: manager + reason, and an ANNULÉ slip.
void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late OrderRepository orders;
  late PrintService print;
  late FakePrinter printer;
  const counter = PrinterConfig(host: '10.0.0.9');
  const approval = Approval(approvedBy: 's-sonia', reason: 'changed_mind');

  final express = product('p1', 'Express', 1200); // bar

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    for (final (id, name, role) in [('s-ahmed', 'Ahmed', 'server'), ('s-sonia', 'Sonia', 'manager')]) {
      await db.into(db.staffMembers).insert(StaffMembersCompanion.insert(id: id, name: name, role: role, pinHash: 'x'));
    }
    orders = OrderRepository(db, outbox, staffId: () => 's-ahmed');
    printer = FakePrinter();
    print = PrintService(db, outbox, transport: printer, staffId: () => 's-ahmed');
    await print.saveSettings(const PrinterSettings(receipt: counter));
  });
  tearDown(() => db.close());

  Future<(String, OrderLineRow)> sentExpresses(int n) async {
    for (var i = 0; i < n; i++) {
      await orders.addProduct(express);
    }
    final id = (await orders.watchOpenOrder().first)!.id;
    await print.sendOrder(id);
    return (id, (await orders.watchLines(id).first).single);
  }

  Future<Map<String, dynamic>> lastPayload() async => jsonDecode((await outbox.pending()).last.payloadJson);

  test('before "Envoyer": − works freely (nothing to approve)', () async {
    await orders.addProduct(express);
    await orders.addProduct(express);
    final id = (await orders.watchOpenOrder().first)!.id;
    final l = (await orders.watchLines(id).first).single;
    await orders.setQty(l.id, 1);
    expect((await orders.watchLines(id).first).single.qty, 1);
  });

  test('after "Envoyer": − needs a manager and a reason; the event says who and why', () async {
    final (_, l) = await sentExpresses(2);
    await expectLater(
      orders.setQty(l.id, 1),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', contains('validation d’un gérant'))),
    );
    await expectLater(
      orders.setQty(l.id, 1, approval: const Approval(approvedBy: 's-ahmed', reason: 'error')),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Seul un gérant peut valider.')),
    );
    await expectLater(
      orders.setQty(l.id, 1, approval: const Approval(approvedBy: 's-sonia', reason: 'why not')),
      throwsA(isA<OrderException>().having((e) => e.message, 'm', 'Choisissez le motif.')),
    );

    await orders.setQty(l.id, 1, approval: approval);
    final e = (await outbox.pending()).last;
    expect((e.type, e.approvedBy), ('order.item_updated', 's-sonia'));
    expect(await lastPayload(), {'lineId': l.id, 'qty': 1, 'why': 'changed_mind'});

    await orders.removeLine(l.id, approval: approval);
    expect(await lastPayload(), {'lineId': l.id, 'reason': 'removed_after_send', 'why': 'changed_mind'});
  });

  test('cancelling a ticket with sent items needs a manager; the event keeps the reason', () async {
    final (id, _) = await sentExpresses(1);
    await expectLater(orders.cancelOrder(id), throwsA(isA<OrderException>()));
    await orders.cancelOrder(id, approval: const Approval(approvedBy: 's-sonia', reason: 'quality'));
    final e = (await outbox.pending()).last;
    expect((e.type, e.approvedBy, jsonDecode(e.payloadJson)['reason']), ('order.cancelled', 's-sonia', 'quality'));
  });

  test('the bar gets an "ANNULÉ" slip with the quantity and the reason', () async {
    final (id, l) = await sentExpresses(2);
    await orders.setQty(l.id, 1, approval: approval);
    await print.printCancellation(id, items: [(l.id, 1)], reason: 'changed_mind');
    final slip = printer.texts.last;
    expect(slip, contains('ANNULÉ BAR'));
    expect(slip, contains('-1 X EXPRESS'));
    expect(slip, contains('Motif : Le client a changé d\'avis'));
  });
}
