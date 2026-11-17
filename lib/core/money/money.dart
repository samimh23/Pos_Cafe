/// Money in Tunisian dinars, stored as integer **millimes** (1 DT = 1000).
///
/// Never use `double` for money. Rounding is half away from zero, the same
/// rule as the backend.
class Money implements Comparable<Money> {
  final int millimes;

  const Money(this.millimes);

  static const zero = Money(0);

  /// `Money.dt(4, 500)` = 4.500 DT.
  const Money.dt(int dinars, [int millimes = 0]) : millimes = dinars * 1000 + millimes;

  static final _pattern = RegExp(r'^(-?)(\d+)(?:\.(\d{1,3}))?$');

  /// Parses "4.5", "4.500", "4,500", "12", "4.5 DT". Throws [FormatException].
  factory Money.parse(String input) {
    final s = input.replaceAll(RegExp(r'\s*(DT|TND)\s*$', caseSensitive: false), '').trim().replaceAll(',', '.');
    final m = _pattern.firstMatch(s);
    if (m == null) throw FormatException('Invalid amount', input);
    final value = int.parse(m.group(2)!) * 1000 + int.parse((m.group(3) ?? '').padRight(3, '0'));
    return Money(m.group(1) == '-' ? -value : value);
  }

  static Money? tryParse(String input) {
    try {
      return Money.parse(input);
    } on FormatException {
      return null;
    }
  }

  Money operator +(Money other) => Money(millimes + other.millimes);
  Money operator -(Money other) => Money(millimes - other.millimes);
  Money operator -() => Money(-millimes);
  Money operator *(int quantity) => Money(millimes * quantity);

  /// Percentage in basis points (1500 = 15 %).
  Money percentBp(int basisPoints) => Money(roundDiv(millimes * basisPoints, 10000));

  bool get isNegative => millimes < 0;
  bool get isZero => millimes == 0;

  bool operator <(Money o) => millimes < o.millimes;
  bool operator >(Money o) => millimes > o.millimes;
  bool operator <=(Money o) => millimes <= o.millimes;
  bool operator >=(Money o) => millimes >= o.millimes;

  @override
  int compareTo(Money other) => millimes.compareTo(other.millimes);

  @override
  bool operator ==(Object other) => other is Money && other.millimes == millimes;

  @override
  int get hashCode => millimes.hashCode;

  /// "4.500"
  String toDecimalString() {
    final abs = millimes.abs();
    final s = '${abs ~/ 1000}.${(abs % 1000).toString().padLeft(3, '0')}';
    return millimes < 0 ? '-$s' : s;
  }

  /// "4.500 DT"
  @override
  String toString() => '${toDecimalString()} DT';
}

/// Integer division rounded half away from zero.
int roundDiv(int numerator, int denominator) {
  if (denominator == 0) throw ArgumentError('Division by zero');
  final negative = (numerator < 0) != (denominator < 0);
  final n = numerator.abs(), d = denominator.abs();
  final q = (n * 2 + d) ~/ (d * 2);
  return negative ? -q : q;
}
