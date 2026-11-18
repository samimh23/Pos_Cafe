import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/device_repository.dart';
import '../core/lan/lan_providers.dart';
import '../core/providers.dart';
import '../core/sync/sync_controller.dart';
import '../features/floor/view/floor_screen.dart';
import '../features/floor/view_model/floor_view_model.dart';
import '../features/home/view/home_screen.dart';
import '../features/pairing/view/pairing_screen.dart';
import '../features/staff_login/view/staff_login_screen.dart';
import '../features/staff_login/view_model/staff_session.dart';

class PosCafeApp extends StatelessWidget {
  const PosCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pos Café',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8B5E3C),
        useMaterial3: true,
        // Floating, centred messages: they never cover the ticket's "Encaisser" button.
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 520),
      ),
      home: const _StartGate(),
    );
  }
}

/// Not paired → pairing. Paired but nobody logged in → staff PIN login.
/// Logged in → tables (if the café has tables) → the ticket of a table or the counter.
class _StartGate extends ConsumerWidget {
  const _StartGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(deviceIdentityProvider)) {
      AsyncData(value: final identity?) => _Paired(identity: identity),
      AsyncData() => const PairingScreen(),
      AsyncError(:final error) => Scaffold(body: Center(child: Text('Erreur au démarrage: $error'))),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _Paired extends ConsumerWidget {
  const _Paired({required this.identity});
  final DeviceIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync runs on the login screen too: that's how the staff list arrives.
    ref.watch(syncControllerProvider);
    // Café network: the Hub serves the tablets; a tablet connects to the Hub.
    ref.watch(hubServerProvider);
    ref.watch(hubClientProvider);
    final staff = ref.watch(staffSessionProvider);
    if (staff == null) return StaffLoginScreen(identity: identity);
    return ref.watch(activeTargetProvider) == null ? FloorScreen(identity: identity) : HomeScreen(identity: identity);
  }
}
