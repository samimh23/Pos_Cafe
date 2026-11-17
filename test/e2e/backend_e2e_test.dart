// End-to-end against a REAL running backend. Skipped unless E2E_PAIR_CODE is set.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm db:seed && pnpm dev
//   E2E_PAIR_CODE=<POS pairing code from the seed> flutter test test/e2e
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';

void main() {
  final code = Platform.environment['E2E_PAIR_CODE'];
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test('pair → pull menu → record events → push → second sync', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final secrets = MemorySecretStore();
    final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
    final devices = DeviceRepository(db, secrets, api);
    final outbox = OutboxRepository(db);

    final identity = await devices.pair(code: code!, name: 'Test E2E');
    // ignore: avoid_print
    print('paired as ${identity.deviceCode} (${identity.role})');
    await devices.checkWithServer();

    final engine = SyncEngine(db, api, outbox, identity);
    final changes = await engine.pullMenu();
    final products = await db.select(db.products).get();
    // ignore: avoid_print
    print('menu: $changes rows, ${products.length} products, e.g. ${products.first.name} ${products.first.price}');
    expect(products, isNotEmpty);

    for (var i = 0; i < 3; i++) {
      await outbox.record(type: 'debug.test', entityId: identity.deviceId, payload: {'i': i});
    }
    final pushed = await engine.pushPending();
    expect(pushed.pushed, 3);
    expect(await outbox.pending(), isEmpty);

    // Second sync with nothing new: still fine, menu cursor works.
    final second = await engine.syncNow();
    expect(second.pushed, 0);
    expect(second.menuChanges, 0);

    await db.close();
  }, skip: code == null ? 'set E2E_PAIR_CODE to run against a real backend' : false);
}
