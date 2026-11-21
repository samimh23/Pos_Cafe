import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../../core/print/printers.dart';
import '../../../core/providers.dart';
import '../../print/print_providers.dart';
import '../../print/view/loyalty_qr_dialog.dart';
import '../data/discounts.dart';
import '../data/order_repository.dart';
import '../view_model/order_view_model.dart';
import 'approval_dialog.dart';

/// Today's paid and refunded tickets on this POS (since midnight).
final todayTicketsProvider = StreamProvider.autoDispose<List<OrderRow>>((ref) {
  final now = DateTime.now();
  return ref.watch(orderRepositoryProvider).watchClosedTickets(DateTime(now.year, now.month, now.day));
});

/// ⋮ → Tickets du jour: find a ticket, reprint it, or refund it.
class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(todayTicketsProvider).value;
    String time(DateTime? d) =>
        d == null ? '' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets du jour')),
      body:
          tickets == null
              ? const Center(child: CircularProgressIndicator())
              : tickets.isEmpty
              ? const Center(child: Text('Aucun ticket encaissé aujourd’hui.'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final o = tickets[i];
                  final refunded = o.status == 'refunded';
                  return ListTile(
                    key: Key('ticket-${o.receiptNumber}'),
                    leading: Icon(refunded ? Icons.undo : Icons.receipt_long),
                    title: Text(o.receiptNumber ?? '—'),
                    subtitle: Text(
                      '${time(o.closedAt)} · ${o.tableLabel == null ? 'Comptoir' : 'Table ${o.tableLabel}'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (refunded)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Chip(label: Text('Remboursé'), visualDensity: VisualDensity.compact),
                          ),
                        Text(
                          Money(o.total).toString(),
                          style: TextStyle(decoration: refunded ? TextDecoration.lineThrough : null),
                        ),
                      ],
                    ),
                    onTap: () => _open(context, ref, o),
                  );
                },
              ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, OrderRow o) async {
    final db = ref.read(databaseProvider);
    final lines = await (db.select(db.orderLines)..where((l) => l.orderId.equals(o.id) & l.voided.equals(false))).get();
    final payments = await (db.select(db.payments)..where((p) => p.orderId.equals(o.id))).get();
    final loyaltyUrl = await ref.read(printServiceProvider).loyaltyUrl(o.id);
    if (!context.mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text('Ticket ${o.receiptNumber}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in lines)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l.qty} × ${l.name}'
                            '${parseChosenModifiers(l.modifiersJson).isEmpty ? '' : ' (${parseChosenModifiers(l.modifiersJson).map((m) => m.name).join(', ')})'}'
                            '${l.discountType == null ? '' : ' · ${discountLabel(l.discountType, l.discountValue)}'}',
                          ),
                        ),
                        Text(lineTotal(amountsOf(l)).toDecimalString()),
                      ],
                    ),
                  const Divider(),
                  for (final p in payments)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.amount < 0
                                ? 'Remboursé (${p.method == 'card' ? 'carte' : 'espèces'})'
                                : (p.method == 'card' ? 'Carte' : 'Espèces'),
                          ),
                        ),
                        Text(Money(p.amount).toDecimalString()),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              if (loyaltyUrl != null)
                TextButton.icon(
                  key: const Key('ticket-loyalty-qr'),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('QR fidélité'),
                  onPressed: () => Navigator.pop(c, 'loyalty'),
                ),
              TextButton(
                key: const Key('ticket-reprint'),
                onPressed: () => Navigator.pop(c, o.status == 'refunded' ? 'print-refund' : 'reprint'),
                child: Text(o.status == 'refunded' ? 'Imprimer le remboursement' : 'Réimprimer'),
              ),
              if (o.status == 'paid')
                FilledButton.tonalIcon(
                  key: const Key('ticket-refund'),
                  icon: const Icon(Icons.undo),
                  label: const Text('Rembourser'),
                  onPressed: () => Navigator.pop(c, 'refund'),
                ),
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer')),
            ],
          ),
    );
    if (action == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final printer = ref.read(printServiceProvider);
    Future<void> tryPrint(Future<void> Function() p, String done) async {
      try {
        await p();
        messenger.showSnackBar(SnackBar(content: Text(done)));
      } on PrintException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }

    switch (action) {
      case 'loyalty':
        await showLoyaltyQr(context, url: loyaltyUrl!, receiptNumber: o.receiptNumber ?? '');
      case 'reprint':
        await tryPrint(() => printer.printReceipt(o.id), 'Ticket réimprimé ✓');
      case 'print-refund':
        await tryPrint(() => printer.printRefund(o.id), 'Remboursement imprimé ✓');
      case 'refund':
        final approval = await askCancelApproval(
          context,
          ref,
          what: 'Rembourser le ticket ${o.receiptNumber} (${Money(o.total)})',
        );
        if (approval == null || !context.mounted) return;
        final drawer = ref.read(deviceIdentityProvider).value?.deviceId ?? '';
        try {
          await ref.read(orderRepositoryProvider).refund(o.id, approval: approval, drawerId: drawer);
          messenger.showSnackBar(SnackBar(content: Text('Ticket ${o.receiptNumber} remboursé ✓')));
          if (ref.read(printerSettingsProvider).value?.receipt != null) {
            await tryPrint(() => printer.printRefund(o.id), 'Ticket ${o.receiptNumber} remboursé · reçu imprimé ✓');
          }
        } on OrderException catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(e.message)));
        }
    }
  }
}
