import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';

import '../../../core/lan/lan_providers.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../cash/view/cash_screen.dart';
import '../../cash/view_model/cash_view_model.dart';
import '../../floor/view_model/floor_view_model.dart';
import '../../loyalty/view/reward_dialog.dart';
import '../../print/view/loyalty_qr_dialog.dart';
import '../../print/print_providers.dart';
import '../../../core/print/printers.dart';
import '../data/order_repository.dart';
import '../view_model/order_view_model.dart';
import '../data/discounts.dart';
import 'approval_dialog.dart';
import 'discount_dialog.dart';
import 'move_ticket_dialog.dart';
import 'payment_dialog.dart';

/// Right side of the POS: the current ticket (a table or the counter), totals and the pay button.
class TicketPanel extends ConsumerWidget {
  const TicketPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticket = ref.watch(ticketProvider);
    final target = ref.watch(activeTargetProvider);
    final canPay = ref.watch(canTakePaymentsProvider);
    final canPrint = ref.watch(canPrintProvider);
    // Items not sent to the bar / kitchen yet.
    final unsent = ticket.lines
        .where((l) => l.sentAt == null && (l.station == 'bar' || l.station == 'kitchen'))
        .fold(0, (sum, l) => sum + l.qty);
    final billRequested = ticket.order?.billRequestedAt != null;
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
              if (billRequested)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Chip(
                    key: Key('ticket-bill-requested'),
                    avatar: Icon(Icons.receipt_long, size: 16),
                    label: Text('Addition demandée'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (ticket.unpaidLines.isNotEmpty && ticket.order != null)
                IconButton(
                  key: const Key('ticket-reward'),
                  tooltip: 'Récompense fidélité (code client)',
                  icon: const Icon(Icons.card_giftcard),
                  onPressed: () => _reward(context, ref, ticket.order!.id),
                ),
              if (ticket.unpaidLines.isNotEmpty)
                IconButton(
                  key: const Key('ticket-discount'),
                  tooltip: 'Remise sur le ticket',
                  icon: const Icon(Icons.percent),
                  onPressed: () => _discount(context, ref, vm, what: 'tout le ticket', lines: ticket.unpaidLines),
                ),
              if (canPay && canPrint && ticket.order != null && !ticket.isEmpty)
                IconButton(
                  key: const Key('print-bill'),
                  tooltip: 'Imprimer l’addition',
                  icon: const Icon(Icons.receipt_long),
                  onPressed:
                      () => _print(
                        context,
                        () => ref.read(printActionsProvider).printBill(ticket.order!.id),
                        'Addition imprimée ✓',
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
                  onPressed: () => _confirmCancel(context, ref, vm, ticket),
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
                        // ✓ = already sent to the bar / kitchen.
                        leading:
                            l.sentAt != null
                                ? Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Colors.green.shade600,
                                  semanticLabel: 'Envoyé',
                                )
                                : null,
                        title: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [
                            if (mods.isNotEmpty) mods,
                            '${Money(l.unitPrice + l.modifiersPrice).toDecimalString()} × ${l.qty}'
                                '${l.discountType == null ? '' : '  ·  ${discountLabel(l.discountType, l.discountValue)} (${DiscountReasons.label(l.discountReason)})'}',
                          ].join('\n'),
                          style:
                              l.discountType == null ? null : TextStyle(color: Theme.of(context).colorScheme.tertiary),
                        ),
                        isThreeLine: mods.isNotEmpty,
                        onTap: paid ? null : () => _lineActions(context, ref, vm, l),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (paid)
                              const Chip(label: Text('Payé'), visualDensity: VisualDensity.compact)
                            else ...[
                              IconButton(
                                tooltip: 'Moins',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed:
                                    () =>
                                        l.sentAt == null
                                            ? _guard(context, () => vm.decrement(l))
                                            : _cancelSent(context, ref, vm, l),
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
              if (!ticket.totals.discount.isZero)
                Row(
                  children: [
                    const Expanded(child: Text('Remises & offerts')),
                    Text('−${ticket.totals.discount}', key: const Key('ticket-discounts')),
                  ],
                ),
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
              if (canPrint && unsent > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    key: const Key('send-order'),
                    icon: const Icon(Icons.send),
                    label: Text('Envoyer au bar / cuisine ($unsent)'),
                    onPressed: () => _send(context, ref, ticket.order!.id),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 64,
                child:
                    canPay
                        ? FilledButton.icon(
                          key: const Key('pay-cash'),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(
                            ticket.isEmpty
                                ? 'Encaisser'
                                : ticket.remaining.isZero
                                ? 'Clôturer (tout est offert)'
                                : 'Encaisser ${ticket.remaining}',
                          ),
                          onPressed: ticket.isEmpty || busy ? null : () => _pay(context, ref, vm, ticket),
                        )
                        // Server tablets: the cashier takes the payment at the main POS.
                        : FilledButton.tonalIcon(
                          key: const Key('request-bill'),
                          icon: const Icon(Icons.receipt_long),
                          label: Text(billRequested ? 'Addition demandée ✓' : 'Demander l’addition'),
                          onPressed: ticket.isEmpty || billRequested ? null : () => _guard(context, vm.requestBill),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Prints and says so; a printer problem is shown, never silently lost.
  Future<void> _print(BuildContext context, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on PrintException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// "Envoyer": the new items go to the bar / kitchen printers.
  Future<void> _send(BuildContext context, WidgetRef ref, String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await ref.read(printActionsProvider).sendOrder(orderId);
      messenger.showSnackBar(SnackBar(content: Text('${r.message} ✓')));
    } on PrintException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), duration: const Duration(seconds: 8)));
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), duration: const Duration(seconds: 8)));
    }
  }

  /// Tap on an item: offer it, discount it, or remove its discount.
  Future<void> _lineActions(BuildContext context, WidgetRef ref, OrderViewModel vm, OrderLineRow l) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder:
          (c) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text('${l.qty} × ${l.name}', style: Theme.of(c).textTheme.titleMedium)),
                ListTile(
                  key: const Key('line-offer'),
                  leading: const Icon(Icons.card_giftcard),
                  title: const Text('Offrir'),
                  onTap: () => Navigator.pop(c, 'offer'),
                ),
                ListTile(
                  key: const Key('line-discount'),
                  leading: const Icon(Icons.percent),
                  title: const Text('Remise…'),
                  onTap: () => Navigator.pop(c, 'discount'),
                ),
                if (l.discountType != null)
                  ListTile(
                    key: const Key('line-undiscount'),
                    leading: const Icon(Icons.undo),
                    title: const Text('Retirer la remise'),
                    onTap: () => Navigator.pop(c, 'remove'),
                  ),
              ],
            ),
          ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'offer':
        // "Offrir" = free, reason "Geste commercial"; still needs a manager.
        final approver = await askManagerApproval(context, ref, what: 'Offert : ${l.qty} × ${l.name}');
        if (approver == null || !context.mounted) return;
        await _guard(
          context,
          () => vm.discount(DiscountRequest.free(reason: 'geste', lineIds: [l.id], approvedBy: approver)),
        );
      case 'discount':
        await _discount(context, ref, vm, what: '${l.qty} × ${l.name}', lines: [l], only: true);
      case 'remove':
        await _guard(context, () => vm.removeDiscount([l.id]));
    }
  }

  /// Discount dialog → manager approval → apply.
  Future<void> _discount(
    BuildContext context,
    WidgetRef ref,
    OrderViewModel vm, {
    required String what,
    required List<OrderLineRow> lines,
    bool only = false,
  }) async {
    final gross = lines.fold(Money.zero, (sum, l) => sum + lineGross(amountsOf(l)));
    final request = await showDiscountDialog(
      context,
      what: what,
      gross: gross,
      lineIds: only ? [for (final l in lines) l.id] : const [],
    );
    if (request == null || !context.mounted) return;
    final approver = await askManagerApproval(
      context,
      ref,
      what: '${discountLabel(request.type, request.value)} sur $what (${DiscountReasons.label(request.reason)})',
    );
    if (approver == null || !context.mounted) return;
    await _guard(context, () => vm.discount(request.approved(approver)));
  }

  /// Shows refusals (e.g. "Cet article est déjà payé.") instead of failing silently.
  Future<bool> _guard(BuildContext context, Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      return true;
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return false;
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, OrderViewModel vm, TicketState ticket) async {
    // First payment of the day: open the drawer with its float first.
    if (ref.read(openCashSessionProvider).value == null) {
      if (!await openDrawer(context, ref) || !context.mounted) return;
    }
    // Everything offered (gift, "Offert"): nothing to take, the ticket just closes at 0 DT.
    final request =
        ticket.remaining.isZero
            ? const PaymentRequest.cash(amount: Money.zero, tendered: Money.zero)
            : await showPaymentDialog(context, remaining: ticket.remaining, unpaidLines: ticket.unpaidLines);
    if (request == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final orderId = ticket.order?.id;
    final printer = ref.read(printActionsProvider);
    final settings = ref.read(printerSettingsProvider).value ?? PrinterSettings.none;
    final canPrint = ref.read(canPrintProvider);
    try {
      final r = await vm.pay(request);
      final how = request.method == 'card' ? 'par carte' : 'Rendu ${r.change}';
      // Customer receipt: printed automatically when set so (⋮ → Imprimantes), else on demand.
      var printNote = '';
      if (r.closed && orderId != null && canPrint && settings.autoReceipt) {
        try {
          await printer.printReceipt(orderId);
          printNote = ' · ticket imprimé';
        } on PrintException catch (e) {
          printNote = ' · ${e.message}';
        } on OrderException catch (e) {
          printNote = ' · ${e.message}';
        }
      }
      // No printed receipt: the loyalty QR can be shown on screen instead.
      final loyaltyUrl =
          r.closed && orderId != null && printNote != ' · ticket imprimé' && ref.read(posModeProvider) != PosMode.tablet
              ? await ref.read(printServiceProvider).loyaltyUrl(orderId)
              : null;
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r.closed
                ? 'Payé ✅  Ticket ${r.receiptNumber} · $how$printNote'
                : 'Reçu ${r.amount} · $how · Reste ${r.remaining}',
          ),
          duration: const Duration(seconds: 6),
          action:
              loyaltyUrl != null && !canPrint
                  ? SnackBarAction(
                    label: 'QR fidélité',
                    onPressed: () => showLoyaltyQr(context, url: loyaltyUrl, receiptNumber: r.receiptNumber ?? ''),
                  )
                  : r.closed && orderId != null && canPrint
                  ? SnackBarAction(
                    label: printNote == ' · ticket imprimé' ? 'Réimprimer' : 'Imprimer le ticket',
                    onPressed: () => printer.printReceipt(orderId).catchError((_) {}),
                  )
                  : null,
        ),
      );
    } on OrderException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// The customer's code from the Kahwti app → the reward goes on the ticket (no manager needed).
  Future<void> _reward(BuildContext context, WidgetRef ref, String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final applied = await showRewardDialog(context, rewards: ref.read(rewardActionsProvider), orderId: orderId);
    if (applied == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('🎁 ${applied.reward.rewardName} pour ${applied.reward.customerName} · ${applied.description}'),
      ),
    );
  }

  Future<void> _move(BuildContext context, OrderViewModel vm) async {
    final choice = await showMoveTicketDialog(context);
    if (choice == null || !context.mounted) return;
    await _guard(context, () => vm.moveTo(choice.table));
  }

  /// "−" on an item already sent: reason + manager, then the bar/kitchen gets an ANNULÉ slip.
  Future<void> _cancelSent(BuildContext context, WidgetRef ref, OrderViewModel vm, OrderLineRow l) async {
    final approval = await askCancelApproval(context, ref, what: 'Annuler 1 × ${l.name} (déjà envoyé)');
    if (approval == null || !context.mounted) return;
    final orderId = ref.read(ticketProvider).order?.id;
    final ok = await _guard(context, () => vm.decrement(l, approval: approval));
    if (ok && orderId != null && context.mounted) {
      await _print(
        context,
        () => ref.read(printActionsProvider).printCancellation(orderId, items: [(l.id, 1)], reason: approval.reason),
        'Annulation envoyée en préparation ✓',
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, OrderViewModel vm, TicketState ticket) async {
    // Items already at the bar/kitchen: a manager must approve, and they get an ANNULÉ slip.
    final sent = [
      for (final l in ticket.lines)
        if (l.sentAt != null) l,
    ];
    if (sent.isNotEmpty) {
      final approval = await askCancelApproval(context, ref, what: 'Annuler le ticket (déjà envoyé en préparation)');
      if (approval == null || !context.mounted) return;
      final orderId = ticket.order!.id;
      final ok = await _guard(context, () => vm.cancelOrder(approval: approval));
      if (ok && context.mounted) {
        await _print(
          context,
          () => ref
              .read(printActionsProvider)
              .printCancellation(orderId, items: [for (final l in sent) (l.id, l.qty)], reason: approval.reason),
          'Annulation envoyée en préparation ✓',
        );
      }
      return;
    }
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
