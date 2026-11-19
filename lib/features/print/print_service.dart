import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../core/menu/modifiers.dart';
import '../../core/money/money.dart';
import '../../core/money/order_totals.dart';
import '../../core/print/business_info.dart';
import '../../core/print/documents.dart';
import '../../core/print/printers.dart';
import '../../core/print/windows_printer.dart';
import '../../core/sync/outbox_repository.dart';
import '../../core/sync/sync_event_types.dart';
import '../cash/data/cash_repository.dart';
import '../order/data/order_repository.dart' show amountsOf;

/// What was sent where by "Envoyer".
class SendResult {
  /// station → number of items printed there.
  final Map<String, int> printed;
  const SendResult(this.printed);
  int get total => printed.values.fold(0, (a, b) => a + b);

  /// "Envoyé : 2 au bar, 1 en cuisine"
  String get message {
    if (printed.isEmpty) return 'Rien de nouveau à envoyer.';
    final parts = [
      if (printed['bar'] != null) '${printed['bar']} au bar',
      if (printed['kitchen'] != null) '${printed['kitchen']} en cuisine',
    ];
    return parts.isEmpty ? 'Envoyé.' : 'Envoyé : ${parts.join(', ')}';
  }
}

/// What the order screen can print. On the main POS (or a POS alone) it prints
/// here; on a tablet it asks the main POS, which has the printers.
abstract interface class PrintActions {
  /// Sends the new items of a ticket to the bar / kitchen printers.
  Future<SendResult> sendOrder(String orderId);
  Future<void> printBill(String orderId);
  Future<void> printReceipt(String orderId);
}

/// Prints on the printers set on this POS (⋮ → Imprimantes).
class PrintService implements PrintActions {
  PrintService(
    this._db,
    this._outbox, {
    PrinterTransport transport = const AutoPrinterTransport(),
    String? Function()? staffId,
    DateTime Function()? clock,
  }) : _transport = transport,
       _staffId = staffId ?? (() => null),
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final PrinterTransport _transport;
  final String? Function() _staffId;
  final DateTime Function() _now;

  Future<PrinterSettings> settings() async => PrinterSettings.decode(await _db.getKv(PrinterSettings.kvKey));
  Future<void> saveSettings(PrinterSettings s) => _db.setKv(PrinterSettings.kvKey, s.encode());
  Future<BusinessInfo?> _business() async => BusinessInfo.decode(await _db.getKv(BusinessInfo.kvKey));

  Future<String?> _staffName() async {
    final id = _staffId();
    if (id == null) return null;
    return (await (_db.select(_db.staffMembers)..where((s) => s.id.equals(id))).getSingleOrNull())?.name;
  }

  PrintLine _line(OrderLineRow l) => PrintLine(
    qty: l.qty,
    name: l.name,
    modifiers: [for (final m in parseChosenModifiers(l.modifiersJson)) m.name],
    total: lineTotal(amountsOf(l)),
  );

  Future<OrderRow> _order(String id) async {
    final o = await (_db.select(_db.orders)..where((o) => o.id.equals(id))).getSingleOrNull();
    if (o == null) throw const PrintException('Ticket introuvable.');
    return o;
  }

