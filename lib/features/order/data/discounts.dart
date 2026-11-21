import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';

/// Why a discount was given — always required, shown to the owner.
abstract final class DiscountReasons {
  static const labels = {
    'geste': 'Geste commercial',
    'staff': 'Personnel',
    'error': 'Erreur',
    'complaint': 'Réclamation client',
    'other': 'Autre',
  };

  /// A reward paid with loyalty points: no manager needed (the backend checked the code).
  static const loyalty = 'loyalty';
  static String label(String? code) => code == loyalty ? 'Fidélité' : labels[code] ?? (code ?? '');
}

/// What the cashier asks for: free / % / amount, on some lines or the whole ticket.
class DiscountRequest {
  /// [DiscountType.free], [DiscountType.percent] (basis points) or [DiscountType.amount] (millimes).
  final String type;
  final int value;
  final String reason;

  /// Lines to discount; empty = every line not paid yet (whole ticket).
  final List<String> lineIds;

  /// Manager who typed their PIN (null when the person logged in is a manager).
  final String? approvedBy;

  const DiscountRequest({
    required this.type,
    this.value = 0,
    required this.reason,
    this.lineIds = const [],
    this.approvedBy,
  });

  const DiscountRequest.free({required this.reason, this.lineIds = const [], this.approvedBy})
    : type = DiscountType.free,
      value = 0;

  DiscountRequest approved(String? by) =>
      DiscountRequest(type: type, value: value, reason: reason, lineIds: lineIds, approvedBy: by);

  Map<String, Object?> toJson() => {
    'type': type,
    'value': value,
    'reason': reason,
    'lineIds': lineIds,
    'approvedBy': approvedBy,
  };

  factory DiscountRequest.fromJson(Map<String, dynamic> j) => DiscountRequest(
    type: j['type'] as String,
    value: (j['value'] as int?) ?? 0,
    reason: j['reason'] as String,
    lineIds: ((j['lineIds'] as List?) ?? const []).cast<String>(),
    approvedBy: j['approvedBy'] as String?,
  );
}

/// "Offert", "−10 %", "−1.000 DT" — how a discount is shown and printed.
String discountLabel(String? type, int value) => switch (type) {
  DiscountType.free => 'Offert',
  DiscountType.percent => '−${value % 100 == 0 ? value ~/ 100 : (value / 100).toStringAsFixed(1)} %',
  DiscountType.amount => '−${Money(value)}',
  _ => '',
};

/// Splits an amount over lines in proportion to their price (the last cents go to
/// the biggest line), never more than a line is worth.
Map<String, int> splitAmount(int amount, Map<String, int> grossById) {
  final int total = grossById.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return {for (final id in grossById.keys) id: 0};
  final int capped = amount > total ? total : amount;
  final Map<String, int> shares = {for (final e in grossById.entries) e.key: capped * e.value ~/ total};
  var left = capped - shares.values.fold<int>(0, (a, b) => a + b);
  final biggestFirst = grossById.keys.toList()..sort((a, b) => grossById[b]!.compareTo(grossById[a]!));
  for (final id in biggestFirst) {
    if (left == 0) break;
    final int room = grossById[id]! - shares[id]!;
    final int add = left < room ? left : room;
    shares[id] = shares[id]! + add;
    left -= add;
  }
  return shares;
}

/// Why something already sent to the bar/kitchen is cancelled (or a paid ticket refunded).
abstract final class CancelReasons {
  static const labels = {
    'changed_mind': 'Le client a changé d’avis',
    'error': 'Erreur de saisie',
    'quality': 'Problème de qualité',
    'other': 'Autre',
  };
  static String label(String? code) => labels[code] ?? (code ?? '');
}

/// A manager's OK for a sensitive action, with its reason.
class Approval {
  /// Manager who typed their PIN; null when the person logged in is a manager.
  final String? approvedBy;
  final String reason;
  const Approval({this.approvedBy, required this.reason});

  Map<String, Object?> toJson() => {'approvedBy': approvedBy, 'reason': reason};
  static Approval? fromJson(Object? j) {
    if (j is! Map) return null;
    return Approval(approvedBy: j['approvedBy'] as String?, reason: j['reason'] as String);
  }
}
