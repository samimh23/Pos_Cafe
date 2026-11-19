import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/app/app.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/providers.dart';
import 'package:pos_cafe/features/print/print_providers.dart';

import '../fake_printer.dart';
import '../fakes.dart';
import 'staff_login_helper.dart';

/// In the real UI: set the printer (⋮ → Imprimantes, Tester), send a table's order to
/// the bar, pay → the customer receipt prints by itself.
void main() {
  testWidgets('printers: test page, Envoyer to the bar, automatic receipt', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final secrets = MemorySecretStore();
    final api = FakePosApi()..withFloor();
    final printer = FakePrinter();
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
          printerTransportProvider.overrideWithValue(printer),
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

    await loginAsAhmed(tester);
    await settle();

    // ⋮ → Imprimantes: one printer at the counter, test page, save.
    await tester.tap(find.byKey(const Key('pos-menu')));
    await settle();
    await tester.tap(find.text('Imprimantes'));
    await settle();
    await tester.enterText(find.byKey(const Key('printer-receipt-host')), '192.168.1.50');
    await tester.tap(find.byKey(const Key('printer-receipt-test')));
    await io();
    await settle();
    expect(printer.texts.single, contains('test d’impression'.replaceAll('’', "'")));
    await tester.tap(find.byKey(const Key('printers-save')));
    await io();
    await settle();
    await tester.pageBack();
    await settle();

    // Table 2: 2 Express → "Envoyer au bar / cuisine (2)".
    await tester.tap(find.byKey(const Key('table-table-2')));
    await settle();
    for (var i = 0; i < 20 && find.byKey(const Key('product-p1')).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    await tester.tap(find.byKey(const Key('product-p1')));
    await settle();
    expect(find.text('Envoyer au bar / cuisine (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('send-order')));
    await io();
    await settle();
    final bar = printer.texts.last;
    expect(bar, contains('BAR'));
    expect(bar, contains('TABLE 2'));
    expect(bar, contains('2 X EXPRESS'));
    expect(find.byKey(const Key('send-order')), findsNothing); // nothing left to send
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // ✓ on the line

    // Pay (opens the drawer first) → the receipt prints by itself.
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
    final receipt = printer.texts.last;
    expect(receipt, contains('Ticket T1-000001'));
    expect(receipt, contains("SAMI'S COFFE"));
    expect(receipt, contains('TOTAL 2.400 DT'));

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
