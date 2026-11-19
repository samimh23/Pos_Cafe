import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ids.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_event_types.dart';
import 'discounts.dart';

/// What the cashier asks for when paying (all or part of a ticket).
class PaymentRequest {
  /// cash | card
  final String method;

  /// Part of the ticket paid now. Ignored when [lineIds] is set (the lines decide).
  final Money amount;

  /// Cash given by the customer (card: same as the amount).
  final Money tendered;

  /// "Split by items": these lines are paid now, and can't be changed afterwards.
  final List<String> lineIds;

  const PaymentRequest.cash({required this.amount, required this.tendered, this.lineIds = const []}) : method = 'cash';
  const PaymentRequest.card({required this.amount, this.lineIds = const []}) : method = 'card', tendered = amount;
}

class PaymentResult {
  /// Set when this payment completed the ticket (it is closed).
  final String? receiptNumber;
  final Money amount;
  final Money change;

  /// Still to pay on this ticket (zero when closed).
  final Money remaining;
  final Money total;
  const PaymentResult({
    required this.receiptNumber,
    required this.amount,
    required this.change,
    required this.remaining,
    required this.total,
  });
  bool get closed => receiptNumber != null;
}

/// An open ticket, for the tables screen.
class OpenTicket {
  final String orderId;
  final String? tableId;
  final String? tableLabel;
  final DateTime openedAt;
  final Money total;
  final Money paid;

  /// A server asked for the bill.
  final bool billRequested;
  const OpenTicket({
    required this.orderId,
    required this.tableId,
    required this.tableLabel,
    required this.openedAt,
    required this.total,
    required this.paid,
    this.billRequested = false,
  });
  Money get remaining => total - paid;
}

class OrderException implements Exception {
  final String message;
  const OrderException(this.message);
  @override
  String toString() => message;
}

/// What the order screen can do. On the Hub and on a POS working alone this is
/// the local [OrderRepository]; on a server tablet the actions go to the Hub.
abstract interface class OrderActions {
  Future<void> addProduct(ProductRow p, {DiningTableRow? table, List<ModifierOption> modifiers});
  Future<void> setQty(String lineId, int qty);
  Future<void> removeLine(String lineId);
  Future<void> cancelOrder(String orderId);
  Future<void> moveOrder(String orderId, DiningTableRow? to);

  /// [drawerId]: the cash drawer (device id) the money goes into — it must be open.
  Future<PaymentResult> pay(String orderId, PaymentRequest req, {required String deviceCode, required String drawerId});
  Future<void> requestBill(String orderId);

  /// Offert / % / amount on some lines or the whole ticket (reason + manager required).
  Future<void> discount(String orderId, DiscountRequest request);

  /// Back to the full price (no approval needed).
  Future<void> removeDiscount(String orderId, List<String> lineIds);
}

LineAmounts amountsOf(OrderLineRow l) => (
  unitPrice: l.unitPrice,
  modifiersPrice: l.modifiersPrice,
  qty: l.qty,
  vatRateBp: l.vatRateBp,
  voided: l.voided,
  discountType: l.discountType,
  discountValue: l.discountValue,
);

/// Model layer for orders. Every method changes the local data AND records the
/// matching sync event in ONE transaction — both are saved, or neither.
///
/// Several orders can be open at once: one per table, plus one at the counter
/// (`tableId == null`, takeaway).
class OrderRepository implements OrderActions {
  OrderRepository(this._db, this._outbox, {DateTime Function()? clock, String? Function()? staffId})
    : _now = clock ?? DateTime.now,
      _staffId = staffId ?? (() => null);

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final DateTime Function() _now;

  /// Who is logged in on the POS — every event says who did it.
  final String? Function() _staffId;

  static const _receiptSeqKey = 'receipt_seq';

  // ── Reads (streams: the UI updates by itself) ─────────────

  /// The open order of a table, or of the counter when [tableId] is null.
  Stream<OrderRow?> watchOpenOrder({String? tableId}) => _openOrderQuery(tableId).watchSingleOrNull();

