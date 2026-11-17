import 'money.dart';
import 'vat.dart';

/// What the totals need from a line (pure data, no database).
typedef LineAmounts = ({int unitPrice, int modifiersPrice, int qty, int vatRateBp, bool voided});

/// Price of one line TTC = (product price + modifiers) × quantity.
Money lineTotal(LineAmounts l) => l.voided ? Money.zero : Money(l.unitPrice + l.modifiersPrice) * l.qty;

/// Totals of an order, ready for the ticket and the receipt.
class OrderTotals {
  final Money total;
  final int itemCount;
  final List<VatSplit> vat;

  const OrderTotals._(this.total, this.itemCount, this.vat);

  static const empty = OrderTotals._(Money.zero, 0, []);

  factory OrderTotals.of(Iterable<LineAmounts> lines) {
    var total = Money.zero;
    var count = 0;
    final vatLines = <({int rateBp, Money ttc})>[];
    for (final l in lines.where((l) => !l.voided)) {
      final t = lineTotal(l);
      total += t;
      count += l.qty;
      if (!t.isZero) vatLines.add((rateBp: l.vatRateBp, ttc: t));
    }
    return OrderTotals._(total, count, vatBreakdown(vatLines));
  }

  bool get isEmpty => itemCount == 0;
}
