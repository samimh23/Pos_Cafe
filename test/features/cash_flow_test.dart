import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/app/app.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/providers.dart';

import '../fakes.dart';

/// The cashier's day in the real UI: "Caisse fermée" → open with 50 DT →
/// 30 DT out for the bread → close with 19.500 counted → report shows 0.500 missing.
void main() {
  testWidgets('open the drawer, cash out, close with a count, see the gap', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi();
    // A cashier (only cashiers and managers may take cash out and close). PIN 1234.
    api.staff.add({'id': 'staff-riadh', 'name': 'Riadh', 'role': 'cashier', 'pinHash': ahmedPinHash, 'active': true});
    await secrets.write(SecretKeys.deviceToken, 'token');
    await tester.runAsync(
      () => db.setKv(
        'device_identity',
        '{"deviceId":"dev-1","deviceCode":"T1","role":"hub","tenantId":"t","branchId":"b","name":"Caisse"}',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          secretStoreProvider.overrideWithValue(secrets),
          posApiProvider.overrideWithValue(api),
        ],
        child: const PosCafeApp(),
      ),
    );
    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // Riadh logs in.
    final tile = find.byKey(const Key('staff-staff-riadh'));
    for (var i = 0; i < 40 && tile.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(tile);
    await tester.pump();
    for (final d in '1234'.split('')) {
      await tester.tap(find.byKey(Key('pin-$d')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('pin-ok')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle();

    // "Caisse fermée" → Caisse screen → open with 50 DT.
    expect(find.text('Caisse fermée'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cash-chip')));
    await settle();
    await tester.tap(find.byKey(const Key('cash-open')));
    await settle();
    await tester.tap(find.byKey(const Key('float-50000')));
    await settle();
    await tester.tap(find.byKey(const Key('cash-open-confirm')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('sum-expected'))).data, '50.000 DT');

    // 30 DT out for the bread supplier.
    await tester.tap(find.byKey(const Key('cash-out')));
    await settle();
    await tester.enterText(find.byKey(const Key('move-amount')), '30');
    await tester.enterText(find.byKey(const Key('move-reason')), 'Pain du fournisseur');
    await settle(2);
    await tester.tap(find.byKey(const Key('move-confirm')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('sum-expected'))).data, '20.000 DT');
    expect(find.text('Pain du fournisseur'), findsOneWidget);

    // Close: 19.500 counted → 0.500 missing, shown live and on the report.
    await tester.tap(find.byKey(const Key('cash-close')));
    await settle();
    await tester.enterText(find.byKey(const Key('close-counted')), '19.5');
    await settle(2);
    expect(tester.widget<Text>(find.byKey(const Key('close-gap'))).data, 'Il manque 0.500 DT');
    await tester.tap(find.byKey(const Key('close-confirm')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await settle();
    expect(find.byKey(const Key('closing-report')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('report-gap'))).data, '-0.500 DT');

    await tester.tap(find.text('Terminer'));
    await settle();
    expect(find.text('Caisse fermée'), findsOneWidget); // back on the POS, drawer closed

    // Sent to the cloud (pushed or still waiting in the outbox).
    final types = await tester.runAsync(
      () async => [
        ...api.pushed.values.map((e) => e['type']),
        for (final e in await db.select(db.outboxEvents).get()) e.type,
      ],
    );
    expect(types, containsAll(['cash_session.opened', 'cash.moved', 'cash_session.closed']));

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
