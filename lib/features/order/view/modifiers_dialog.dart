import 'package:flutter/material.dart';

import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';

/// Lets the cashier pick options (size, extras…). Returns the chosen options, or null if cancelled.
Future<List<ModifierOption>?> showModifiersDialog(
  BuildContext context,
  String productName,
  List<ModifierGroup> groups,
) => showDialog<List<ModifierOption>>(
  context: context,
  builder: (_) => _ModifiersDialog(productName: productName, groups: groups),
);

class _ModifiersDialog extends StatefulWidget {
  const _ModifiersDialog({required this.productName, required this.groups});
  final String productName;
  final List<ModifierGroup> groups;

  @override
  State<_ModifiersDialog> createState() => _ModifiersDialogState();
}

class _ModifiersDialogState extends State<_ModifiersDialog> {
  final _selected = <String, Set<String>>{}; // groupId → option ids

  @override
  void initState() {
    super.initState();
    for (final g in widget.groups) {
      // Required single choice: pre-select the first option (usually "Normal").
      _selected[g.id] = {if (g.required && g.single && g.options.isNotEmpty) g.options.first.id};
    }
  }

  void _toggle(ModifierGroup g, ModifierOption o) => setState(() {
    final s = _selected[g.id]!;
    if (g.single) {
      s
        ..clear()
        ..add(o.id);
    } else if (!s.remove(o.id) && s.length < g.maxSelect) {
      s.add(o.id);
    }
  });

  String? get _error {
    for (final g in widget.groups) {
      final e = g.validate(_selected[g.id]!);
      if (e != null) return e;
    }
    return null;
  }

  List<ModifierOption> get _chosen => [
    for (final g in widget.groups)
      for (final o in g.options)
        if (_selected[g.id]!.contains(o.id)) o,
  ];

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return AlertDialog(
      title: Text(widget.productName),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final g in widget.groups) ...[
                Text(g.required ? g.name : '${g.name} (optionnel)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in g.options)
                      FilterChip(
                        key: Key('modifier-${o.id}'),
                        label: Text(o.extraPrice > 0 ? '${o.name} +${Money(o.extraPrice).toDecimalString()}' : o.name),
                        selected: _selected[g.id]!.contains(o.id),
                        onSelected: (_) => _toggle(g, o),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (error != null) Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('modifiers-confirm'),
          onPressed: error == null ? () => Navigator.pop(context, _chosen) : null,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
