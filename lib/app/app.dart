import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/home/view/home_screen.dart';
import '../features/pairing/view/pairing_screen.dart';

class PosCafeApp extends StatelessWidget {
  const PosCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pos Café',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF8B5E3C), useMaterial3: true),
      home: const _StartGate(),
    );
  }
}

/// Not paired → pairing screen. Paired → POS.
class _StartGate extends ConsumerWidget {
  const _StartGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(deviceIdentityProvider)) {
      AsyncData(value: final identity?) => HomeScreen(identity: identity),
      AsyncData() => const PairingScreen(),
      AsyncError(:final error) => Scaffold(body: Center(child: Text('Erreur au démarrage: $error'))),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
