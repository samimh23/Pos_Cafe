import 'dart:convert';

/// A modifier option, e.g. "Extra shot +0.500".
class ModifierOption {
  final String id;
  final String name;

  /// Extra price per unit, in millimes.
  final int extraPrice;

  const ModifierOption({required this.id, required this.name, this.extraPrice = 0});

  factory ModifierOption.fromJson(Map<String, dynamic> j) =>
      ModifierOption(id: j['id'], name: j['name'], extraPrice: (j['extraPrice'] as num?)?.toInt() ?? 0);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'extraPrice': extraPrice};
}

/// A group of options, e.g. "Taille" (choose exactly 1) or "Extras" (0 to 3).
class ModifierGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.options = const [],
  });

  bool get required => minSelect > 0;
  bool get single => maxSelect == 1;

  factory ModifierGroup.fromJson(Map<String, dynamic> j) => ModifierGroup(
    id: j['id'],
    name: j['name'],
    minSelect: (j['minSelect'] as num?)?.toInt() ?? 0,
    maxSelect: (j['maxSelect'] as num?)?.toInt() ?? 1,
    options: [for (final o in (j['modifiers'] as List? ?? const [])) ModifierOption.fromJson(o)],
  );

  /// Error message in French, or null when [selectedIds] is a valid choice for this group.
  String? validate(Set<String> selectedIds) {
    final n = options.where((o) => selectedIds.contains(o.id)).length;
    if (n < minSelect) {
      return minSelect == 1 ? '$name : choisissez une option' : '$name : choisissez au moins $minSelect';
    }
    if (n > maxSelect) return '$name : $maxSelect maximum';
    return null;
  }
}

List<ModifierGroup> parseModifierGroups(String json) {
  final list = jsonDecode(json);
  if (list is! List) return const [];
  return [for (final g in list) ModifierGroup.fromJson((g as Map).cast<String, dynamic>())];
}

List<ModifierOption> parseChosenModifiers(String json) => [
  for (final m in (jsonDecode(json) as List)) ModifierOption.fromJson((m as Map).cast<String, dynamic>()),
];
