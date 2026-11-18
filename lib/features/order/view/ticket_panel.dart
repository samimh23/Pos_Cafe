import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../floor/view_model/floor_view_model.dart';
import '../data/order_repository.dart';
import '../view_model/order_view_model.dart';
import 'move_ticket_dialog.dart';
import 'payment_dialog.dart';

/// Right side of the POS: the current ticket (a table or the counter), totals and the pay button.
class TicketPanel extends ConsumerWidget {
  const TicketPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(ticketProvider);
    final target = ref.watch(activeTargetProvider);
    final hasTables = ref.watch(hasTablesProvider);
    final busy = ref.watch(orderViewModelProvider);
    final vm = ref.read(orderViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;
    final partlyPaid = !ticket.paid.isZero;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  switch (target) {
                    TableTarget(:final table) => 'Table ${table.name}',
                    _ => 'Comptoir',
                  },
                  key: const Key('ticket-title'),
                  style: text.titleLarge,
                ),
              ),
              if (hasTables && ticket.order != null)
                IconButton(
                  key: const Key('move-ticket'),
                  tooltip: 'Changer de table',
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () => _move(context, vm),
                ),
              if (!ticket.isEmpty && !partlyPaid)
                TextButton.icon(
                  key: const Key('cancel-order'),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Annuler'),
                  onPressed: () => _confirmCancel(context, vm),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child:
              ticket.isEmpty
                  ? const Center(child: Text('Touchez un produit pour commencer'))
                  : ListView.separated(
                    itemCount: ticket.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final l = ticket.lines[i];
                      final paid = l.paymentId != null;
                      final mods = parseChosenModifiers(l.modifiersJson).map((m) => m.name).join(', ');
                      return ListTile(
                        key: Key('line-${l.productId}${paid ? '-paid' : ''}'),
                        title: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [
                            if (mods.isNotEmpty) mods,
                            '${Money(l.unitPrice + l.modifiersPrice).toDecimalString()} × ${l.qty}',
                          ].join('\n'),
                        ),
                        isThreeLine: mods.isNotEmpty,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (paid)
                              const Chip(label: Text('Payé'), visualDensity: VisualDensity.compact)
                            else ...[
                              IconButton(
                                tooltip: 'Moins',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _guard(context, () => vm.decrement(l)),
                              ),
                              Text('${l.qty}', style: text.titleMedium),
                              IconButton(
                                tooltip: 'Plus',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _guard(context, () => vm.increment(l)),
                              ),
                            ],
                            SizedBox(
                              width: 72,
                              child: Text(
                                lineTotal(amountsOf(l)).toDecimalString(),
                                textAlign: TextAlign.right,
                                style: text.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final v in ticket.totals.vat)
                Row(
                  children: [
                    Expanded(
                      child: Text('TVA ${v.label} (HT ${v.ht.toDecimalString()})', overflow: TextOverflow.ellipsis),
                    ),
                    Text(v.vat.toDecimalString()),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('TOTAL', style: text.headlineSmall)),
                  Text(ticket.totals.total.toString(), key: const Key('ticket-total'), style: text.headlineSmall),
                ],
              ),
              if (partlyPaid) ...[
                Row(
                  children: [
                    const Expanded(child: Text('Déjà payé')),
                    Text(ticket.paid.toString(), key: const Key('ticket-paid')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('RESTE', style: text.titleLarge)),
                    Text(ticket.remaining.toString(), key: const Key('ticket-remaining'), style: text.titleLarge),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  key: const Key('pay-cash'),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(ticket.isEmpty ? 'Encaisser' : 'Encaisser ${ticket.remaining}'),
                  onPressed: ticket.isEmpty || busy ? null : () => _pay(context, vm, ticket),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows refusals (e.g. "Cet article est déjà payé.") instead of failing silently.
  Future<void> _guard(BuildContext context, Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pay(BuildContext context, OrderViewModel vm, TicketState ticket) async {
    final request = await showPaymentDialog(context, remaining: ticket.remaining, unpaidLines: ticket.unpaidLines);
    if (request == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await vm.pay(request);
      final how = request.method == 'card' ? 'par carte' : 'Rendu ${r.change}';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r.closed ? 'Payé ✅  Ticket ${r.receiptNumber} · $how' : 'Reçu ${r.amount} · $how · Reste ${r.remaining}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _move(BuildContext context, OrderViewModel vm) async {
    final choice = await showMoveTicketDialog(context);
    if (choice == null || !context.mounted) return;
    await _guard(context, () => vm.moveTo(choice.table));
  }

  Future<void> _confirmCancel(BuildContext context, OrderViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Annuler la commande ?'),
            content: const Text('Tous les articles du ticket seront retirés.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Non')),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Oui, annuler')),
            ],
          ),
    );
    if (ok == true && context.mounted) await _guard(context, vm.cancelOrder);
  }
}
