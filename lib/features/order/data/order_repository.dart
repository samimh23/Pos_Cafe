import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ids.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../../core/sync/outbox_repository.dart';
import '../../../core/sync/sync_event_types.dart';

class PaymentResult {
  final String receiptNumber;
  final Money total;
  final Money change;
  const PaymentResult(this.receiptNumber, this.total, this.change);
}

class OrderException implements Exception {
  final String message;
  const OrderException(this.message);
  @override
  String toString() => message;
}

LineAmounts amountsOf(OrderLineRow l) => (
  unitPrice: l.unitPrice,
  modifiersPrice: l.modifiersPrice,
  qty: l.qty,
  vatRateBp: l.vatRateBp,
  voided: l.voided,
);

/// Model layer for orders. Every method changes the local data AND records the
/// matching sync event in ONE transaction — both are saved, or neither.
class OrderRepository {
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

  Stream<OrderRow?> watchOpenOrder() =>
      (_db.select(_db.orders)
            ..where((o) => o.status.equals('open'))
            ..orderBy([(o) => OrderingTerm.desc(o.openedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Stream<List<OrderLineRow>> watchLines(String orderId) =>
      (_db.select(_db.orderLines)
            ..where((l) => l.orderId.equals(orderId) & l.voided.equals(false))
            ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
          .watch();

  // ── Actions ──────────────────────────────────────────────

  /// Adds a product. Same product with the same modifiers → quantity + 1.
  Future<void> addProduct(ProductRow p, {List<ModifierOption> modifiers = const []}) {
    return _db.transaction(() async {
      final orderId = await _openOrderId();
      final modifiersJson = jsonEncode([for (final m in modifiers) m.toJson()]);

      final existing =
          await (_db.select(_db.orderLines)
                ..where(
                  (l) =>
                      l.orderId.equals(orderId) &
                      l.productId.equals(p.id) &
                      l.modifiersJson.equals(modifiersJson) &
                      l.voided.equals(false),
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

  Future<void> setQty(String lineId, int qty) => _db.transaction(() async {
    final line = await _line(lineId);
    if (qty <= 0) {
      await _void(line, 'removed_before_send');
    } else {
      await _setQty(line, qty);
    }
  });

  Future<void> removeLine(String lineId) =>
      _db.transaction(() async => _void(await _line(lineId), 'removed_before_send'));

  /// Cancels the whole open order (before payment).
  Future<void> cancelOpenOrder() => _db.transaction(() async {
    final order = await _currentOpenOrder();
    if (order == null) return;
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

  /// Cash payment of the open order: payment + receipt number + close, all at once.
  Future<PaymentResult> payCash({required Money tendered, required String deviceCode}) {
    return _db.transaction(() async {
      final order = await _currentOpenOrder();
      if (order == null) throw const OrderException('Aucune commande en cours.');

      final lines =
          await (_db.select(_db.orderLines)..where((l) => l.orderId.equals(order.id) & l.voided.equals(false))).get();
      final totals = OrderTotals.of(lines.map(amountsOf));
      if (totals.isEmpty) throw const OrderException('La commande est vide.');
      if (tendered < totals.total) throw OrderException('Montant insuffisant : il manque ${totals.total - tendered}.');

      final change = tendered - totals.total;
      final seq = (int.tryParse(await _db.getKv(_receiptSeqKey) ?? '') ?? 0) + 1;
      await _db.setKv(_receiptSeqKey, '$seq');
      final number = '$deviceCode-${seq.toString().padLeft(6, '0')}';
      final now = _now();
      final paymentId = newId();

      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: paymentId,
              orderId: order.id,
              method: 'cash',
              amount: totals.total.millimes,
              tendered: tendered.millimes,
              changeGiven: change.millimes,
              createdAt: now,
            ),
          );
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
        type: EventTypes.paymentAdded,
        entityId: order.id,
        payload: {
          'paymentId': paymentId,
          'method': 'cash',
          'amount': totals.total.millimes,
          'tendered': tendered.millimes,
          'change': change.millimes,
        },
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

      return PaymentResult(number, totals.total, change);
    });
  }

  // ── Helpers ──────────────────────────────────────────────

  Future<OrderRow?> _currentOpenOrder() =>
      (_db.select(_db.orders)
            ..where((o) => o.status.equals('open'))
            ..orderBy([(o) => OrderingTerm.desc(o.openedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// The open order, or a new one (records order.opened).
  Future<String> _openOrderId() async {
    final open = await _currentOpenOrder();
    if (open != null) return open.id;
    final id = newId();
    await _db.into(_db.orders).insert(OrdersCompanion.insert(id: id, openedAt: _now()));
    await _outbox.record(staffId: _staffId(), type: EventTypes.orderOpened, entityId: id, payload: {'type': 'takeaway'});
    return id;
  }

  Future<OrderLineRow> _line(String id) => (_db.select(_db.orderLines)..where((l) => l.id.equals(id))).getSingle();

  Future<void> _setQty(OrderLineRow line, int qty) async {
    await (_db.update(_db.orderLines)..where((l) => l.id.equals(line.id))).write(OrderLinesCompanion(qty: Value(qty)));
    await _outbox.record(
      staffId: _staffId(),
      type: EventTypes.orderItemUpdated,
      entityId: line.orderId,
      payload: {'lineId': line.id, 'qty': qty},
    );
  }

  Future<void> _void(OrderLineRow line, String reason) async {
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
