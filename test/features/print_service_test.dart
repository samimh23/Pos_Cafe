import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/print/escpos.dart';
import 'package:pos_cafe/core/print/printers.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/cash/data/cash_repository.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';
import 'package:pos_cafe/features/print/print_service.dart';

import '../core/sync_engine_test.dart' show identity;
import '../fake_printer.dart';
import '../fakes.dart';
import '../order_helpers.dart';
import 'order_repository_test.dart' show product;

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late OrderRepository orders;
  late FakePrinter printer;
  late PrintService print;
  late DiningTableRow t2;

  const counter = PrinterConfig(host: '192.168.1.50');
  const kitchen = PrinterConfig(host: '192.168.1.51', width: 32);
  final express = product('p1', 'Express', 1200); // station: bar (see product())
  final crepe = ProductRow(
    id: 'p9',
    categoryId: 'c1',
    name: 'Crêpe chocolat',
    price: 5500,
    vatRateBp: 700,
    station: 'kitchen',
    modifierGroupsJson: '[]',
    available: true,
    sortOrder: 0,
  );
  final croissant = ProductRow(
    id: 'p8',
    categoryId: 'c1',
    name: 'Croissant',
    price: 1500,
    vatRateBp: 700,
    station: 'none',
    modifierGroupsJson: '[]',
    available: true,
    sortOrder: 0,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    await SyncEngine(db, FakePosApi()..withFloor(), outbox, identity).syncNow(); // business info, staff, tables
    orders = OrderRepository(db, outbox, staffId: () => 'staff-ahmed');
    printer = FakePrinter();
    print = PrintService(
      db,
      outbox,
      transport: printer,
      staffId: () => 'staff-ahmed',
      clock: () => DateTime(2026, 11, 19, 14, 5),
    );
    t2 = await (db.select(db.diningTables)..where((t) => t.id.equals('table-2'))).getSingle();
    await openTestDrawer(db);
  });
  tearDown(() => db.close());

  Future<String> order(List<ProductRow> items) async {
    for (final p in items) {
      await orders.addProduct(p, table: t2);
    }
    return (await orders.watchOpenOrder(tableId: t2.id).first)!.id;
  }

  test('"Envoyer": bar and kitchen tickets, big and readable; only new items next time', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter, kitchen: kitchen));
    final id = await order([express, express, crepe, croissant]);

    final r = await print.sendOrder(id);
    expect(r.printed, {'bar': 2, 'kitchen': 1});
    expect(r.message, 'Envoyé : 2 au bar, 1 en cuisine');

    final bar = printer.textsFor(counter.label).single; // no bar printer → the counter one
    expect(bar, contains('BAR'));
    expect(bar, contains('TABLE 2'));
    expect(bar, contains('14:05 · Ahmed'));
    expect(bar, contains('2 X EXPRESS'));
    expect(bar, isNot(contains('CROISSANT'))); // no station: not printed
    final kit = printer.textsFor(kitchen.label).single;
    expect(kit, contains('CUISINE'));
    // 58 mm in big letters = 16 characters a line: the name wraps.
    expect(kit, contains('1 X CRÊPE\nCHOCOLAT'));

    // Everything is marked sent (the croissant too); nothing new → nothing printed.
    expect((await db.select(db.orderLines).get()).every((l) => l.sentAt != null), isTrue);
    expect((await print.sendOrder(id)).message, 'Rien de nouveau à envoyer.');
    expect(printer.sent.length, 2);

    // A new round: only the new item goes.
    await orders.addProduct(crepe, table: t2);
    await print.sendOrder(id);
    expect(printer.textsFor(kitchen.label).last, contains('1 X CRÊPE'));
    expect(printer.sent.length, 3);
    expect((await outbox.pending()).where((e) => e.type == 'order.sent').length, 4); // bar, kitchen, none, kitchen
  });

  test('+ on an item already sent adds a new line, so the extra is sent too', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter));
    final id = await order([express]);
    await print.sendOrder(id);
    final sent = (await db.select(db.orderLines).getSingle());
    await orders.setQty(sent.id, 3); // the table wants 2 more
    final lines = await db.select(db.orderLines).get();
    expect([for (final l in lines) (l.qty, l.sentAt != null)], unorderedEquals([(1, true), (2, false)]));
    expect((await print.sendOrder(id)).printed, {'bar': 2});
    expect(printer.texts.last, contains('2 X EXPRESS'));
  });

  test('a printer off: its items stay unsent (tap Envoyer again); the others are sent', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter, kitchen: kitchen));
    final id = await order([express, crepe]);
    printer.offline.add(kitchen.label);

    await expectLater(
      print.sendOrder(id),
      throwsA(isA<PrintException>().having((e) => e.message, 'm', contains('192.168.1.51'))),
    );
    final lines = await db.select(db.orderLines).get();
    expect({for (final l in lines) l.name: l.sentAt != null}, {'Express': true, 'Crêpe chocolat': false});

    printer.offline.clear();
    expect((await print.sendOrder(id)).printed, {'kitchen': 1});
  });

  test('no printer set → a clear message, nothing marked sent', () async {
    final id = await order([express]);
    await expectLater(print.sendOrder(id), throwsA(isA<PrintException>()));
    await expectLater(print.printBill(id), throwsA(isA<PrintException>()));
    expect((await db.select(db.orderLines).getSingle()).sentAt, isNull);
  });

  test('customer receipt: café header with MF, items, total, cash and change, VAT, footer', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter));
    final id = await order([express, express, croissant]); // 3.900
    await orders.pay(
      id,
      const PaymentRequest.cash(amount: Money(3900), tendered: Money.dt(5)),
      deviceCode: 'T1',
      drawerId: testDrawer,
    );
    await print.printReceipt(id);
    final t = printer.texts.single;
    for (final s in [
      "SAMI'S COFFE",
      'Rue de Marseille, Tunis',
      'MF : 1234567/A/M/000',
      'Ticket T1-000001',
      'Table 2',
      'Servi par Ahmed',
      '2 x Express',
      'TOTAL 3.900 DT',
      'Rendu',
      '1.100',
      'TVA 19%',
      'TVA 7%',
      'Merci de votre visite !',
    ]) {
      expect(t, contains(s), reason: s);
    }
    expect(printer.tickets.single.every((l) => l.length <= 48), isTrue);
  });

  test('discounts are printed under their item, with the total of discounts', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter));
    await db
        .into(db.staffMembers)
        .insertOnConflictUpdate(
          StaffMembersCompanion.insert(id: 's-boss', name: 'Sonia', role: 'manager', pinHash: 'x'),
        );
    final id = await order([express, express, crepe]); // 2.400 + 5.500
    final line = (await orders.watchLines(id).first).firstWhere((l) => l.name == 'Express');
    await orders.discount(id, DiscountRequest.free(reason: 'geste', lineIds: [line.id], approvedBy: 's-boss'));
    await orders.pay(id, const PaymentRequest.card(amount: Money(5500)), deviceCode: 'T1', drawerId: testDrawer);
    await print.printReceipt(id);
    final t = printer.texts.single;
    expect(t, contains('2 x Express'));
    expect(t, contains('Offert (Geste commercial)'));
    expect(t, contains('-2.400'));
    expect(t, contains('Remises & offerts'));
    expect(t, contains('TOTAL 5.500 DT'));
  });

  test('l’addition: what is left after a partial payment; not a receipt', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter));
    final id = await order([express, crepe]); // 6.700
    await orders.pay(id, const PaymentRequest.card(amount: Money(1200)), deviceCode: 'T1', drawerId: testDrawer);
    await print.printBill(id);
    final t = printer.texts.single;
    expect(t, contains('ADDITION'));
    expect(t, contains('Déjà payé'));
    expect(t, contains('RESTE À PAYER'));
    expect(t, contains('5.500 DT'));
    expect(t, contains("Ceci n'est pas un ticket de caisse")); // ’ prints as '
  });

  test('closing report prints the gap', () async {
    await print.saveSettings(const PrinterSettings(receipt: counter));
    final cash = CashRepository(db, outbox, drawerId: 'dev-1', staffId: () => null);
    await cash.open(const Money.dt(50));
    final closing = CashClosing(
      summary: (await cash.summary())!,
      counted: const Money(49500),
      closedAt: DateTime(2026, 11, 19, 23),
      closedBy: 'Riadh',
      note: null,
    );
    await print.printCashReport(closing, drawer: 'T1');
    final t = printer.texts.single;
    expect(t, contains('CLÔTURE DE CAISSE · T1'));
    expect(t, contains('Espèces attendues'));
    expect(t, contains('-0.500'));
  });

  test('real network: bytes reach a printer listening on a port (like the virtual printer)', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final received = BytesBuilder();
    final done = server.first.then((s) => s.forEach(received.add));
    await const NetworkPrinterTransport().send(
      PrinterConfig(host: '127.0.0.1', port: server.port),
      (EscPos()
            ..text('Bonjour Kahwti')
            ..cut())
          .bytes(),
    );
    await done;
    await server.close();
    expect(decodeEscPos(received.toBytes()).single, ['Bonjour Kahwti']);

    await expectLater(
      const NetworkPrinterTransport().send(const PrinterConfig(host: '127.0.0.1', port: 1), Uint8List(1)),
      throwsA(isA<PrintException>().having((e) => e.message, 'm', contains('injoignable'))),
    );
  });
}
