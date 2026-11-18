import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/device/device_repository.dart';
import '../../../core/lan/hub_widgets.dart';
import '../../../core/lan/lan_providers.dart';
import '../../home/view/home_screen.dart' show PosAppBarActions;
import '../../order/data/order_repository.dart';
import '../view_model/floor_view_model.dart';

/// "Salle": every table, free or busy (amount left, how long it's been open). Works offline.
class FloorScreen extends ConsumerWidget {
  const FloorScreen({super.key, required this.identity});
  final DeviceIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(areasProvider).value;
    final tables = ref.watch(tablesProvider).value;
    final tickets = ref.watch(openTicketsProvider).value ?? const [];

    if (areas == null || tables == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final byTable = {
      for (final t in tickets)
        if (t.tableId != null) t.tableId!: t,
    };
    final counter = tickets.where((t) => t.tableId == null).firstOrNull;
    // Tables whose room was deleted still show up, under "Autres".
    final known = {for (final a in areas) a.id};
    final orphans = tables.where((t) => !known.contains(t.areaId)).toList();
    final sections =
        [
          for (final a in areas) (a.name, tables.where((t) => t.areaId == a.id).toList()),
          if (orphans.isNotEmpty) ('Autres', orphans),
        ].where((s) => s.$2.isNotEmpty).toList();

    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${identity.name} · ${identity.deviceCode}'),
          actions: const [PosAppBarActions()],
          bottom:
              sections.length > 1
                  ? TabBar(
                    isScrollable: true,
                    tabs: [
                      for (final (name, list) in sections)
                        Tab(text: '$name (${list.where((t) => byTable.containsKey(t.id)).length}/${list.length})'),
                    ],
                  )
                  : null,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HubLinkBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${byTable.length} table${byTable.length > 1 ? 's' : ''} occupée${byTable.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // The counter ticket lives on the Hub (or a POS working alone), not on server tablets.
                  if (ref.watch(posModeProvider) != PosMode.tablet)
                    FilledButton.tonalIcon(
                      key: const Key('counter-tile'),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: Text(counter == null ? 'Comptoir / À emporter' : 'Comptoir · ${counter.remaining}'),
                      onPressed: () => ref.read(ticketTargetProvider.notifier).open(const CounterTarget()),
                    ),
                ],
              ),
            ),
            Expanded(
              child:
                  sections.isEmpty
                      ? const Center(child: Text('Aucune table.'))
                      : TabBarView(
                        children: [
                          for (final (_, list) in sections)
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [for (final t in list) _TableTile(table: t, ticket: byTable[t.id])],
                              ),
                            ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableTile extends ConsumerWidget {
  const _TableTile({required this.table, required this.ticket});
  final DiningTableRow table;
  final OpenTicket? ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final busy = ticket != null;
    final minutes = busy ? DateTime.now().difference(ticket!.openedAt).inMinutes : 0;

    return SizedBox(
      width: 140,
      height: 120,
      child: Card(
        color: busy ? scheme.primaryContainer : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: busy ? scheme.primary : scheme.outlineVariant, width: busy ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('table-${table.id}'),
          onTap: () => ref.read(ticketTargetProvider.notifier).open(TableTarget(table)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            // Long names or large system fonts shrink instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    table.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (busy) ...[
                    Text(ticket!.remaining.toString(), style: text.titleSmall),
                    if (ticket!.billRequested)
                      Container(
                        key: Key('bill-requested-${table.id}'),
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: scheme.tertiary, borderRadius: BorderRadius.circular(8)),
                        child: Text('Addition', style: text.labelSmall?.copyWith(color: scheme.onTertiary)),
                      )
                    else
                      Text(minutes < 1 ? 'à l’instant' : '$minutes min', style: text.bodySmall),
                  ] else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_seat_outlined, size: 16, color: scheme.outline),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${table.seats} · libre',
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: scheme.outline),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
