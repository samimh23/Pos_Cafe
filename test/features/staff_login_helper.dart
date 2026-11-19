import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Waits for the staff list to sync, taps Ahmed, types 1234 and presses OK.
Future<void> loginAsAhmed(WidgetTester tester, {String pin = '1234'}) => loginAs(tester, 'staff-ahmed', pin: pin);

/// Same for any staff member of the fake server (they all use PIN 1234 in tests).
Future<void> loginAs(WidgetTester tester, String staffId, {String pin = '1234'}) async {
  final tile = find.byKey(Key('staff-$staffId'));
  for (var i = 0; i < 40 && tile.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('Qui êtes-vous ?'), findsOneWidget);
  await tester.tap(tile);
  await tester.pump();
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-$d')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('pin-ok')));
  // The PIN check runs real crypto (PBKDF2), outside the fake clock.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
