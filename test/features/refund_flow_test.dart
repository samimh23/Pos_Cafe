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

/// The manager refunds a ticket from "Tickets du jour".
void main() {
  testWidgets('pay a ticket → ⋮ Tickets du jour → Rembourser (reason) → "Remboursé"', (tester) async {
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

    Future<void> io() => tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));

    await loginAs(tester, 'staff-sonia'); // a manager: approves by herself
    for (var i = 0; i < 20 && find.byKey(const Key('product-p1')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Sell an Express, cash (opening the drawer with 50 DT first).
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    await tester.tap(find.byKey(const Key('pay-cash')));
    await settle();
    await tester.tap(find.byKey(const Key('float-50000')));
    await settle();
    await tester.tap(find.byKey(const Key('cash-open-confirm')));
    await io();
    await settle();
    await tester.tap(find.byKey(const Key('cash-confirm')));
    await io();
    await settle();

    // ⋮ → Tickets du jour → T1-000001 → Rembourser → "Problème de qualité".
    await tester.tap(find.byKey(const Key('pos-menu')));
    await settle();
    await tester.tap(find.text('Tickets du jour'));
    await settle();
    expect(find.byKey(const Key('ticket-T1-000001')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ticket-T1-000001')));
    await io();
    await settle();
    await tester.tap(find.byKey(const Key('ticket-refund')));
    await settle();
    await tester.tap(find.byKey(const Key('cancel-reason-quality')));
    await io();
    await settle();

    expect(find.text('Remboursé'), findsOneWidget);
    final events = await tester.runAsync(
      () async => [
        ...api.pushed.values.where((e) => e['type'] == 'order.refunded').map((e) => e['approvedBy']),
        for (final e in await db.select(db.outboxEvents).get())
          if (e.type == 'order.refunded') e.approvedBy,
      ],
    );
    expect(events, ['staff-sonia']);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
