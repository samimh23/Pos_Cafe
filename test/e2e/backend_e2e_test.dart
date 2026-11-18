// End-to-end against a REAL running backend. Skipped unless E2E_PAIR_CODE is set.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm db:seed && pnpm dev
//   E2E_PAIR_CODE=<POS pairing code from the seed> flutter test test/e2e
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../order_helpers.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

void main() {
  final code = Platform.environment['E2E_PAIR_CODE'];
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'pair → pull menu → record events → push → second sync',
    () async {
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

      // A real order: 2 × first product + 1 × second, paid cash.
      final orders = OrderRepository(db, outbox);
      await orders.addProduct(products[0]);
      await orders.addProduct(products[0]);
      await orders.addProduct(products[1]);
      final paid = await orders.payCounterCash(tendered: const Money.dt(50), deviceCode: identity.deviceCode);
      // ignore: avoid_print
      print('paid ${paid.receiptNumber}: total ${paid.total}, change ${paid.change}');

      final pending = (await outbox.pending()).length;
      final pushed = await engine.pushPending();
      // ignore: avoid_print
      print('pushed ${pushed.pushed} events');
      expect(pushed.pushed, pending);
      expect(await outbox.pending(), isEmpty);

      // Second sync with nothing new: still fine, menu cursor works.
      final second = await engine.syncNow();
      expect(second.pushed, 0);
      expect(second.menuChanges, 0);

      await db.close();
    },
    skip: code == null ? 'set E2E_PAIR_CODE to run against a real backend' : false,
  );
}
