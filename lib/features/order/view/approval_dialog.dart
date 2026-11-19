import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/staff/staff_repository.dart';
import '../../staff_login/view_model/staff_session.dart';
import '../data/discounts.dart';

/// Cancelling something sent / refunding: the reason, then a manager's PIN
/// (or the manager logged in). Null if cancelled.
Future<Approval?> askCancelApproval(BuildContext context, WidgetRef ref, {required String what}) async {
  final reason = await showDialog<String>(
    context: context,
    builder:
        (c) => SimpleDialog(
          title: Text(what),
          children: [
            for (final e in CancelReasons.labels.entries)
              SimpleDialogOption(
                key: Key('cancel-reason-${e.key}'),
                onPressed: () => Navigator.pop(c, e.key),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(e.value)),
              ),
          ],
        ),
  );
  if (reason == null || !context.mounted) return null;
  final approver = await askManagerApproval(context, ref, what: '$what — ${CancelReasons.label(reason)}');
  return approver == null ? null : Approval(approvedBy: approver, reason: reason);
}

/// Asks a manager to approve a sensitive action ([what]: "Offert : 2 x Express").
/// Returns the manager's staff id, or null if cancelled. A manager logged in
/// approves by themselves — no PIN asked.
Future<String?> askManagerApproval(BuildContext context, WidgetRef ref, {required String what}) async {
  final me = ref.read(staffSessionProvider);
  if (me?.role == 'manager') return me!.id;
  final managers = (ref.read(staffListProvider).value ?? const <StaffRow>[]).where((s) => s.role == 'manager').toList();
  if (managers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun gérant sur cette caisse : ajoutez-en un dans Kahwti → Personnel.')),
    );
    return null;
  }
  return showDialog<String>(context: context, builder: (_) => _ApprovalDialog(what: what, managers: managers));
}

class _ApprovalDialog extends ConsumerStatefulWidget {
  const _ApprovalDialog({required this.what, required this.managers});
  final String what;
  final List<StaffRow> managers;

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  late StaffRow? _manager = widget.managers.length == 1 ? widget.managers.single : null;
  var _pin = '';
  String? _error;
  var _checking = false;

  Future<void> _ok() async {
    final m = _manager;
    if (m == null || _pin.length < 4 || _checking) return;
    setState(() => _checking = true);
    final r = await ref.read(staffRepositoryProvider).approve(m, _pin);
    if (!mounted) return;
    switch (r) {
      case PinOk(:final staff):
        Navigator.pop(context, staff.id);
      case PinWrong(:final remaining):
        setState(() {
          _pin = '';
          _checking = false;
          _error = 'Code incorrect. Encore $remaining essai${remaining > 1 ? 's' : ''}.';
        });
      case PinLocked():
        setState(() {
          _pin = '';
          _checking = false;
          _error = 'Trop d’essais. Réessayez dans 1 minute.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget key(String d) => Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        width: 64,
        height: 52,
        child: OutlinedButton(
          key: Key('approve-pin-$d'),
          onPressed:
              _checking
                  ? null
                  : () => setState(() {
                    _error = null;
                    if (d == '⌫') {
                      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
                    } else if (_pin.length < 6) {
                      _pin += d;
                    }
                  }),
          child: Text(d, style: text.titleLarge),
        ),
      ),
    );

    return AlertDialog(
      title: const Text('Validation d’un gérant'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.what, textAlign: TextAlign.center, style: text.titleMedium),
            const SizedBox(height: 12),
            if (_manager == null) ...[
              const Text('Quel gérant valide ?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in widget.managers)
                    ActionChip(
                      key: Key('approve-staff-${m.id}'),
                      avatar: const Icon(Icons.verified_user_outlined, size: 18),
                      label: Text(m.name),
                      onPressed: () => setState(() => _manager = m),
                    ),
                ],
              ),
            ] else ...[
              Text('Code de ${_manager!.name}'),
              const SizedBox(height: 8),
              Text('•' * _pin.length, style: text.headlineSmall, key: const Key('approve-dots')),
              SizedBox(
                height: 24,
                child:
                    _error == null
                        ? null
                        : Text(
                          _error!,
                          key: const Key('approve-error'),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
              ),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['⌫', '0'],
              ])
                Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) key(d)]),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        if (_manager != null)
          FilledButton(
            key: const Key('approve-ok'),
            onPressed: _pin.length >= 4 && !_checking ? _ok : null,
            child: const Text('Valider'),
          ),
      ],
    );
  }
}
