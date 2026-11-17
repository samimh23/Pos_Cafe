import 'money.dart';

/// TTC → HT + VAT for one rate. Café prices are TTC (VAT included).
class VatSplit {
  /// Basis points: 1900 = 19 %.
  final int rateBp;
  final Money ttc;
  final Money ht;
  Money get vat => ttc - ht;

  const VatSplit._(this.rateBp, this.ttc, this.ht);

  /// ht = round(ttc × 10000 / (10000 + rate)) — same formula as the backend.
  factory VatSplit.fromTtc(int rateBp, Money ttc) =>
      VatSplit._(rateBp, ttc, Money(roundDiv(ttc.millimes * 10000, 10000 + rateBp)));

  String get label => '${rateBp ~/ 100}%';
}

/// Receipt VAT breakdown: one entry per rate, computed on the summed TTC of
/// that rate (not per line) to limit rounding drift. Highest rate first.
List<VatSplit> vatBreakdown(Iterable<({int rateBp, Money ttc})> lines) {
  final totals = <int, Money>{};
  for (final l in lines) {
    totals[l.rateBp] = (totals[l.rateBp] ?? Money.zero) + l.ttc;
  }
  final rates = totals.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final r in rates) VatSplit.fromTtc(r, totals[r]!)];
}
