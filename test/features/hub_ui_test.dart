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

/// What a server tablet and the main POS show, in the real UI.
void main() {
  Future<(AppDatabase, FakePosApi)> start(
    WidgetTester tester, {
    required String role,
    bool canPay = false,
    bool replaced = false,
  }) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi()..withFloor();
    api.lan = {
      'lanKey': 'k',
      // An address nobody answers on: the Hub is "off".
      'hub': {
        'deviceId': 'hub-1',
        'code': 'T1',
        'addresses': ['10.255.255.1'],
        'port': 7799,
      },
      'devices': [
        {'id': 'hub-1', 'code': 'T1', 'name': 'Caisse', 'role': 'hub', 'canTakePayments': true, 'disabled': false},
        {'id': 'dev-2', 'code': 'T2', 'name': 'Tablette', 'role': 'pos', 'canTakePayments': canPay, 'disabled': false},
      ],
    };
    if (replaced) {
      api.lan = {
        'lanKey': 'k',
        'hub': {
          'deviceId': 'hub-9',
          'code': 'T9',
          'addresses': ['10.255.255.1'],
          'port': 7799,
        },
        'devices': [
          {'id': 'hub-1', 'code': 'T1', 'name': 'Ancien PC', 'role': 'pos', 'canTakePayments': true, 'disabled': false},
          {
            'id': 'hub-9',
            'code': 'T9',
            'name': 'Nouveau PC',
            'role': 'hub',
            'canTakePayments': true,
            'disabled': false,
          },
        ],
      };
    }
    await secrets.write(SecretKeys.deviceToken, 'token');
    final id = role == 'hub' ? 'hub-1' : 'dev-2';
    await tester.runAsync(
      () => db.setKv(
        'device_identity',
        '{"deviceId":"$id","deviceCode":"T2","role":"$role","tenantId":"t","branchId":"b","name":"Tablette"}',
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
    await loginAsAhmed(tester);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return (db, api);
  }

  Future<void> end(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox());
    // Lets the tablet's 3-second connection attempt time out (fake clock).
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(db.close);
  }

  testWidgets('server tablet: Hub off → clear warning; no counter; "Demander l’addition" instead of paying', (
    tester,
  ) async {
    final (db, _) = await start(tester, role: 'pos');

    expect(find.byKey(const Key('hub-banner')), findsOneWidget);
    expect(find.byKey(const Key('hub-link-chip')), findsOneWidget);
    expect(find.text('T1 injoignable'), findsOneWidget);
    expect(find.byKey(const Key('role-badge-secondaire')), findsOneWidget);
    expect(find.byKey(const Key('counter-tile')), findsNothing);

    await tester.tap(find.byKey(const Key('table-table-1')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('pay-cash')), findsNothing);
    expect(find.byKey(const Key('request-bill')), findsOneWidget);
    expect(find.byKey(const Key('hub-banner')), findsOneWidget);
    await end(tester, db);
  });

  testWidgets('server tablet allowed to take payments (terrace): the pay button is there', (tester) async {
    final (db, _) = await start(tester, role: 'pos', canPay: true);
    await tester.tap(find.byKey(const Key('table-table-1')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('pay-cash')), findsOneWidget);
    expect(find.byKey(const Key('request-bill')), findsNothing);
    await end(tester, db);
  });

  testWidgets('main POS: PRINCIPALE badge, "Aucune tablette connectée", counter, no warning', (tester) async {
    final (db, _) = await start(tester, role: 'hub');
    expect(find.text('Aucune tablette connectée'), findsOneWidget);
    expect(find.byKey(const Key('role-badge-principale')), findsOneWidget);
    expect(find.byKey(const Key('hub-banner')), findsNothing);
    expect(find.byKey(const Key('counter-tile')), findsOneWidget);
    await end(tester, db);
  });

  testWidgets('old main POS replaced by a new one → shows SECONDAIRE and connects to the new one (T9)', (tester) async {
    final (db, _) = await start(tester, role: 'hub', replaced: true);
    expect(find.byKey(const Key('role-badge-secondaire')), findsOneWidget);
    expect(find.byKey(const Key('role-badge-principale')), findsNothing);
    expect(find.text('T9 injoignable'), findsOneWidget);
    expect(find.byKey(const Key('hub-chip')), findsNothing);
    await end(tester, db);
  });
}
