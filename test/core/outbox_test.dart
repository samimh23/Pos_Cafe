import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
  });
  tearDown(() => db.close());

  test('sequence increases 1, 2, 3 and survives across calls', () async {
    for (var i = 0; i < 3; i++) {
      await outbox.record(type: 'order.opened', entityId: 'o$i', payload: {'i': i});
    }
    final rows = await outbox.pending();
    expect(rows.map((r) => r.deviceSeq), [1, 2, 3]);
    expect(await db.getKv('last_seq'), '3');
  });

  test('remove and reject', () async {
    final a = await outbox.record(type: 'a.b', entityId: 'x', payload: {});
    final b = await outbox.record(type: 'a.b', entityId: 'x', payload: {});
    final c = await outbox.record(type: 'a.b', entityId: 'x', payload: {});

    await outbox.remove([a.id]);
    await outbox.markRejected({b.id: 'WRONG_DEVICE_OR_BRANCH'});

    expect((await outbox.pending()).map((r) => r.id), [c.id]);
    expect(await outbox.watchPendingCount().first, 1);
  });

  test('event and data change roll back together', () async {
    await expectLater(
      db.transaction(() async {
        await outbox.record(type: 'a.b', entityId: 'x', payload: {});
        throw StateError('crash in the middle');
      }),
      throwsStateError,
    );
    expect(await outbox.pending(), isEmpty);
    expect(await db.getKv('last_seq'), isNull);
  });
}
