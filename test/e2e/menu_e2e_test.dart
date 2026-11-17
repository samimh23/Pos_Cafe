// End-to-end against a REAL running backend: the owner edits the menu, the POS follows.
// Skipped unless E2E_MENU=1.
//
//   cd backend-platform && pnpm db:up && pnpm db:migrate && pnpm dev
//   E2E_MENU=1 flutter test test/e2e/menu_e2e_test.dart
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/api/pos_api.dart';
import 'package:pos_cafe/core/db/app_database.dart';
import 'package:pos_cafe/core/device/device_repository.dart';
import 'package:pos_cafe/core/device/secret_store.dart';
import 'package:pos_cafe/core/sync/outbox_repository.dart';
import 'package:pos_cafe/core/sync/sync_engine.dart';

void main() {
  final url = Platform.environment['E2E_API_URL'] ?? 'http://localhost:3000';

  test(
    'owner builds menu → POS pulls → owner edits + deletes → POS follows',
    () async {
      // ── Owner (what the Next.js app will do) ──
      final owner = Dio(BaseOptions(baseUrl: url));
      final signup =
          (await owner.post(
            '/v1/auth/signup',
            data: {
              'email': 'e2e${DateTime.now().millisecondsSinceEpoch}@example.com',
              'password': 'correct horse battery',
              'name': 'Owner',
              'businessName': 'Café E2E',
            },
          )).data;
      owner.options.headers['authorization'] = 'Bearer ${signup['accessToken']}';
      final branch = signup['branches'][0]['id'];

      final cat = (await owner.post('/v1/owner/branches/$branch/categories', data: {'name': 'Boissons'})).data;
      final express =
          (await owner.post(
            '/v1/owner/branches/$branch/products',
            data: {'categoryId': cat['id'], 'name': 'Express', 'price': 1200, 'sortOrder': 1},
          )).data;
      final tea =
          (await owner.post(
            '/v1/owner/branches/$branch/products',
            data: {'categoryId': cat['id'], 'name': 'Thé', 'price': 1800, 'sortOrder': 2},
          )).data;
      final code = (await owner.post('/v1/owner/branches/$branch/pairing-codes', data: {'role': 'hub'})).data['code'];

      // ── POS (real Flutter code) ──
      final db = AppDatabase(NativeDatabase.memory());
      final secrets = MemorySecretStore();
      final api = DioPosApi(baseUrl: url, token: () => secrets.read(SecretKeys.deviceToken));
      final identity = await DeviceRepository(db, secrets, api).pair(code: code, name: 'Caisse');
      final engine = SyncEngine(db, api, OutboxRepository(db), identity);

      await engine.pullMenu();
      Future<List<(String, int)>> menu() async => [
        for (final p in await (db.select(db.products)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get())
          (p.name, p.price),
      ];
      expect(await menu(), [('Express', 1200), ('Thé', 1800)]);
      // ignore: avoid_print
      print('POS menu after first pull: ${await menu()}');

      // ── Owner edits ──
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await owner.patch('/v1/owner/products/${express['id']}', data: {'price': 1300});
      await owner.delete('/v1/owner/products/${tea['id']}');

      // ── POS follows on its next sync ──
      await engine.pullMenu();
      expect(await menu(), [('Express', 1300)]);
      // ignore: avoid_print
      print('POS menu after owner edits: ${await menu()}');

      await db.close();
    },
    skip: Platform.environment['E2E_MENU'] == null ? 'set E2E_MENU=1 to run against a real backend' : false,
  );
}