  Stream<List<OrderLineRow>> watchLines(String orderId) =>
      (_db.select(_db.orderLines)
            ..where((l) => l.orderId.equals(orderId) & l.voided.equals(false))
            ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
          .watch();

  /// Already paid on this ticket (split payments).
  Stream<Money> watchPaid(String orderId) => _paidQuery(orderId).watchSingle().map((r) => Money(r.read<int>('paid')));

  /// All open tickets with their totals — what the tables screen shows.
  Stream<List<OpenTicket>> watchOpenTickets() => _db
      .customSelect(
        '''
        SELECT o.id, o.table_id, o.table_label, o.opened_at, o.bill_requested_at,
          COALESCE((SELECT SUM((l.unit_price + l.modifiers_price) * l.qty) FROM order_lines l
                    WHERE l.order_id = o.id AND l.voided = 0), 0) AS total,
          COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.order_id = o.id), 0) AS paid
        FROM orders o
        WHERE o.status = 'open'
        ORDER BY o.opened_at
        ''',
        readsFrom: {_db.orders, _db.orderLines, _db.payments},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            OpenTicket(
              orderId: r.read<String>('id'),
              tableId: r.readNullable<String>('table_id'),
              tableLabel: r.readNullable<String>('table_label'),
              openedAt: r.read<DateTime>('opened_at'),
              total: Money(r.read<int>('total')),
              paid: Money(r.read<int>('paid')),
              billRequested: r.readNullable<DateTime>('bill_requested_at') != null,
            ),
        ],
      );

  // ── Actions ──────────────────────────────────────────────

  /// Adds a product to the ticket of [table] (null = counter).
  /// Same product with the same modifiers → quantity + 1 (never on a line already paid or sent).
  @override
  Future<void> addProduct(ProductRow p, {DiningTableRow? table, List<ModifierOption> modifiers = const []}) {
    return _db.transaction(() async {
      final orderId = await _openOrderId(table);
      final modifiersJson = jsonEncode([for (final m in modifiers) m.toJson()]);

      final existing =
          await (_db.select(_db.orderLines)
                ..where(
                  (l) =>
                      l.orderId.equals(orderId) &
                      l.productId.equals(p.id) &
                      l.modifiersJson.equals(modifiersJson) &
                      l.voided.equals(false) &
                      l.paymentId.isNull() &
                      // Already sent to the bar/kitchen: a new round is a NEW line, so it gets sent too.
                      l.sentAt.isNull() &
                      // An offered coffee must not make the next coffee free too.
                      l.discountType.isNull(),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) {
        await _setQty(existing, existing.qty + 1);
        return;
      }

      final line = OrderLinesCompanion.insert(
        id: newId(),
        orderId: orderId,
        productId: p.id,
        name: p.name,
        unitPrice: p.price,
        modifiersPrice: Value(modifiers.fold(0, (sum, m) => sum + m.extraPrice)),
        modifiersJson: Value(modifiersJson),
        qty: 1,
        vatRateBp: p.vatRateBp,
        station: Value(p.station),
        createdAt: _now(),
      );
      await _db.into(_db.orderLines).insert(line);
      await _outbox.record(
        staffId: _staffId(),
        type: EventTypes.orderItemAdded,
        entityId: orderId,
        payload: {
          'lineId': line.id.value,
          'productId': p.id,
          'name': p.name,
          'unitPrice': p.price,
          'qty': 1,
          'vatRateBp': p.vatRateBp,
          'station': p.station,
          'modifiers': [for (final m in modifiers) m.toJson()],
        },
      );
    });
  }

  @override
  Future<void> setQty(String lineId, int qty) => _db.transaction(() async {
    final line = await _changeableLine(lineId);
    if (qty <= 0) {
      await _void(line, line.sentAt == null ? 'removed_before_send' : 'removed_after_send');
    } else if ((line.sentAt != null || line.discountType != null) && qty > line.qty) {
      // Already sent to the bar/kitchen, or discounted: the extra goes on a NEW line at full
      // price, so "Envoyer" sends it and the discount doesn't silently grow.
      await _addLineLike(line, qty - line.qty);
    } else {
      await _setQty(line, qty);
    }
  });

  /// A new (not sent) line with the same product, options and prices as [like].
  Future<void> _addLineLike(OrderLineRow like, int qty) async {
    final id = newId();
    await _db
        .into(_db.orderLines)
        .insert(
          OrderLinesCompanion.insert(
            id: id,
            orderId: like.orderId,
            productId: like.productId,
            name: like.name,
            unitPrice: like.unitPrice,
            modifiersPrice: Value(like.modifiersPrice),
            modifiersJson: Value(like.modifiersJson),
            qty: qty,
            vatRateBp: like.vatRateBp,
            station: Value(like.station),
            createdAt: _now(),
          ),
        );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderItemAdded,
      entityId: like.orderId,
      payload: {
        'lineId': id,
        'productId': like.productId,
        'name': like.name,
        'unitPrice': like.unitPrice,
        'qty': qty,
        'vatRateBp': like.vatRateBp,
        'station': like.station,
        'modifiers': jsonDecode(like.modifiersJson),
      },
    );
  }

