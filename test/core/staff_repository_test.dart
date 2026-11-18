import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/staff/staff_repository.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';

import '../fakes.dart';
import 'sync_engine_test.dart' show identity;

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late StaffRepository staffRepo;
  late DateTime now;
  late FakePosApi api;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    now = DateTime.utc(2026, 11, 18, 9);
    staffRepo = StaffRepository(db, outbox, clock: () => now);
    api = FakePosApi();
    await SyncEngine(db, api, outbox, identity).pullMenu(); // brings Ahmed (PIN 1234)
  });
  tearDown(() => db.close());

  Future<StaffRow> ahmed() => (db.select(db.staffMembers)..where((t) => t.name.equals('Ahmed'))).getSingle();

  test('sync brings staff with the PIN hash; right PIN logs in and records an event', () async {
    final a = await ahmed();
    expect(a.role, 'server');

    final r = await staffRepo.login(a, '1234');
    expect(r, isA<PinOk>());
    final ev = (await outbox.pending()).last;
    expect((ev.type, ev.staffId), ('staff.logged_in', a.id));
  });

  test('wrong PIN counts down, then locks for 60 s — even the right PIN is refused while locked', () async {
    final a = await ahmed();
    for (var left = 4; left >= 1; left--) {
      expect(await staffRepo.login(a, '0000'), isA<PinWrong>().having((w) => w.remaining, 'remaining', left));
    }
    expect(await staffRepo.login(a, '0000'), isA<PinLocked>());
    expect(await staffRepo.login(a, '1234'), isA<PinLocked>());
    expect((await outbox.pending()).map((e) => e.type), contains('staff.pin_locked'));

    // The lock survives an app restart (saved in the DB)…
    final afterRestart = StaffRepository(db, outbox, clock: () => now);
    expect(await afterRestart.login(a, '1234'), isA<PinLocked>());

    // …and ends after 60 s.
    now = now.add(const Duration(seconds: 61));
    expect(await staffRepo.login(a, '1234'), isA<PinOk>());
  });

  test('a good login resets the wrong-PIN counter', () async {
    final a = await ahmed();
    await staffRepo.login(a, '0000');
    await staffRepo.login(a, '0000');
    expect(await staffRepo.login(a, '1234'), isA<PinOk>());
    expect(await staffRepo.login(a, '0000'), isA<PinWrong>().having((w) => w.remaining, 'remaining', 4));
  });

  test('owner deactivates someone → removed from this POS on the next sync', () async {
    api.changedStaff = [
      {...api.staff.first, 'active': false},
    ];
    await SyncEngine(db, api, outbox, identity).pullMenu();
    expect(await db.select(db.staffMembers).get(), isEmpty);
  });

  test('owner changes the PIN → the new hash is used at the next login', () async {
    final a = await ahmed();
    api.changedStaff = [
      {...api.staff.first, 'pinHash': 'pbkdf2-sha256\$1000\$a2Fod3RpLXRlc3Qtc2FsdA\$AAAA', 'active': true},
    ];
    await SyncEngine(db, api, outbox, identity).pullMenu();
    expect(await staffRepo.login(a, '1234'), isA<PinWrong>()); // old PIN no longer works
  });

  test('invalid PIN shapes are rejected without checking', () async {
    expect(await staffRepo.login(await ahmed(), '12'), isA<PinWrong>());
    expect(jsonDecode((await db.getKv('pin_lock_staff-ahmed'))!)['failures'], 1);
  });
}
