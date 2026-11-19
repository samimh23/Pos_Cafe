import 'money.dart';
import 'vat.dart';

/// What the totals need from a line (pure data, no database).
typedef LineAmounts =
    ({int unitPrice, int modifiersPrice, int qty, int vatRateBp, bool voided, String? discountType, int discountValue});

/// free | percent (basis points: 1000 = 10 %) | amount (millimes, for the whole line).
abstract final class DiscountType {
  static const free = 'free', percent = 'percent', amount = 'amount';
}

/// Discount of a line from its gross total. Same formula and test vectors as the
/// backend (shared/money.ts discountOf): never more than the line.
Money discountOf(Money gross, String? type, int value) => switch (type) {
  DiscountType.free => gross,
  DiscountType.percent => Money(_min(gross.millimes, roundDiv(gross.millimes * value.clamp(0, 10000), 10000))),
  DiscountType.amount => Money(_min(gross.millimes, value < 0 ? 0 : value)),
  _ => Money.zero,
};

int _min(int a, int b) => a < b ? a : b;

/// Price × quantity, before any discount.
Money lineGross(LineAmounts l) => l.voided ? Money.zero : Money(l.unitPrice + l.modifiersPrice) * l.qty;

Money lineDiscount(LineAmounts l) => discountOf(lineGross(l), l.discountType, l.discountValue);

/// What the customer pays for the line: gross − discount.
Money lineTotal(LineAmounts l) => lineGross(l) - lineDiscount(l);

/// Totals of an order, ready for the ticket and the receipt.
class OrderTotals {
  final Money total;

  /// Sum of the discounts ("Remises & offerts").
  final Money discount;
  final int itemCount;
  final List<VatSplit> vat;

  const OrderTotals._(this.total, this.discount, this.itemCount, this.vat);

  static const empty = OrderTotals._(Money.zero, Money.zero, 0, []);

  factory OrderTotals.of(Iterable<LineAmounts> lines) {
    var total = Money.zero;
    var discount = Money.zero;
    var count = 0;
    final vatLines = <({int rateBp, Money ttc})>[];
    for (final l in lines.where((l) => !l.voided)) {
      final t = lineTotal(l);
      total += t;
      discount += lineDiscount(l);
      count += l.qty;
      if (!t.isZero) vatLines.add((rateBp: l.vatRateBp, ttc: t));
    }
    return OrderTotals._(total, discount, count, vatBreakdown(vatLines));
  }

  bool get isEmpty => itemCount == 0;
}
