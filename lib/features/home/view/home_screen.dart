import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/device/device_repository.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/sync_controller.dart';
import '../view_model/home_view_model.dart';

Color _hex(String? hex) =>
    hex == null || hex.length != 7 ? Colors.blueGrey : Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// POS home: menu from the local DB + sync status. Ordering comes next.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.identity});
  final DeviceIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncControllerProvider); // keeps the background sync running
    final vm = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('${identity.name} · ${identity.deviceCode}${identity.isHub ? ' (Hub)' : ''}'),
        actions: [
          const _SyncStatusChip(),
          if (kDebugMode)
            PopupMenuButton<String>(
              tooltip: 'Développement',
              onSelected: (v) => switch (v) {
                'event' => vm.recordTestEvent(),
                'forget' => vm.forgetDevice(),
                _ => null,
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'event', child: Text('Créer un événement test')),
                PopupMenuItem(value: 'forget', child: Text('Dissocier cette caisse')),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Row(
        children: [
          SizedBox(width: 200, child: _CategoryList()),
          VerticalDivider(width: 1),
          Expanded(child: _ProductGrid()),
        ],
      ),
    );
  }
}

class _SyncStatusChip extends ConsumerWidget {
  const _SyncStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingEventsProvider).value ?? 0;

    final (icon, color, label) = switch (status) {
      SyncStatus(syncing: true) => (Icons.sync, Colors.blue, 'Synchronisation…'),
      SyncStatus(lastError: final String err) => (Icons.error_outline, Colors.red, err),
      SyncStatus(connection: Connection.offline) => (Icons.cloud_off, Colors.orange, 'Hors ligne'),
      SyncStatus(connection: Connection.online) => (Icons.cloud_done, Colors.green, 'En ligne'),
      _ => (Icons.cloud_queue, Colors.grey, '…'),
    };

    return Tooltip(
      message: 'Appuyer pour synchroniser maintenant',
      child: ActionChip(
        key: const Key('sync-chip'),
        avatar: Icon(icon, color: color, size: 18),
        label: Text(pending > 0 ? '$label · $pending en attente' : label),
        onPressed: () => ref.read(homeViewModelProvider.notifier).syncNow(),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final selected = ref.watch(homeViewModelProvider);

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Menu vide. Il sera téléchargé à la prochaine synchronisation.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              height: 64,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.id == selected ? _hex(c.color) : _hex(c.color).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ref.read(homeViewModelProvider.notifier).selectCategory(c.id),
                child: Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = ref.watch(homeViewModelProvider);
    if (categoryId == null) return const SizedBox.shrink();
    final products = ref.watch(productsProvider(categoryId)).value ?? const [];
    final text = Theme.of(context).textTheme;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(child: Text(p.name, style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                Text(Money(p.price).toString(), style: text.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
