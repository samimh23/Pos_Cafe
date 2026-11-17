import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../view_model/pairing_view_model.dart';

/// First screen of a new POS: link it to a café with the code from the owner app.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController(text: 'Caisse principale');

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() => ref.read(pairingViewModelProvider.notifier).pair(code: _code.text, name: _name.text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pairingViewModelProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.point_of_sale, size: 64),
                const SizedBox(height: 16),
                Text('Associer cette caisse', style: text.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Entrez le code affiché dans l\'application du propriétaire.',
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('pairing-code'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Code (ex: K7Q2-M9XD)', border: OutlineInputBorder()),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('pairing-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nom de la caisse', border: OutlineInputBorder()),
                  onSubmitted: (_) => _submit(),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    key: const Key('pairing-submit'),
                    onPressed: state.submitting ? null : _submit,
                    child:
                        state.submitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Associer'),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Serveur: ${AppConfig.apiUrl}', style: text.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
