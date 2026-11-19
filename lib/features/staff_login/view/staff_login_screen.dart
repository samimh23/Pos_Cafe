import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/device/device_repository.dart';
import '../../../core/lan/hub_widgets.dart';
import '../../../core/sync/sync_controller.dart';
import '../view_model/pin_login_view_model.dart';
import '../view_model/staff_session.dart';

const _roleLabel = {'manager': 'Gérant', 'cashier': 'Caissier', 'server': 'Serveur', 'kitchen': 'Cuisine'};

/// "Qui êtes-vous ?" — staff tiles, then the PIN pad. Works offline.
class StaffLoginScreen extends ConsumerWidget {
  const StaffLoginScreen({super.key, required this.identity});
  final DeviceIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(pinLoginViewModelProvider.select((s) => s.selected));
    final staff = ref.watch(staffListProvider).value;

    return Scaffold(
      appBar: AppBar(title: PosTitle(name: identity.name, code: identity.deviceCode)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch ((staff, selected)) {
              (null, _) => const CircularProgressIndicator(),
              (final List<StaffRow> list, null) when list.isEmpty => const _NoStaff(),
              (final List<StaffRow> list, null) => _StaffPicker(staff: list),
              (_, final StaffRow s) => _PinPad(staff: s),
            },
          ),
        ),
      ),
    );
  }
}

class _NoStaff extends ConsumerWidget {
  const _NoStaff();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(syncControllerProvider).syncing;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.group_add_outlined, size: 56),
        const SizedBox(height: 16),
        Text('Aucun membre du personnel', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez votre personnel dans Kahwti → Personnel (sur le web), puis synchronisez cette caisse.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('sync-staff'),
          onPressed: syncing ? null : () => ref.read(syncControllerProvider.notifier).syncNow(),
          icon: const Icon(Icons.sync),
          label: Text(syncing ? 'Synchronisation…' : 'Synchroniser'),
        ),
      ],
    );
  }
}

class _StaffPicker extends ConsumerWidget {
  const _StaffPicker({required this.staff});
  final List<StaffRow> staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Qui êtes-vous ?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final s in staff)
              SizedBox(
                width: 150,
                height: 110,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('staff-${s.id}'),
                    onTap: () => ref.read(pinLoginViewModelProvider.notifier).select(s),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(child: Text(s.name.characters.first.toUpperCase())),
                        const SizedBox(height: 8),
                        Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_roleLabel[s.role] ?? s.role, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PinPad extends ConsumerWidget {
  const _PinPad({required this.staff});
  final StaffRow staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pinLoginViewModelProvider);
    final vm = ref.read(pinLoginViewModelProvider.notifier);
    final locked = state.lockedUntil != null && state.lockedUntil!.isAfter(DateTime.now());
    final text = Theme.of(context).textTheme;

    Widget key(String label, VoidCallback? onTap, {Key? k, IconData? icon}) => SizedBox(
      width: 84,
      height: 64,
      child: OutlinedButton(
        key: k,
        onPressed: locked || state.checking ? null : onTap,
        child: icon != null ? Icon(icon) : Text(label, style: text.headlineSmall),
      ),
    );

    // Physical keyboard (Windows PC): digits, Backspace, Enter, Escape.
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final c = e.character;
        if (c != null && RegExp(r'^\d$').hasMatch(c)) {
          vm.digit(c);
        } else if (e.logicalKey == LogicalKeyboardKey.backspace) {
          vm.erase();
        } else if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
          vm.submit();
        } else if (e.logicalKey == LogicalKeyboardKey.escape) {
          vm.back();
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(staff.name, style: text.headlineSmall),
          const SizedBox(height: 4),
          const Text('Entrez votre code'),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < PinLoginViewModel.maxLength; i++)
                Container(
                  margin: const EdgeInsets.all(6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < state.pin.length ? Theme.of(context).colorScheme.primary : null,
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 28,
            child:
                state.error != null
                    ? Text(
                      state.error!,
                      key: const Key('pin-error'),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    )
                    : null,
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final d in row)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: key(d, () => vm.digit(d), k: Key('pin-$d')),
                    ),
                ],
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: key('', vm.erase, icon: Icons.backspace_outlined, k: const Key('pin-erase')),
              ),
              Padding(padding: const EdgeInsets.all(4), child: key('0', () => vm.digit('0'), k: const Key('pin-0'))),
              Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 84,
                  height: 64,
                  child: FilledButton(
                    key: const Key('pin-ok'),
                    onPressed: locked || state.checking ? null : vm.submit,
                    child:
                        state.checking
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('OK'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: vm.back, child: const Text('← Changer de personne')),
        ],
      ),
    );
  }
}
