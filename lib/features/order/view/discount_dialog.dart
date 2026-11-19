import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../data/discounts.dart';

/// "Remise" on [what] (an item, or the whole ticket worth [gross]):
/// Offert / 10 / 20 / 50 % / other % / amount, and the reason. Returns the request
/// (without the manager's approval yet), or null.
Future<DiscountRequest?> showDiscountDialog(
  BuildContext context, {
  required String what,
  required Money gross,
  List<String> lineIds = const [],
}) => showDialog<DiscountRequest>(
  context: context,
  builder: (_) => _DiscountDialog(what: what, gross: gross, lineIds: lineIds),
);

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({required this.what, required this.gross, required this.lineIds});
  final String what;
  final Money gross;
  final List<String> lineIds;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  String _type = DiscountType.free;
  int _value = 0;
  String? _reason;
  final _custom = TextEditingController();
  String _customKind = ''; // '' | 'percent' | 'amount'

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _pick(String type, int value) => setState(() {
    _type = type;
    _value = value;
    _customKind = '';
    _custom.clear();
  });

  void _custom_(String kind) => setState(() {
    _customKind = kind;
    _type = kind == 'percent' ? DiscountType.percent : DiscountType.amount;
    _value = 0;
    _custom.clear();
  });

  void _readCustom(String v) {
    final t = v.trim().replaceAll(',', '.');
    setState(() {
      if (_customKind == 'percent') {
        final p = double.tryParse(t);
        _value = p == null ? 0 : (p * 100).round();
      } else {
        _value = Money.tryParse(t)?.millimes ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final discount = discountOf(widget.gross, _type, _value);
    final valid =
        _reason != null &&
        (_type == DiscountType.free ||
            (_type == DiscountType.percent && _value >= 1 && _value <= 10000) ||
            (_type == DiscountType.amount && _value >= 1));
    final text = Theme.of(context).textTheme;
    ChoiceChip choice(String key, String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(key: Key(key), label: Text(label), selected: selected, onSelected: (_) => onTap());

    return AlertDialog(
      title: Text('Remise — ${widget.what}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                choice('disc-free', 'Offert', _type == DiscountType.free, () => _pick(DiscountType.free, 0)),
                for (final p in const [10, 20, 50])
                  choice(
                    'disc-p$p',
                    '−$p %',
                    _type == DiscountType.percent && _customKind.isEmpty && _value == p * 100,
                    () => _pick(DiscountType.percent, p * 100),
                  ),
                choice('disc-custom-percent', 'Autre %', _customKind == 'percent', () => _custom_('percent')),
                choice('disc-custom-amount', 'Montant', _customKind == 'amount', () => _custom_('amount')),
              ],
            ),
            if (_customKind.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('disc-custom-input'),
                controller: _custom,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _customKind == 'percent' ? 'Pourcentage (%)' : 'Montant (DT)',
                  border: const OutlineInputBorder(),
                ),
                onChanged: _readCustom,
              ),
            ],
            const SizedBox(height: 16),
            Text('Motif', style: text.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in DiscountReasons.labels.entries)
                  choice('reason-${e.key}', e.value, _reason == e.key, () => setState(() => _reason = e.key)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Remise : $discount  ·  à payer : ${widget.gross - discount}',
              key: const Key('disc-preview'),
              style: text.titleMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const Key('disc-confirm'),
          onPressed:
              valid
                  ? () => Navigator.pop(
                    context,
                    DiscountRequest(type: _type, value: _value, reason: _reason!, lineIds: widget.lineIds),
                  )
                  : null,
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
