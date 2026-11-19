import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/money/order_totals.dart';
import 'package:pos_cafe/features/order/data/discounts.dart';

void main() {
  /// Same vectors as Backend_Platform test/discounts.test.ts — POS and cloud must agree.
  const vectors = <(int, String?, int, int)>[
    (2400, 'free', 0, 2400),
    (3500, 'percent', 1000, 350),
    (1250, 'percent', 1500, 188), // 187.5 → 188
    (1000, 'percent', 3333, 333),
    (1000, 'percent', 20000, 1000),
    (1200, 'amount', 500, 500),
    (1200, 'amount', 5000, 1200),
    (1200, 'amount', -50, 0),
    (1200, null, 900, 0),
  ];

  for (final (gross, type, value, discount) in vectors) {
    test('discountOf($gross, $type, $value) = $discount', () {
      expect(discountOf(Money(gross), type, value), Money(discount));
    });
  }

  test('an amount off the whole ticket is split by price, nothing lost or above a line', () {
    expect(splitAmount(1000, {'a': 3000, 'b': 1000}), {'a': 750, 'b': 250});
    final odd = splitAmount(1000, {'a': 1, 'b': 1, 'c': 1000});
    expect(odd.values.fold<int>(0, (s, v) => s + v), 1000);
    expect(odd['a']! <= 1 && odd['b']! <= 1, isTrue);
    expect(splitAmount(9000, {'a': 2000, 'b': 1000}), {'a': 2000, 'b': 1000}); // capped at the ticket
  });

  test('labels: Offert, −10 %, −12.5 %, −1.000 DT; reasons in French', () {
    expect(discountLabel('free', 0), 'Offert');
    expect(discountLabel('percent', 1000), '−10 %');
    expect(discountLabel('percent', 1250), '−12.5 %');
    expect(discountLabel('amount', 1000), '−1.000 DT');
    expect(DiscountReasons.label('geste'), 'Geste commercial');
  });
}
