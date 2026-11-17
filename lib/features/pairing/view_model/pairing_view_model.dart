import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/pos_api.dart';
import '../../../core/providers.dart';

class PairingState {
  final bool submitting;
  final String? error;
  const PairingState({this.submitting = false, this.error});
}

/// ViewModel of the pairing screen. No widgets here.
class PairingViewModel extends Notifier<PairingState> {
  @override
  PairingState build() => const PairingState();

  Future<void> pair({required String code, required String name}) async {
    if (code.trim().isEmpty || name.trim().isEmpty) {
      state = const PairingState(error: 'Entrez le code et un nom pour cette caisse.');
      return;
    }
    state = const PairingState(submitting: true);
    try {
      await ref.read(deviceRepositoryProvider).pair(code: code.trim(), name: name.trim());
      ref.invalidate(deviceIdentityProvider); // the app switches to the POS screen
      if (ref.mounted) state = const PairingState();
    } on ApiException catch (e) {
      if (ref.mounted) state = PairingState(error: messageFor(e));
    }
  }

  static String messageFor(ApiException e) => switch (e.code) {
    'PAIRING_CODE_INVALID' => 'Code invalide, déjà utilisé ou expiré. Demandez un nouveau code.',
    'VALIDATION_ERROR' => 'Le code ou le nom n\'est pas valide.',
    'NETWORK' => 'Serveur injoignable. Vérifiez la connexion internet.',
    _ => 'Erreur: ${e.message}',
  };
}

final pairingViewModelProvider = NotifierProvider<PairingViewModel, PairingState>(PairingViewModel.new);