  @override
  Future<void> removeLine(String lineId) =>
      _db.transaction(() async => _void(await _changeableLine(lineId), 'removed_before_send'));

  /// Cancels a whole open order (only before anything was paid).
  @override
  Future<void> cancelOrder(String orderId) => _db.transaction(() async {
    final order = await _openOrder(orderId);
    if (!(await _paid(orderId)).isZero) {
      throw const OrderException('Une partie est déjà payée : ce ticket ne peut plus être annulé.');
    }
    await (_db.update(_db.orders)..where(
      (o) => o.id.equals(order.id),
    )).write(OrdersCompanion(status: const Value('cancelled'), closedAt: Value(_now())));
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderCancelled,
      entityId: order.id,
      payload: {'reason': 'cancelled_by_staff'},
    );
  });

  /// Moves a ticket to another table ([to] null = the counter). The destination must be free.
  @override
  Future<void> moveOrder(String orderId, DiningTableRow? to) => _db.transaction(() async {
    final order = await _openOrder(orderId);
    if (order.tableId == to?.id) return;
    if (await _openOrderQuery(to?.id).getSingleOrNull() != null) {
      throw OrderException(to == null ? 'Le comptoir a déjà un ticket en cours.' : 'La table ${to.name} est occupée.');
    }
    await (_db.update(_db.orders)..where((o) => o.id.equals(orderId))).write(
      OrdersCompanion(
        tableId: Value(to?.id),
        tableLabel: Value(to?.name),
        type: Value(to == null ? 'takeaway' : 'table'),
      ),
    );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderTableChanged,
      entityId: orderId,
      payload: {'tableId': to?.id, 'tableName': to?.name},
    );
  });

  // ── Discounts ─────────────────────────────────────────────

  /// Applies a discount. Every discount has a reason and a manager: the one who
  /// typed their PIN ([DiscountRequest.approvedBy]), or the person logged in if
  /// they are a manager. Paid lines are not touched.
  @override
  Future<void> discount(String orderId, DiscountRequest r) => _db.transaction(() async {
    await _openOrder(orderId);
    if (!DiscountReasons.labels.containsKey(r.reason)) throw const OrderException('Choisissez le motif de la remise.');
    final approver = await _manager(r.approvedBy);
    if (r.type == DiscountType.percent && (r.value < 1 || r.value > 10000)) {
      throw const OrderException('Pourcentage invalide (entre 0,01 et 100 %).');
    }
    if (r.type == DiscountType.amount && r.value < 1) throw const OrderException('Montant de remise invalide.');
    if (r.type != DiscountType.free && r.type != DiscountType.percent && r.type != DiscountType.amount) {
      throw const OrderException('Type de remise invalide.');
    }

    var lines =
        await (_db.select(_db.orderLines)
          ..where((l) => l.orderId.equals(orderId) & l.voided.equals(false) & l.paymentId.isNull())).get();
    if (r.lineIds.isNotEmpty) {
      lines = lines.where((l) => r.lineIds.contains(l.id)).toList();
      if (lines.length != r.lineIds.toSet().length) {
        throw const OrderException('Article introuvable, retiré ou déjà payé.');
      }
    }
    if (lines.isEmpty) throw const OrderException('Aucun article à remiser.');

    // An amount on several lines is split in proportion to their price.
    final values =
        r.type == DiscountType.amount && lines.length > 1
            ? splitAmount(r.value, {for (final l in lines) l.id: lineGross(amountsOf(l)).millimes})
            : {for (final l in lines) l.id: r.value};

    final before = OrderTotals.of(lines.map(amountsOf)).total;
    final after = OrderTotals.of([for (final l in lines) _withDiscount(l, r.type, values[l.id]!)]).total;
    await _checkStillCoversPaid(orderId, after - before);

    for (final l in lines) {
      await (_db.update(_db.orderLines)..where((x) => x.id.equals(l.id))).write(
        OrderLinesCompanion(
          discountType: Value(r.type),
          discountValue: Value(values[l.id]!),
          discountReason: Value(r.reason),
          discountApprovedBy: Value(approver),
        ),
      );
    }
    await _outbox.record(
      staffId: _staffId(),
      approvedBy: approver,
      type: EventTypes.orderItemDiscounted,
      entityId: orderId,
      payload: {
        'reason': r.reason,
        'lines': [
          for (final l in lines) {'lineId': l.id, 'type': r.type, 'value': values[l.id]},
        ],
      },
    );
  });

  @override
  Future<void> removeDiscount(String orderId, List<String> lineIds) => _db.transaction(() async {
    await _openOrder(orderId);
    final lines =
        await (_db.select(_db.orderLines)
          ..where((l) => l.orderId.equals(orderId) & l.id.isIn(lineIds) & l.discountType.isNotNull())).get();
    if (lines.isEmpty) return;
    if (lines.any((l) => l.paymentId != null)) throw const OrderException('Cet article est déjà payé.');
    await (_db.update(_db.orderLines)..where((l) => l.id.isIn([for (final l in lines) l.id]))).write(
      const OrderLinesCompanion(
        discountType: Value(null),
        discountValue: Value(0),
        discountReason: Value(null),
        discountApprovedBy: Value(null),
      ),
    );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderItemDiscounted,
      entityId: orderId,
      payload: {
        'reason': null,
        'lines': [
          for (final l in lines) {'lineId': l.id, 'type': null, 'value': 0},
        ],
      },
    );
  });

  LineAmounts _withDiscount(OrderLineRow l, String type, int value) => (
    unitPrice: l.unitPrice,
    modifiersPrice: l.modifiersPrice,
    qty: l.qty,
    vatRateBp: l.vatRateBp,
    voided: l.voided,
    discountType: type,
    discountValue: value,
  );

  /// The manager approving a sensitive action: [approvedBy] (must be a manager),
  /// or the person logged in if they are a manager.
  Future<String> _manager(String? approvedBy) async {
    Future<StaffRow?> staff(String? id) async =>
        id == null ? null : (_db.select(_db.staffMembers)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (approvedBy != null) {
      if ((await staff(approvedBy))?.role != 'manager') throw const OrderException('Seul un gérant peut valider.');
      return approvedBy;
    }
    final me = await staff(_staffId());
    if (me?.role == 'manager') return me!.id;
    throw const OrderException('Validation d’un gérant requise.');
  }

  /// "Demander l'addition": marks the ticket so the cashier sees it on the Hub.
  @override
  Future<void> requestBill(String orderId) => _db.transaction(() async {
    final order = await _openOrder(orderId);
    if (order.billRequestedAt != null) return;
    await (_db.update(_db.orders)
      ..where((o) => o.id.equals(orderId))).write(OrdersCompanion(billRequestedAt: Value(_now())));
    await _outbox.record(staffId: _staffId(), type: EventTypes.orderBillRequested, entityId: orderId, payload: {});
  });

  /// Pays all or part of a ticket. When nothing is left to pay, the ticket gets
  /// its receipt number and closes — all in one transaction.
  @override
  Future<PaymentResult> pay(
    String orderId,
    PaymentRequest req, {
    required String deviceCode,
    required String drawerId,
  }) {
    return _db.transaction(() async {
      final order = await _openOrder(orderId);
      final drawerOpen =
          await (_db.select(_db.cashSessions)
                ..where((t) => t.drawerId.equals(drawerId) & t.status.equals('open'))
                ..limit(1))
              .getSingleOrNull();
      if (drawerOpen == null) {
        throw const OrderException('Caisse fermée : ouvrez la caisse (fond de caisse) avant d’encaisser.');
      }
      final lines =
          await (_db.select(_db.orderLines)..where((l) => l.orderId.equals(order.id) & l.voided.equals(false))).get();
      final totals = OrderTotals.of(lines.map(amountsOf));
      if (totals.isEmpty) throw const OrderException('La commande est vide.');
      final remaining = totals.total - await _paid(order.id);

      var amount = req.amount;
      if (req.lineIds.isNotEmpty) {
        final chosen = lines.where((l) => req.lineIds.contains(l.id)).toList();
        if (chosen.length != req.lineIds.toSet().length || chosen.any((l) => l.paymentId != null)) {
          throw const OrderException('Un article choisi est déjà payé ou a été retiré.');
        }
        amount = chosen.fold(Money.zero, (sum, l) => sum + lineTotal(amountsOf(l)));
      }
      if (amount <= Money.zero || amount > remaining) {
        throw OrderException('Montant invalide : il reste $remaining à payer.');
      }
      final tendered = req.method == 'card' ? amount : req.tendered;
      if (tendered < amount) throw OrderException('Montant insuffisant : il manque ${amount - tendered}.');
      final change = tendered - amount;

      final now = _now();
      final paymentId = newId();
      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: paymentId,
              orderId: order.id,
              method: req.method,
              amount: amount.millimes,
              tendered: tendered.millimes,
              changeGiven: change.millimes,
              createdAt: now,
              drawerId: Value(drawerId),
            ),
          );
      if (req.lineIds.isNotEmpty) {
        await (_db.update(_db.orderLines)
          ..where((l) => l.id.isIn(req.lineIds))).write(OrderLinesCompanion(paymentId: Value(paymentId)));
      }
      await _outbox.record(
        staffId: _staffId(),
        type: EventTypes.paymentAdded,
        entityId: order.id,
        payload: {
          'paymentId': paymentId,
          'method': req.method,
          'amount': amount.millimes,
          'tendered': tendered.millimes,
          'change': change.millimes,
          'drawerId': drawerId,
          if (req.lineIds.isNotEmpty) 'lineIds': req.lineIds,
        },
      );

      final left = remaining - amount;
      if (!left.isZero) {
        return PaymentResult(receiptNumber: null, amount: amount, change: change, remaining: left, total: totals.total);
      }

      // Fully paid → receipt number + close.
      final seq = (int.tryParse(await _db.getKv(_receiptSeqKey) ?? '') ?? 0) + 1;
      await _db.setKv(_receiptSeqKey, '$seq');
      final number = '$deviceCode-${seq.toString().padLeft(6, '0')}';
      await (_db.update(_db.orders)..where((o) => o.id.equals(order.id))).write(
        OrdersCompanion(
          status: const Value('paid'),
          closedAt: Value(now),
          total: Value(totals.total.millimes),
          receiptNumber: Value(number),
        ),
      );
      await _outbox.record(
        staffId: _staffId(),
        type: EventTypes.orderClosed,
        entityId: order.id,
        payload: {
          'receiptNumber': number,
          'total': totals.total.millimes,
          'itemCount': totals.itemCount,
          'vat': [
            for (final v in totals.vat)
              {'rateBp': v.rateBp, 'ttc': v.ttc.millimes, 'ht': v.ht.millimes, 'vat': v.vat.millimes},
          ],
        },
      );
      return PaymentResult(
        receiptNumber: number,
        amount: amount,
        change: change,
        remaining: Money.zero,
        total: totals.total,
      );
    });
  }

  // ── Helpers ──────────────────────────────────────────────

  SimpleSelectStatement<$OrdersTable, OrderRow> _openOrderQuery(String? tableId) =>
      _db.select(_db.orders)
        ..where((o) => o.status.equals('open') & (tableId == null ? o.tableId.isNull() : o.tableId.equals(tableId)))
        ..orderBy([(o) => OrderingTerm.desc(o.openedAt)])
        ..limit(1);

  Selectable<QueryRow> _paidQuery(String orderId) => _db.customSelect(
    'SELECT COALESCE(SUM(amount), 0) AS paid FROM payments WHERE order_id = ?',
    variables: [Variable.withString(orderId)],
    readsFrom: {_db.payments},
  );

  Future<Money> _paid(String orderId) async => Money((await _paidQuery(orderId).getSingle()).read<int>('paid'));

  Future<OrderRow> _openOrder(String orderId) async {
    final o =
        await (_db.select(_db.orders)..where((o) => o.id.equals(orderId) & o.status.equals('open'))).getSingleOrNull();
    if (o == null) throw const OrderException('Ce ticket est déjà fermé.');
    return o;
  }

  /// The open order of the table (or counter), or a new one (records order.opened).
  Future<String> _openOrderId(DiningTableRow? table) async {
    final open = await _openOrderQuery(table?.id).getSingleOrNull();
    if (open != null) return open.id;
    final id = newId();
    await _db
        .into(_db.orders)
        .insert(
          OrdersCompanion.insert(
            id: id,
            openedAt: _now(),
            type: Value(table == null ? 'takeaway' : 'table'),
            tableId: Value(table?.id),
            tableLabel: Value(table?.name),
          ),
        );
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderOpened,
      entityId: id,
      payload: {
        'type': table == null ? 'takeaway' : 'table',
        if (table != null) ...{'tableId': table.id, 'tableName': table.name},
      },
    );
    return id;
  }

  /// A line that can still be changed: not paid on its own, and the ticket
  /// total must stay at least what was already paid.
  Future<OrderLineRow> _changeableLine(String id) async {
    final line = await (_db.select(_db.orderLines)..where((l) => l.id.equals(id))).getSingle();
    if (line.paymentId != null) throw const OrderException('Cet article est déjà payé.');
    return line;
  }

  Future<void> _checkStillCoversPaid(String orderId, Money delta) async {
    final paid = await _paid(orderId);
    if (paid.isZero) return;
    final lines =
        await (_db.select(_db.orderLines)..where((l) => l.orderId.equals(orderId) & l.voided.equals(false))).get();
    final total = OrderTotals.of(lines.map(amountsOf)).total;
    if (total + delta < paid) {
      throw OrderException('Impossible : $paid déjà payé sur ce ticket.');
    }
  }

  Future<void> _setQty(OrderLineRow line, int qty) async {
    final unit = Money(line.unitPrice + line.modifiersPrice);
    if (qty < line.qty) await _checkStillCoversPaid(line.orderId, unit * (qty - line.qty));
    await (_db.update(_db.orderLines)..where((l) => l.id.equals(line.id))).write(OrderLinesCompanion(qty: Value(qty)));
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderItemUpdated,
      entityId: line.orderId,
      payload: {'lineId': line.id, 'qty': qty},
    );
  }

  Future<void> _void(OrderLineRow line, String reason) async {
    await _checkStillCoversPaid(line.orderId, -lineTotal(amountsOf(line)));
    await (_db.update(_db.orderLines)
      ..where((l) => l.id.equals(line.id))).write(const OrderLinesCompanion(voided: Value(true)));
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderItemVoided,
      entityId: line.orderId,
      payload: {'lineId': line.id, 'reason': reason},
    );
  }
}
