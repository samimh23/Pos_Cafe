import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/money/vat.dart';

/// Same vectors as the backend tests — if one side changes rounding, both must change.
void main() {
  group('format', () {
    for (final (m, text) in [(4500, '4.500'), (0, '0.000'), (-1250, '-1.250'), (5, '0.005'), (1234567, '1234.567')]) {
      test('$m → $text', () => expect(Money(m).toDecimalString(), text));
    }
  });

  group('parse', () {
    for (final (text, m) in [
      ('4.5', 4500),
      ('4,500', 4500),
      ('12', 12000),
      ('0.005', 5),
      ('-1.25', -1250),
      ('4.5 DT', 4500),
    ]) {
      test('"$text" → $m', () => expect(Money.parse(text).millimes, m));
    }
    for (final bad in ['', 'abc', '1.2345', '1.2.3']) {
      test('invalid "$bad"', () => expect(() => Money.parse(bad), throwsFormatException));
    }
  });

  group('percent', () {
    for (final (m, bp, r) in [(4500, 1000, 450), (3333, 1500, 500), (1005, 500, 50)]) {
      test('$m × ${bp}bp = $r', () => expect(Money(m).percentBp(bp).millimes, r));
    }
  });

  group('VAT split', () {
    for (final (ttc, bp, ht, vat) in [
      (4500, 1900, 3782, 718),
      (2400, 1900, 2017, 383),
      (3500, 700, 3271, 229),
      (10000, 1300, 8850, 1150),
      (1190, 1900, 1000, 190),
      (0, 1900, 0, 0),
      (1000, 0, 1000, 0),
      (-4500, 1900, -3782, -718),
    ]) {
      test('$ttc @ ${bp}bp', () {
        final s = VatSplit.fromTtc(bp, Money(ttc));
        expect(s.ht.millimes, ht);
        expect(s.vat.millimes, vat);
      });
    }
  });

  test('VAT breakdown per rate on summed TTC', () {
    final b = vatBreakdown([
      (rateBp: 1900, ttc: const Money(4500)),
      (rateBp: 1900, ttc: const Money(2400)),
      (rateBp: 700, ttc: const Money(3500)),
    ]);
    expect(
      [for (final s in b) (s.rateBp, s.ttc.millimes, s.ht.millimes, s.vat.millimes)],
      [(1900, 6900, 5798, 1102), (700, 3500, 3271, 229)],
    );
  });
}
