import 'dart:convert';

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

/// A server's real flow in the UI: tables → table 2 → order → move to table 3 →
/// half in cash, rest by card → back to the tables, table free.
void main() {
  testWidgets('table service: open, move, split payment, table free again', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi()..withFloor();
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
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await loginAsAhmed(tester);
    await settle();

    // Tables screen: Salle (1–4) and Terrasse tabs, all free.
    expect(find.text('0 table occupée'), findsOneWidget);
    expect(find.text('Salle (0/4)'), findsOneWidget);
    expect(find.text('Terrasse (0/1)'), findsOneWidget);

    // Table 2 → order 2 Express.
    await tester.tap(find.byKey(const Key('table-table-2')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-title'))).data, 'Table 2');
    for (var i = 0; i < 20 && find.byKey(const Key('product-p1')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-total'))).data, '2.400 DT');

    // Back to the tables: table 2 is busy with 2.400 DT; the counter is still empty.
    await tester.tap(find.byKey(const Key('back-to-floor')));
    await settle();
    expect(find.text('1 table occupée'), findsOneWidget);
    expect(find.text('2.400 DT'), findsOneWidget);
    await tester.tap(find.byKey(const Key('counter-tile')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-title'))).data, 'Comptoir');
    expect(find.text('Touchez un produit pour commencer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-to-floor')));
    await settle();

    // Customers change table: 2 → 3.
    await tester.tap(find.byKey(const Key('table-table-2')));
    await settle();
    await tester.tap(find.byKey(const Key('move-ticket')));
    await settle();
    expect(find.byKey(const Key('move-to-table-2')), findsNothing); // its own table isn't offered
    await tester.tap(find.byKey(const Key('move-to-table-3')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-title'))).data, 'Table 3');

    // Pay half in cash (exact)…
    await tester.tap(find.byKey(const Key('pay-cash')));
    await settle();
    await tester.tap(find.byKey(const Key('pay-mode-share')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('pay-amount'))).data, 'À payer maintenant : 1.200 DT');
    await tester.tap(find.byKey(const Key('cash-confirm')));
    await settle();
    expect(tester.widget<Text>(find.byKey(const Key('ticket-remaining'))).data, '1.200 DT');
    expect(find.byKey(const Key('cancel-order')), findsNothing); // partly paid → can't cancel

    // …and the rest by card → ticket closed → back to the tables, all free.
    await tester.tap(find.byKey(const Key('pay-cash')));
    await settle();
    await tester.tap(find.byKey(const Key('pay-method-card')));
    await settle();
    await tester.tap(find.byKey(const Key('cash-confirm')));
    await settle();
    expect(find.text('0 table occupée'), findsOneWidget);
    expect(find.byKey(const Key('ticket-title')), findsNothing);

    // What the backend receives.
    final all = await tester.runAsync(
      () async => [
        ...api.pushed.values,
        for (final e in await db.select(db.outboxEvents).get()) {'type': e.type, 'payload': jsonDecode(e.payloadJson)},
      ],
    );
    Iterable<Map> ofType(String t) => all!.where((e) => e['type'] == t).map((e) => e['payload'] as Map);
    expect(ofType('order.opened').single, {'type': 'table', 'tableId': 'table-2', 'tableName': '2'});
    expect(ofType('order.table_changed').single, {'tableId': 'table-3', 'tableName': '3'});
    expect(ofType('payment.added').map((p) => (p['method'], p['amount'])), [('cash', 1200), ('card', 1200)]);
    expect(ofType('order.closed').single['total'], 2400);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
