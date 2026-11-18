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

/// Full POS flow in the real UI: add products (with options), pay cash, ticket resets.
void main() {
  testWidgets('order 2 Express + 1 Cappuccino Grand, pay cash, get receipt T1-000001', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi();
    api.products.add({
      'id': 'p3',
      'categoryId': 'c1',
      'name': 'Cappuccino',
      'price': 3500,
      'vatRateBp': 1900,
      'station': 'bar',
      'available': true,
      'modifierGroups': [
        {
          'id': 'size',
          'name': 'Taille',
          'minSelect': 1,
          'maxSelect': 1,
          'modifiers': [
            {'id': 'normal', 'name': 'Normal', 'extraPrice': 0},
            {'id': 'grand', 'name': 'Grand', 'extraPrice': 500},
          ],
        },
      ],
    });

    // Already paired.
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

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // First sync brings the staff list; the server logs in.
    await loginAsAhmed(tester);

    // Wait for the menu.
    for (var i = 0; i < 20 && find.byKey(const Key('product-p1')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Touchez un produit pour commencer'), findsOneWidget);

    // 2 × Express
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();

    // Cappuccino → modifiers dialog → choose "Grand"
    await tester.tap(find.byKey(const Key('product-p3')));
    await settle();
    expect(find.text('Taille'), findsOneWidget);
    await tester.tap(find.byKey(const Key('modifier-grand')));
    await settle();
    await tester.tap(find.byKey(const Key('modifiers-confirm')));
    await settle();

    // 2 × 1.200 + 4.000 = 6.400
    expect(tester.widget<Text>(find.byKey(const Key('ticket-total'))).data, '6.400 DT');
    expect(find.text('Grand\n4.000 × 1'), findsOneWidget);

    // Pay with a 10 DT note
    await tester.tap(find.byKey(const Key('pay-cash')));
    await settle();
    await tester.tap(find.text('10.000 DT'));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('cash-change'))).data, 'Rendu : 3.600 DT');
    await tester.tap(find.byKey(const Key('cash-confirm')));
    await settle();

    expect(find.textContaining('T1-000001'), findsOneWidget);
    expect(find.textContaining('Rendu 3.600 DT'), findsOneWidget);
    expect(find.text('Touchez un produit pour commencer'), findsOneWidget); // ticket reset

    // Events: everything the cashier did is in the outbox or already pushed to the (fake) server.
    final pushedTypes = [...api.pushed.values.map((e) => e['type'])];
    final pendingTypes = await tester.runAsync(
      () async => [for (final e in await db.select(db.outboxEvents).get()) e.type],
    );
    final all = [...pushedTypes, ...?pendingTypes];
    expect(all, containsAll(['order.opened', 'order.item_added', 'payment.added', 'order.closed']));

    // Every sale event says WHO did it (the staff member logged in on this POS).
    final pushedOrder = api.pushed.values.where((e) => '${e['type']}'.startsWith('order.'));
    final pendingOrder = await tester.runAsync(
      () async => [
        for (final e in await db.select(db.outboxEvents).get())
          if (e.type.startsWith('order.')) e.staffId,
      ],
    );
    final staffIds = {...pushedOrder.map((e) => e['staffId']), ...?pendingOrder};
    expect(staffIds, {'staff-ahmed'});

    // Tap the name → logged out → back to "Qui êtes-vous ?".
    expect(find.text('Ahmed'), findsOneWidget);
    await tester.tap(find.byKey(const Key('staff-chip')));
    await settle();
    expect(find.text('Qui êtes-vous ?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
