import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';

import '../fakes.dart';

const identity = DeviceIdentity(
  deviceId: 'dev-1',
  deviceCode: 'T1',
  role: 'hub',
  tenantId: 'tenant-1',
  branchId: 'branch-1',
  name: 'Caisse',
);

void main() {
  late AppDatabase db;
  late OutboxRepository outbox;
  late FakePosApi api;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxRepository(db);
    api = FakePosApi();
    engine = SyncEngine(db, api, outbox, identity);
  });
  tearDown(() => db.close());

  test('push sends events with device/branch ids and empties the outbox', () async {
    await outbox.record(type: 'order.opened', entityId: 'o1', payload: {'table': 'T5'});
    await outbox.record(type: 'order.closed', entityId: 'o1', payload: {'total': 2400});

    final r = await engine.pushPending();

    expect(r.pushed, 2);
    expect(await outbox.pending(), isEmpty);
    final sent = api.pushed.values.toList();
    expect(sent.map((e) => e['deviceSeq']), [1, 2]);
    expect(sent.first['deviceId'], 'dev-1');
    expect(sent.first['branchId'], 'branch-1');
    expect(sent.first['payload'], {'table': 'T5'});
  });

  test('offline: events stay in the outbox, nothing lost', () async {
    await outbox.record(type: 'order.opened', entityId: 'o1', payload: {});
    api.failWith = const ApiException('NETWORK', 'Server unreachable');

    await expectLater(engine.pushPending(), throwsA(isA<ApiException>()));
    expect(await outbox.pending(), hasLength(1));

    api.failWith = null; // internet back
    await engine.pushPending();
    expect(await outbox.pending(), isEmpty);
  });

  test('rejected events are kept but not retried', () async {
    final bad = await outbox.record(type: 'order.opened', entityId: 'o1', payload: {});
    await outbox.record(type: 'order.opened', entityId: 'o2', payload: {});
    api.rejectIds = {bad.id};

    final r = await engine.pushPending();
    expect(r.pushed, 1);
    expect(r.rejected, 1);
    expect(await outbox.pending(), isEmpty);
    final row = await (db.select(db.outboxEvents)..where((t) => t.id.equals(bad.id))).getSingle();
    expect(row.rejectedCode, 'WRONG_DEVICE_OR_BRANCH');
  });

  test('push in batches of 500', () async {
    for (var i = 0; i < 1203; i++) {
      await outbox.record(type: 'debug.test', entityId: 'e', payload: {'i': i});
    }
    final r = await engine.pushPending();
    expect(r.pushed, 1203);
    expect(api.pushed, hasLength(1203));
  });

  test('pull saves the menu and the cursor; next pull asks only for changes', () async {
    final changes = await engine.pullMenu();
    expect(changes, 2);
    expect((await db.select(db.categories).get()).single.name, 'Boissons chaudes');
    final p = (await db.select(db.products).get()).single;
    expect((p.name, p.price, p.vatRateBp), ('Express', 1200, 1900));
    expect(await db.getKv('pull_cursor'), '2026-11-17T10:00:00.000Z');

    expect(await engine.pullMenu(), 0);
  });

  test('pull updates an existing product (price change)', () async {
    await engine.pullMenu();
    await db.deleteKv('pull_cursor');
    api.products.first['price'] = 1300;
    await engine.pullMenu();
    expect((await db.select(db.products).getSingle()).price, 1300);
  });

  test('owner deletions reach the POS: deleted product and category are removed', () async {
    api.products.add({...api.products.first, 'id': 'p2', 'name': 'Thé', 'sortOrder': 2});
    await engine.pullMenu();
    expect(await db.select(db.products).get(), hasLength(2));

    api.changedProducts = [
      {...api.products.first, 'price': 1400, 'deleted': false},
      {...api.products.last, 'deleted': true},
    ];
    await engine.pullMenu();
    final left = await db.select(db.products).get();
    expect(left.map((p) => (p.name, p.price)), [('Express', 1400)]);

    api.changedProducts = [
      {...api.products.first, 'deleted': true},
    ];
    api.changedCategories = [
      {...api.categories.first, 'deleted': true},
    ];
    await engine.pullMenu();
    expect(await db.select(db.products).get(), isEmpty);
    expect(await db.select(db.categories).get(), isEmpty);
  });

  test('product order from the owner is saved', () async {
    api.products.first['sortOrder'] = 7;
    await engine.pullMenu();
    expect((await db.select(db.products).getSingle()).sortOrder, 7);
  });
}
