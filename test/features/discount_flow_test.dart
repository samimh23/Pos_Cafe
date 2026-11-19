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
import 'staff_login_helper.dart';

/// A server (Ahmed) offers a coffee; the manager (Sonia) approves with her PIN on the spot.
void main() {
  testWidgets('Offrir → manager PIN → the coffee shows "Offert" and the totals drop', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi();
    api.staff.add({'id': 'staff-sonia', 'name': 'Sonia', 'role': 'manager', 'pinHash': ahmedPinHash, 'active': true});
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

    await loginAsAhmed(tester); // a server: needs a manager to approve
    for (var i = 0; i < 20 && find.byKey(const Key('product-p1')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-total'))).data, '2.400 DT');

    // Tap the line → Offrir → Sonia types her PIN.
    await tester.tap(find.descendant(of: find.byKey(const Key('line-p1')), matching: find.text('Express')));
    await settle();
    await tester.tap(find.byKey(const Key('line-offer')));
    await settle();
    expect(find.text('Validation d’un gérant'), findsOneWidget);
    expect(find.text('Code de Sonia'), findsOneWidget);
    for (final d in '1234'.split('')) {
      await tester.tap(find.byKey(Key('approve-pin-$d')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('approve-ok')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // PIN check (PBKDF2)
    await settle();

    expect(find.textContaining('Offert (Geste commercial)'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('ticket-discounts'))).data, '−2.400 DT');
    expect(tester.widget<Text>(find.byKey(const Key('ticket-total'))).data, '0.000 DT');

    final approvedBy = await tester.runAsync(
      () async => [
        for (final e in await db.select(db.outboxEvents).get())
          if (e.type == 'order.item_discounted') (e.staffId, e.approvedBy),
      ],
    );
    expect(approvedBy, [('staff-ahmed', 'staff-sonia')]);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