  Future<List<OrderLineRow>> _lines(String orderId) =>
      (_db.select(_db.orderLines)
            ..where((l) => l.orderId.equals(orderId) & l.voided.equals(false))
            ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
          .get();

  Future<PrinterConfig> _receiptPrinter() async {
    final p = (await settings()).receipt;
    if (p == null) throw const PrintException('Aucune imprimante de tickets. Configurez-la : ⋮ → Imprimantes.');
    return p;
  }

  // ── Bar / kitchen ────────────────────────────────────────

  /// New items (not sent yet) → one ticket per station. A station whose printer
  /// fails keeps its items unsent, so "Envoyer" can be tapped again.
  @override
  Future<SendResult> sendOrder(String orderId) async {
    final order = await _order(orderId);
    final s = await settings();
    final unsent = (await _lines(orderId)).where((l) => l.sentAt == null).toList();
    final printed = <String, int>{};
    final staff = await _staffName();
    final now = _now();
    final failures = <String>[];

    for (final station in ['bar', 'kitchen', 'none']) {
      final group =
          unsent
              .where(
                (l) => (l.station == station) || (station == 'none' && l.station != 'bar' && l.station != 'kitchen'),
              )
              .toList();
      if (group.isEmpty) continue;
      if (station != 'none') {
        final printer = s.forStation(station);
        if (printer == null) {
          throw const PrintException('Aucune imprimante pour le bar ou la cuisine. Configurez-la : ⋮ → Imprimantes.');
        }
        try {
          await _transport.send(
            printer,
            stationDocument(
              width: printer.width,
              station: station,
              at: now,
              table: order.tableLabel,
              staff: staff,
              lines: [for (final l in group) _line(l)],
            ),
          );
          printed[station] = group.fold(0, (sum, l) => sum + l.qty);
        } on PrintException catch (e) {
          failures.add(e.message);
          continue; // stays unsent
        }
      }
      // Items with no station (e.g. a croissant from the counter) are just marked as sent.
      final ids = [for (final l in group) l.id];
      await _db.transaction(() async {
        await (_db.update(_db.orderLines)..where((l) => l.id.isIn(ids))).write(OrderLinesCompanion(sentAt: Value(now)));
        await _outbox.record(
          staffId: _staffId(),
          type: EventTypes.orderSent,
          entityId: orderId,
          payload: {'station': station, 'lineIds': ids},
        );
      });
    }
    if (failures.isNotEmpty) throw PrintException(failures.join('\n'));
    return SendResult(printed);
  }

  // ── Customer documents ───────────────────────────────────

  @override
  Future<void> printBill(String orderId) async {
    final printer = await _receiptPrinter();
    final order = await _order(orderId);
    final lines = await _lines(orderId);
    final paid = (await (_db.select(_db.payments)..where((p) => p.orderId.equals(orderId))).get()).fold(
      Money.zero,
      (sum, p) => sum + Money(p.amount),
    );
    await _transport.send(
      printer,
      billDocument(
        width: printer.width,
        business: await _business(),
        at: _now(),
        table: order.tableLabel,
        staff: await _staffName(),
        lines: [for (final l in lines) _line(l)],
        total: OrderTotals.of(lines.map(amountsOf)).total,
        paid: paid,
      ),
    );
  }

  @override
  Future<void> printReceipt(String orderId) async {
    final printer = await _receiptPrinter();
    final order = await _order(orderId);
    if (order.receiptNumber == null) throw const PrintException('Ce ticket n’est pas encore payé.');
    final lines = await _lines(orderId);
    final totals = OrderTotals.of(lines.map(amountsOf));
    final payments = await (_db.select(_db.payments)..where((p) => p.orderId.equals(orderId))).get();
    await _transport.send(
      printer,
      receiptDocument(
        width: printer.width,
        business: await _business(),
        receiptNumber: order.receiptNumber!,
        at: order.closedAt ?? _now(),
        table: order.tableLabel,
        staff: await _staffName(),
        lines: [for (final l in lines) _line(l)],
        total: totals.total,
        vat: totals.vat,
        payments: [
          for (final p in payments)
            PrintPayment(
              method: p.method,
              amount: Money(p.amount),
              tendered: Money(p.tendered),
              change: Money(p.changeGiven),
            ),
        ],
      ),
    );
  }

  // ── Cash and test ────────────────────────────────────────

  Future<void> printCashReport(CashClosing c, {required String drawer}) async {
    final printer = await _receiptPrinter();
    final s = c.summary;
    await _transport.send(
      printer,
      cashReportDocument(
        width: printer.width,
        business: await _business(),
        drawer: drawer,
        openedAt: s.openedAt,
        openedBy: s.openedBy,
        closedAt: c.closedAt,
        closedBy: c.closedBy,
        openingFloat: s.openingFloat,
        cashSales: s.cashSales,
        cashIn: s.cashIn,
        cashOut: s.cashOut,
        expected: s.expectedCash,
        counted: c.counted,
        cardSales: s.cardSales,
        tickets: s.ticketCount,
        note: c.note,
      ),
    );
  }

  Future<void> printTest(PrinterConfig printer) =>
      _transport.send(printer, testDocument(width: printer.width, label: printer.label));
}
