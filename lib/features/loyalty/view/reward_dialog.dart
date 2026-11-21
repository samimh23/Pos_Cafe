import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../order/data/order_repository.dart';
import '../loyalty_reward.dart';
import '../reward_actions.dart';

/// "Fidélité" on the ticket: the cashier types the customer's 6-digit code,
/// sees the reward and what it does on this ticket, then confirms.
/// Returns what was applied, or null if cancelled.
Future<RewardCheck?> showRewardDialog(
  BuildContext context, {
  required RewardActions rewards,
  required String orderId,
}) => showDialog<RewardCheck>(context: context, builder: (_) => _RewardDialog(rewards: rewards, orderId: orderId));

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({required this.rewards, required this.orderId});
  final RewardActions rewards;
  final String orderId;

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  final _code = TextEditingController();
  RewardCheck? _checked;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
    } on OrderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() => _run(() async {
    final c = await widget.rewards.check(widget.orderId, _code.text.trim());
    if (mounted) setState(() => _checked = c);
  });

  Future<void> _apply() => _run(() async {
    final c = await widget.rewards.redeem(widget.orderId, _code.text.trim());
    if (mounted) Navigator.pop(context, c);
  });

  @override
  Widget build(BuildContext context) {
    final checked = _checked;
    return AlertDialog(
      title: const Text('Récompense fidélité'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Le client montre le code à 6 chiffres affiché dans son application Kahwti.'),
            const SizedBox(height: 16),
            TextField(
              key: const Key('reward-code'),
              controller: _code,
              autofocus: true,
              enabled: !_busy && checked == null,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '000000', border: OutlineInputBorder()),
              onSubmitted: (_) => _check(),
            ),
            if (checked != null) ...[
              const SizedBox(height: 16),
              Card(
                key: const Key('reward-preview'),
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: Text(checked.reward.rewardName),
                  subtitle: Text(
                    '${checked.reward.customerName} · ${checked.reward.points} points\n${checked.description}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const Key('reward-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Annuler')),
        if (checked == null)
          FilledButton(
            key: const Key('reward-check'),
            onPressed: _busy ? null : _check,
            child: Text(_busy ? 'Vérification…' : 'Vérifier'),
          )
        else
          FilledButton.icon(
            key: const Key('reward-apply'),
            icon: const Icon(Icons.check),
            onPressed: _busy ? null : _apply,
            label: Text(_busy ? 'Un instant…' : 'Appliquer (−${checked.reward.points} pts)'),
          ),
      ],
    );
  }
}
