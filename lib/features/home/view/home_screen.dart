import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/device/device_repository.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../core/lan/hub_widgets.dart';
import '../../cash/view/cash_screen.dart';
import '../../print/view/printers_screen.dart';
import '../../../core/lan/lan_providers.dart';
import '../../floor/view_model/floor_view_model.dart';
import '../../order/view/modifiers_dialog.dart';
import '../../order/view/ticket_panel.dart';
import '../../order/view_model/order_view_model.dart';
import '../../staff_login/view_model/staff_session.dart';
import '../view_model/home_view_model.dart';

Color _hex(String? hex) =>
    hex == null || hex.length != 7 ? Colors.blueGrey : Color(int.parse('FF${hex.substring(1)}', radix: 16));

/// POS ordering screen: menu from the local DB + the ticket of a table or the counter.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.identity});
  final DeviceIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncControllerProvider); // keeps the background sync running
    final hasTables = ref.watch(hasTablesProvider);

    return Scaffold(
      appBar: AppBar(
        leading:
            hasTables
                ? IconButton(
                  key: const Key('back-to-floor'),
                  tooltip: 'Tables',
                  icon: const Icon(Icons.table_restaurant_outlined),
                  onPressed: () => ref.read(ticketTargetProvider.notifier).backToFloor(),
                )
                : null,
        title: PosTitle(name: identity.name, code: identity.deviceCode),
        actions: const [PosAppBarActions()],
      ),
      body: const Column(
        children: [
          HubLinkBanner(),
          Expanded(
            child: Row(
              children: [
                SizedBox(width: 190, child: _CategoryList()),
                VerticalDivider(width: 1),
                Expanded(child: _ProductGrid()),
                VerticalDivider(width: 1),
                SizedBox(width: 400, child: TicketPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Below this screen width the app bar chips get short labels.
const compactBarWidth = 1500.0;

/// Staff name, sync status, developer menu — same on the tables and order screens.
class PosAppBarActions extends ConsumerWidget {
  const PosAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(homeViewModelProvider.notifier);
    // Tablets and small PCs: short chips (full text in the tooltip) so the bar never overflows.
    final compact = MediaQuery.sizeOf(context).width < compactBarWidth;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _StaffChip(),
        const SizedBox(width: 8),
        CashChip(compact: compact),
        const SizedBox(width: 8),
        HubStatusChip(compact: compact),
        const SizedBox(width: 8),
        _SyncStatusChip(compact: compact),
        PopupMenuButton<String>(
          key: const Key('pos-menu'),
          tooltip: 'Menu',
          onSelected:
              (v) => switch (v) {
                'printers' => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const PrintersScreen())),
                'event' => vm.recordTestEvent(),
                'forget' => vm.forgetDevice(),
                _ => null,
              },
          itemBuilder:
              (_) => [
                // Tablets print on the main POS's printers: nothing to set there.
                if (ref.read(posModeProvider) != PosMode.tablet)
                  const PopupMenuItem(value: 'printers', child: Text('Imprimantes')),
                if (kDebugMode) ...const [
                  PopupMenuItem(value: 'event', child: Text('Créer un événement test')),
                  PopupMenuItem(value: 'forget', child: Text('Dissocier cette caisse')),
                ],
              ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Who is logged in + "switch user" (back to the PIN screen).
class _StaffChip extends ConsumerWidget {
  const _StaffChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffSessionProvider);
    if (staff == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'Changer d’utilisateur',
      child: ActionChip(
        key: const Key('staff-chip'),
        avatar: const Icon(Icons.person_outline, size: 18),
        label: Text(staff.name),
        onPressed: () => ref.read(staffSessionProvider.notifier).logout(),
      ),
    );
  }
}

class _SyncStatusChip extends ConsumerWidget {
  const _SyncStatusChip({this.compact = false});
  final bool compact;

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

    final full = pending > 0 ? '$label · $pending en attente' : label;
    return Tooltip(
      message: compact ? '$full — appuyer pour synchroniser' : 'Appuyer pour synchroniser maintenant',
      child: ActionChip(
        key: const Key('sync-chip'),
        avatar: Icon(icon, color: color, size: 18),
        label: Text(
          compact ? (pending > 0 ? '$pending' : (status.connection == Connection.online ? 'OK' : '!')) : full,
        ),
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
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('product-${p.id}'),
            onTap: () => _addProduct(context, ref, p),
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
          ),
        );
      },
    );
  }

  /// Products with options (size, extras…) open the modifiers dialog first.
  Future<void> _addProduct(BuildContext context, WidgetRef ref, ProductRow p) async {
    final vm = ref.read(orderViewModelProvider.notifier);
    final groups = parseModifierGroups(p.modifierGroupsJson);
    if (groups.isEmpty) return vm.addProduct(p);

    final chosen = await showModifiersDialog(context, p.name, groups);
    if (chosen != null) await vm.addProduct(p, chosen);
  }
}
