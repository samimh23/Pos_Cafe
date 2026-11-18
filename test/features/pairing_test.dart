import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/app/app.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/providers.dart';
import 'package:pos_cafe/features/pairing/view_model/pairing_view_model.dart';

import '../fakes.dart';
import 'staff_login_helper.dart';

void main() {
  late AppDatabase db;
  late MemorySecretStore secrets;
  late FakePosApi api;

  List<Override> overrides() => [
    databaseProvider.overrideWithValue(db),
    secretStoreProvider.overrideWithValue(secrets),
    posApiProvider.overrideWithValue(api),
  ];

  setUp(() {
    // closeStreamsSynchronously: no leftover stream timers in widget tests.
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    secrets = MemorySecretStore();
    api = FakePosApi();
  });
  tearDown(() => db.close());

  group('PairingViewModel', () {
    test('valid code → identity saved, token + private key in secure storage', () async {
      final c = ProviderContainer(overrides: overrides());
      addTearDown(c.dispose);

      await c.read(pairingViewModelProvider.notifier).pair(code: 'ABCD-EFGH', name: 'Caisse principale');

      expect(c.read(pairingViewModelProvider).error, isNull);
      final identity = await c.read(deviceIdentityProvider.future);
      expect(identity?.deviceCode, 'T1');
      expect(identity?.name, 'Caisse principale');
      expect(secrets.values[SecretKeys.deviceToken], 'secret-token-1');
      expect(secrets.values[SecretKeys.devicePrivateKey], isNotEmpty);
    });

    test('invalid code → French error, nothing saved', () async {
      final c = ProviderContainer(overrides: overrides());
      addTearDown(c.dispose);

      await c.read(pairingViewModelProvider.notifier).pair(code: 'NOPE-NOPE', name: 'Caisse');

      expect(c.read(pairingViewModelProvider).error, contains('Code invalide'));
      expect(await c.read(deviceIdentityProvider.future), isNull);
      expect(secrets.values, isEmpty);
    });

    test('empty fields → validation message without calling the server', () async {
      final c = ProviderContainer(overrides: overrides());
      addTearDown(c.dispose);
      await c.read(pairingViewModelProvider.notifier).pair(code: ' ', name: 'Caisse');
      expect(c.read(pairingViewModelProvider).error, isNotNull);
      expect(api.devices, 0);
    });
  });

  testWidgets('not paired → pairing screen; after pairing → staff login → POS home with the menu', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(overrides: overrides(), child: const PosCafeApp()));
    await tester.pumpAndSettle();
    expect(find.text('Associer cette caisse'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pairing-code')), 'ABCD-EFGH');
    await tester.tap(find.byKey(const Key('pairing-submit')));
    // pairing → first sync pulls the menu and the staff → "Qui êtes-vous ?"
    await loginAsAhmed(tester);
    for (var i = 0; i < 10 && find.text('Express').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('T1'), findsOneWidget);
    expect(find.text('Boissons chaudes'), findsOneWidget);
    expect(find.text('Express'), findsOneWidget);
    expect(find.byKey(const Key('staff-chip')), findsOneWidget);

    // Stop the periodic sync timer before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}
