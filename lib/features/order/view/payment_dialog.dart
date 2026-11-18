import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../data/order_repository.dart';

/// "Encaisser": all, an equal share, or chosen items — in cash or by card.
/// Returns what to pay, or null if cancelled.
Future<PaymentRequest?> showPaymentDialog(
  BuildContext context, {
  required Money remaining,
  required List<OrderLineRow> unpaidLines,
}) => showDialog<PaymentRequest>(
  context: context,
  builder: (_) => _PaymentDialog(remaining: remaining, unpaidLines: unpaidLines),
);

enum _Split { all, share, items }

/// One share of [remaining] when splitting in [parts]; the last share takes the rest.
Money shareOf(Money remaining, int parts) => Money((remaining.millimes + parts - 1) ~/ parts);

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.remaining, required this.unpaidLines});
  final Money remaining;
  final List<OrderLineRow> unpaidLines;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  var _split = _Split.all;
  var _parts = 2;
  final _chosen = <String>{};
  var _card = false;
  Money? _tendered; // null = exact amount
  final _input = TextEditingController();

  /// Common Tunisian notes for one-tap entry.
  static const _notes = [Money.dt(5), Money.dt(10), Money.dt(20), Money.dt(50)];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Money get _amount => switch (_split) {
    _Split.all => widget.remaining,
    _Split.share => shareOf(widget.remaining, _parts),
    _Split.items => widget.unpaidLines
        .where((l) => _chosen.contains(l.id))
        .fold(Money.zero, (sum, l) => sum + lineTotal(amountsOf(l))),
  };

  void _setTendered(Money? m) => setState(() {
    _tendered = m;
    _input.text = m?.toDecimalString() ?? '';
  });

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final tendered = _card ? amount : (_tendered ?? amount);
    final change = tendered - amount;
    final tooMuch = amount > widget.remaining;
    final ok = !amount.isZero && !tooMuch && !change.isNegative;
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Encaisser — reste ${widget.remaining}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_Split>(
                segments: const [
                  ButtonSegment(value: _Split.all, label: Text('Tout', key: Key('pay-mode-all'))),
                  ButtonSegment(value: _Split.share, label: Text('Partager', key: Key('pay-mode-share'))),
                  ButtonSegment(value: _Split.items, label: Text('Par articles', key: Key('pay-mode-items'))),
                ],
                selected: {_split},
                onSelectionChanged:
                    (s) => setState(() {
                      _split = s.first;
                      _setTendered(null);
                    }),
              ),
              const SizedBox(height: 12),
              if (_split == _Split.share)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const Key('share-minus'),
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _parts > 2 ? () => setState(() => _parts--) : null,
                    ),
                    Text('En $_parts parts', key: const Key('share-parts'), style: text.titleMedium),
                    IconButton(
                      key: const Key('share-plus'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _parts < 20 ? () => setState(() => _parts++) : null,
                    ),
                  ],
                ),
              if (_split == _Split.items)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final l in widget.unpaidLines)
                        CheckboxListTile(
                          key: Key('pay-line-${l.id}'),
                          dense: true,
                          value: _chosen.contains(l.id),
                          onChanged: (v) => setState(() => v == true ? _chosen.add(l.id) : _chosen.remove(l.id)),
                          title: Text('${l.qty} × ${l.name}'),
                          subtitle: _mods(l),
                          secondary: Text(lineTotal(amountsOf(l)).toDecimalString()),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text('À payer maintenant : $amount', key: const Key('pay-amount'), style: text.titleLarge),
              if (tooMuch)
                Text(
                  'Plus que le reste à payer (${widget.remaining}).',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.payments_outlined),
                    label: Text('Espèces', key: Key('pay-method-cash')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.credit_card),
                    label: Text('Carte', key: Key('pay-method-card')),
                  ),
                ],
                selected: {_card},
                onSelectionChanged: (s) => setState(() => _card = s.first),
              ),
              const SizedBox(height: 12),
              if (_card)
                const Text('Faites payer le client sur le terminal (TPE), puis validez quand c’est accepté.')
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      key: const Key('cash-exact'),
                      label: const Text('Montant exact'),
                      onPressed: () => _setTendered(null),
                    ),
                    for (final n in _notes)
                      if (n >= amount) ActionChip(label: Text(n.toString()), onPressed: () => _setTendered(n)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('cash-input'),
                  controller: _input,
                  decoration: const InputDecoration(labelText: 'Montant reçu (DT)', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged:
                      (v) => setState(() => _tendered = v.trim().isEmpty ? null : (Money.tryParse(v) ?? Money.zero)),
                ),
                const SizedBox(height: 12),
                Text(
                  change.isNegative ? 'Manque : ${-change}' : 'Rendu : $change',
                  key: const Key('cash-change'),
                  style: text.headlineSmall?.copyWith(color: change.isNegative ? Colors.red : Colors.green.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('cash-confirm'),
          onPressed: ok ? () => Navigator.pop(context, _request(amount, tendered)) : null,
          child: Text(_card ? 'Payé par carte' : 'Valider'),
        ),
      ],
    );
  }

  PaymentRequest _request(Money amount, Money tendered) {
    final lineIds = _split == _Split.items ? _chosen.toList() : const <String>[];
    return _card
        ? PaymentRequest.card(amount: amount, lineIds: lineIds)
        : PaymentRequest.cash(amount: amount, tendered: tendered, lineIds: lineIds);
  }

  Widget? _mods(OrderLineRow l) {
    final mods = parseChosenModifiers(l.modifiersJson).map((m) => m.name).join(', ');
    return mods.isEmpty ? null : Text(mods);
  }
}
