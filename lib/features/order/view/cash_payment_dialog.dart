import 'package:flutter/material.dart';

import '../../../core/money/money.dart';

/// Asks how much cash the customer gave. Returns the amount given, or null if cancelled.
Future<Money?> showCashPaymentDialog(BuildContext context, Money total) =>
    showDialog<Money>(context: context, builder: (_) => _CashPaymentDialog(total: total));

class _CashPaymentDialog extends StatefulWidget {
  const _CashPaymentDialog({required this.total});
  final Money total;

  @override
  State<_CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<_CashPaymentDialog> {
  late Money _tendered = widget.total;
  final _input = TextEditingController();

  /// Common Tunisian notes for one-tap entry.
  static const _notes = [Money.dt(5), Money.dt(10), Money.dt(20), Money.dt(50)];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _set(Money m) => setState(() {
    _tendered = m;
    _input.text = m.toDecimalString();
  });

  @override
  Widget build(BuildContext context) {
    final change = _tendered - widget.total;
    final text = Theme.of(context).textTheme;
    final ok = !change.isNegative;

    return AlertDialog(
      title: Text('Espèces — ${widget.total}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  key: const Key('cash-exact'),
                  label: const Text('Montant exact'),
                  onPressed: () => _set(widget.total),
                ),
                for (final n in _notes)
                  if (n >= widget.total) ActionChip(label: Text(n.toString()), onPressed: () => _set(n)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('cash-input'),
              controller: _input,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Montant reçu (DT)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => setState(() => _tendered = Money.tryParse(v) ?? Money.zero),
            ),
            const SizedBox(height: 16),
            Text(
              ok ? 'Rendu : $change' : 'Manque : ${-change}',
              key: const Key('cash-change'),
              style: text.headlineSmall?.copyWith(color: ok ? Colors.green.shade700 : Colors.red),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('cash-confirm'),
          onPressed: ok ? () => Navigator.pop(context, _tendered) : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
