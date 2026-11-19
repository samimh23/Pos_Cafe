import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/lan/lan_providers.dart';
import '../../../core/money/money.dart';
import '../../../core/print/printers.dart';
import '../../../core/providers.dart';
import '../../order/data/order_repository.dart' show OrderException;
import '../../print/print_providers.dart';
import '../data/cash_repository.dart';
import '../view_model/cash_view_model.dart';
import 'cash_dialogs.dart';

/// App bar chip: "Caisse ouverte" / "Caisse fermée" → the Caisse screen.
/// Only on POS that take payments (they have a cash drawer).
class CashChip extends ConsumerWidget {
  const CashChip({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canTakePaymentsProvider)) return const SizedBox.shrink();
    final open = ref.watch(openCashSessionProvider).value != null;
    final label = open ? 'Caisse ouverte' : 'Caisse fermée';
    return ActionChip(
      key: const Key('cash-chip'),
      tooltip: label,
      avatar: Icon(Icons.point_of_sale, size: 18, color: open ? Colors.green : Colors.grey),
      label: Text(compact ? (open ? 'Ouverte' : 'Fermée') : label),
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CashScreen())),
    );
  }
}

/// Runs a cash action and shows a refusal as a message instead of failing silently.
Future<bool> runCash(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } on OrderException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

/// Opens the drawer (asks for the float). Used by the Caisse screen and before a first payment.
Future<bool> openDrawer(BuildContext context, WidgetRef ref) async {
  final float = await showOpenDrawerDialog(context);
  if (float == null || !context.mounted) return false;
  final ok = await runCash(context, () => ref.read(cashActionsProvider).open(float));
  ref.invalidate(cashSummaryProvider);
  return ok;
}

/// "Caisse": open the drawer, cash in / out, where it stands, close it.
class CashScreen extends ConsumerWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(openCashSessionProvider).value;
    final summary = ref.watch(cashSummaryProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cashSummaryProvider),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (session == null) ...[
                const Icon(Icons.point_of_sale, size: 56),
                const SizedBox(height: 12),
                Text('Caisse fermée', style: text.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Ouvrez la caisse avec le fond de caisse avant le premier encaissement.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Center(
                  child: FilledButton.icon(
                    key: const Key('cash-open'),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Ouvrir la caisse'),
                    onPressed: () => openDrawer(context, ref),
                  ),
                ),
              ] else
                switch (summary) {
                  AsyncData(value: final s?) => _OpenDrawer(summary: s),
                  AsyncError(:final error) => Text(
                    error is OrderException ? error.message : 'Erreur : $error',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenDrawer extends ConsumerWidget {
  const _OpenDrawer({required this.summary});
  final CashSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final text = Theme.of(context).textTheme;
    String time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    Widget row(String label, Money m, {Key? key, TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(m.toString(), key: key, style: style)]),
    );

    Future<void> move(bool cashIn) async {
      final r = await showMovementDialog(context, cashIn: cashIn);
      if (r == null || !context.mounted) return;
      await runCash(context, () => ref.read(cashActionsProvider).move(cashIn: cashIn, amount: r.$1, reason: r.$2));
      ref.invalidate(cashSummaryProvider);
    }

    Future<void> close() async {
      final r = await showCloseDrawerDialog(context, expected: s.expectedCash);
      if (r == null || !context.mounted) return;
      CashClosing? closing;
      final ok = await runCash(context, () async {
        closing = await ref.read(cashActionsProvider).close(counted: r.$1, note: r.$2);
      });
      if (!ok || closing == null || !context.mounted) return;
      ref.invalidate(cashSummaryProvider);
      // The report prints on this POS's receipt printer (the main POS, or a POS alone).
      final canPrint =
          ref.read(posModeProvider) != PosMode.tablet && (ref.read(printerSettingsProvider).value?.receipt != null);
      final drawer = ref.read(deviceIdentityProvider).value?.deviceCode ?? '';
      final messenger = ScaffoldMessenger.of(context);
      await showClosingReport(
        context,
        closing!,
        onPrint:
            canPrint
                ? () async {
                  try {
                    await ref.read(printServiceProvider).printCashReport(closing!, drawer: drawer);
                    messenger.showSnackBar(const SnackBar(content: Text('Clôture imprimée ✓')));
                  } on PrintException catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
                : null,
      );
      if (context.mounted) Navigator.of(context).maybePop();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Caisse ouverte', style: text.headlineSmall),
        Text('Depuis ${time(s.openedAt)}${s.openedBy == null ? '' : ' · ${s.openedBy}'}'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                row('Fond de caisse', s.openingFloat),
                row('Ventes espèces', s.cashSales, key: const Key('sum-cash-sales')),
                row('Entrées d’argent', s.cashIn),
                row('Sorties d’argent', -s.cashOut),
                const Divider(),
                row('Espèces attendues', s.expectedCash, key: const Key('sum-expected'), style: text.titleLarge),
                const SizedBox(height: 8),
                row('Ventes carte (TPE)', s.cardSales, key: const Key('sum-card-sales')),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${s.ticketCount} ticket${s.ticketCount > 1 ? 's' : ''} encaissé${s.ticketCount > 1 ? 's' : ''}',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              key: const Key('cash-in'),
              icon: const Icon(Icons.add),
              label: const Text('Entrée d’argent'),
              onPressed: () => move(true),
            ),
            OutlinedButton.icon(
              key: const Key('cash-out'),
              icon: const Icon(Icons.remove),
              label: const Text('Sortie d’argent'),
              onPressed: () => move(false),
            ),
            FilledButton.icon(
              key: const Key('cash-close'),
              icon: const Icon(Icons.lock),
              label: const Text('Clôturer la caisse'),
              onPressed: close,
            ),
          ],
        ),
        if (s.openTickets > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${s.openTickets} ticket${s.openTickets > 1 ? 's' : ''} encore ouvert${s.openTickets > 1 ? 's' : ''} dans le café.',
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ],
        if (s.movements.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Mouvements', style: text.titleMedium),
          for (final m in s.movements)
            ListTile(
              dense: true,
              leading: Icon(m.cashIn ? Icons.south_west : Icons.north_east),
              title: Text(m.reason),
              subtitle: Text('${time(m.at)}${m.staffName == null ? '' : ' · ${m.staffName}'}'),
              trailing: Text('${m.cashIn ? '+' : '−'}${m.amount}'),
            ),
        ],
      ],
    );
  }
}
