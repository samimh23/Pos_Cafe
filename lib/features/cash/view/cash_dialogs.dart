import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../data/cash_repository.dart';

Money? parseAmount(String text) => Money.tryParse(text.trim().replaceAll(',', '.'));

/// "Ouvrir la caisse": the cash already in the drawer (opening float).
Future<Money?> showOpenDrawerDialog(BuildContext context) =>
    showDialog<Money>(context: context, builder: (_) => const _OpenDrawerDialog());

class _OpenDrawerDialog extends StatefulWidget {
  const _OpenDrawerDialog();
  @override
  State<_OpenDrawerDialog> createState() => _OpenDrawerDialogState();
}

class _OpenDrawerDialogState extends State<_OpenDrawerDialog> {
  final _input = TextEditingController();
  static const _common = [Money.zero, Money.dt(20), Money.dt(50), Money.dt(100)];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = parseAmount(_input.text);
    return AlertDialog(
      title: const Text('Ouvrir la caisse'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Comptez les espèces déjà dans le tiroir (le fond de caisse).'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final m in _common)
                  ActionChip(
                    key: Key('float-${m.millimes}'),
                    label: Text(m.toString()),
                    onPressed: () => setState(() => _input.text = m.toDecimalString()),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('float-input'),
              controller: _input,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Fond de caisse (DT)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('cash-open-confirm'),
          onPressed: amount == null || amount.isNegative ? null : () => Navigator.pop(context, amount),
          child: const Text('Ouvrir'),
        ),
      ],
    );
  }
}

/// "Entrée / Sortie d'argent": amount + reason.
Future<(Money, String)?> showMovementDialog(BuildContext context, {required bool cashIn}) =>
    showDialog<(Money, String)>(context: context, builder: (_) => _MovementDialog(cashIn: cashIn));

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.cashIn});
  final bool cashIn;
  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = parseAmount(_amount.text);
    final ok = amount != null && amount > Money.zero && _reason.text.trim().isNotEmpty;
    return AlertDialog(
      title: Text(widget.cashIn ? 'Entrée d’argent' : 'Sortie d’argent'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('move-amount'),
              controller: _amount,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Montant (DT)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('move-reason'),
              controller: _reason,
              decoration: InputDecoration(
                labelText: 'Motif',
                hintText: widget.cashIn ? 'Monnaie apportée…' : 'Fournisseur pain, courses…',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('move-confirm'),
          onPressed: ok ? () => Navigator.pop(context, (amount, _reason.text.trim())) : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// "Clôturer": count the drawer; the gap shows live.
Future<(Money, String)?> showCloseDrawerDialog(BuildContext context, {required Money expected}) =>
    showDialog<(Money, String)>(context: context, builder: (_) => _CloseDialog(expected: expected));

/// A gap of 1 DT or more is shown in red (and flagged to the owner).
const bigGap = Money.dt(1);

class _CloseDialog extends StatefulWidget {
  const _CloseDialog({required this.expected});
  final Money expected;
  @override
  State<_CloseDialog> createState() => _CloseDialogState();
}

class _CloseDialogState extends State<_CloseDialog> {
  final _counted = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counted = parseAmount(_counted.text);
    final gap = counted == null ? null : counted - widget.expected;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Clôturer la caisse'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Comptez les espèces du tiroir et saisissez le total.'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('close-counted'),
              controller: _counted,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Espèces comptées (DT)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (gap != null)
              Text(
                gap.isZero ? 'Caisse juste ✓' : (gap.isNegative ? 'Il manque ${-gap}' : 'Excédent de $gap'),
                key: const Key('close-gap'),
                style: text.titleLarge?.copyWith(color: gapColor(gap)),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('close-note'),
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Commentaire (facultatif)',
                hintText: 'Ex. erreur de rendu sur un billet de 20',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('close-confirm'),
          onPressed: counted == null || counted.isNegative ? null : () => Navigator.pop(context, (counted, _note.text)),
          child: const Text('Clôturer'),
        ),
      ],
    );
  }
}

Color gapColor(Money gap) {
  if (gap.isZero) return Colors.green.shade700;
  final big = gap.isNegative ? -gap >= bigGap : gap >= bigGap;
  return big ? Colors.red.shade700 : Colors.orange.shade800;
}

/// The closing report ("Z") shown right after closing.
/// [onPrint]: prints the report on the receipt printer (null = no printer here).
Future<void> showClosingReport(BuildContext context, CashClosing c, {Future<void> Function()? onPrint}) =>
    showDialog<void>(
      context: context,
      builder: (context) {
        final s = c.summary;
        final text = Theme.of(context).textTheme;
        Widget row(String label, Money m, {Key? key, TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [Expanded(child: Text(label, style: style)), Text(m.toString(), key: key, style: style)],
          ),
        );
        String time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
        return AlertDialog(
          key: const Key('closing-report'),
          title: const Text('Clôture de caisse'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ouverte à ${time(s.openedAt)}${s.openedBy == null ? '' : ' par ${s.openedBy}'} · '
                  'clôturée à ${time(c.closedAt)}${c.closedBy == null ? '' : ' par ${c.closedBy}'}',
                ),
                Text('${s.ticketCount} ticket${s.ticketCount > 1 ? 's' : ''} encaissé${s.ticketCount > 1 ? 's' : ''}'),
                const Divider(height: 24),
                row('Fond de caisse', s.openingFloat),
                row('Ventes espèces', s.cashSales),
                row('Entrées d’argent', s.cashIn),
                row('Sorties d’argent', -s.cashOut),
                row('Espèces attendues', s.expectedCash, style: text.titleMedium),
                row('Espèces comptées', c.counted, style: text.titleMedium),
                row(
                  'Écart',
                  c.difference,
                  key: const Key('report-gap'),
                  style: text.titleLarge?.copyWith(color: gapColor(c.difference)),
                ),
                const Divider(height: 24),
                row('Ventes carte (TPE)', s.cardSales),
                if (!s.discounts.isZero) row('Remises & offerts', -s.discounts),
                if (!s.refunds.isZero) row('Remboursements', -s.refunds),
                if (c.note != null) ...[const SizedBox(height: 8), Text('Commentaire : ${c.note}')],
              ],
            ),
          ),
          actions: [
            if (onPrint != null)
              TextButton.icon(
                key: const Key('report-print'),
                icon: const Icon(Icons.print),
                label: const Text('Imprimer'),
                onPressed: onPrint,
              ),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Terminer')),
          ],
        );
      },
    );
