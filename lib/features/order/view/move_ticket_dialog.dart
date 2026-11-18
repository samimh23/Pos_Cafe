import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../floor/view_model/floor_view_model.dart';

/// Where the move goes. `table == null` = the counter.
typedef MoveChoice = ({DiningTableRow? table});

/// "Changer de table": the free tables (and the counter if it's free).
Future<MoveChoice?> showMoveTicketDialog(BuildContext context) =>
    showDialog<MoveChoice>(context: context, builder: (_) => const _MoveTicketDialog());

class _MoveTicketDialog extends ConsumerWidget {
  const _MoveTicketDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(areasProvider).value ?? const [];
    final tables = ref.watch(tablesProvider).value ?? const [];
    final tickets = ref.watch(openTicketsProvider).value ?? const [];
    final current = ref.watch(activeTargetProvider);
    final busy = {for (final t in tickets) t.tableId};
    final free = tables.where((t) => !busy.contains(t.id)).toList();
    final areaName = {for (final a in areas) a.id: a.name};

    return AlertDialog(
      title: const Text('Changer de table'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (free.isEmpty) const Text('Aucune table libre.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in free)
                  ActionChip(
                    key: Key('move-to-${t.id}'),
                    avatar: const Icon(Icons.table_restaurant_outlined, size: 18),
                    label: Text(areaName[t.areaId] == null ? t.name : '${t.name} · ${areaName[t.areaId]}'),
                    onPressed: () => Navigator.pop(context, (table: t)),
                  ),
              ],
            ),
            if (current is TableTarget && !busy.contains(null)) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('move-to-counter'),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Au comptoir / à emporter'),
                onPressed: () => Navigator.pop(context, (table: null)),
              ),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler'))],
    );
  }
}
