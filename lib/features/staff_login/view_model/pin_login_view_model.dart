import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/staff/staff_repository.dart';
import 'staff_session.dart';

class PinLoginState {
  final StaffRow? selected;
  final String pin;
  final bool checking;
  final String? error;
  final DateTime? lockedUntil;

  const PinLoginState({this.selected, this.pin = '', this.checking = false, this.error, this.lockedUntil});

  PinLoginState copyWith({String? pin, bool? checking, String? error, DateTime? lockedUntil, bool clearError = false}) =>
      PinLoginState(
        selected: selected,
        pin: pin ?? this.pin,
        checking: checking ?? this.checking,
        error: clearError ? null : (error ?? this.error),
        lockedUntil: lockedUntil ?? this.lockedUntil,
      );
}

/// ViewModel of the login screen: pick a person, type the PIN, check it offline.
class PinLoginViewModel extends Notifier<PinLoginState> {
  static const maxLength = 6;

  @override
  PinLoginState build() => const PinLoginState();

  void select(StaffRow staff) => state = PinLoginState(selected: staff);

  void back() => state = const PinLoginState();

  void digit(String d) {
    if (state.checking || state.pin.length >= maxLength) return;
    state = state.copyWith(pin: state.pin + d, clearError: true);
  }

  void erase() {
    if (state.pin.isEmpty || state.checking) return;
    state = state.copyWith(pin: state.pin.substring(0, state.pin.length - 1), clearError: true);
  }

  Future<void> submit() async {
    final staff = state.selected;
    if (staff == null || state.checking) return;
    if (state.pin.length < 4) {
      state = state.copyWith(error: 'Le code fait 4 à 6 chiffres.');
      return;
    }
    state = state.copyWith(checking: true, clearError: true);
    final result = await ref.read(staffRepositoryProvider).login(staff, state.pin);
    if (!ref.mounted) return;
    switch (result) {
      case PinOk(:final staff):
        ref.read(staffSessionProvider.notifier).loggedIn(staff);
        state = const PinLoginState();
      case PinWrong(:final remaining):
        state = PinLoginState(
          selected: staff,
          error: 'Code incorrect. Encore $remaining essai${remaining > 1 ? 's' : ''}.',
        );
      case PinLocked(:final until):
        state = PinLoginState(selected: staff, lockedUntil: until, error: 'Trop d’essais. Réessayez dans 1 minute.');
    }
  }
}

final pinLoginViewModelProvider = NotifierProvider<PinLoginViewModel, PinLoginState>(PinLoginViewModel.new);
