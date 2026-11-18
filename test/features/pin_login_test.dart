import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/providers.dart';
import 'package:pos_cafe/features/staff_login/view_model/pin_login_view_model.dart';
import 'package:pos_cafe/features/staff_login/view_model/staff_session.dart';

import '../fakes.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late StaffRow ahmed;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ahmed = const StaffRow(id: 'staff-ahmed', name: 'Ahmed', role: 'server', pinHash: ahmedPinHash);
    await db.into(db.staffMembers).insert(ahmed);
    c = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    c.listen(staffSessionProvider, (_, _) {});
    await c.read(staffListProvider.future);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  PinLoginViewModel vm() => c.read(pinLoginViewModelProvider.notifier);
  PinLoginState state() => c.read(pinLoginViewModelProvider);
  Future<void> type(String pin) async {
    for (final d in pin.split('')) {
      vm().digit(d);
    }
    await vm().submit();
  }

  test('right PIN → session starts, pad resets', () async {
    vm().select(ahmed);
    await type('1234');
    expect(c.read(staffSessionProvider)?.name, 'Ahmed');
    expect(state().selected, isNull);
    expect(state().pin, '');
  });

  test('wrong PIN → French error with tries left, PIN cleared, still nobody logged in', () async {
    vm().select(ahmed);
    await type('9999');
    expect(state().error, 'Code incorrect. Encore 4 essais.');
    expect(state().pin, '');
    expect(c.read(staffSessionProvider), isNull);
  });

  test('5 wrong PINs → locked message', () async {
    vm().select(ahmed);
    for (var i = 0; i < 5; i++) {
      await type('9999');
    }
    expect(state().error, 'Trop d’essais. Réessayez dans 1 minute.');
    expect(state().lockedUntil, isNotNull);
  });

  test('too short → hint, no check; max 6 digits; erase works', () async {
    vm().select(ahmed);
    await type('12');
    expect(state().error, 'Le code fait 4 à 6 chiffres.');
    for (final d in '12345678'.split('')) {
      vm().digit(d);
    }
    expect(state().pin, '121234'); // capped at 6
    vm().erase();
    expect(state().pin, '12123');
  });

  test('logout records the event and ends the session', () async {
    vm().select(ahmed);
    await type('1234');
    await c.read(staffSessionProvider.notifier).logout();
    expect(c.read(staffSessionProvider), isNull);
    final types = [for (final e in await db.select(db.outboxEvents).get()) e.type];
    expect(types, containsAllInOrder(['staff.logged_in', 'staff.logged_out']));
  });
}
