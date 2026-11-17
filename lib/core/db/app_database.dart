import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The POS local database (SQLite). The UI reads from it; sync fills and empties it.
@DriftDatabase(tables: [KvEntries, Categories, Products, OutboxEvents])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'pos_cafe'));

  @override
  int get schemaVersion => 1;

  // ── Key/value helpers ──────────────────────────────────

  Future<String?> getKv(String key) async =>
      (await (select(kvEntries)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setKv(String key, String value) =>
      into(kvEntries).insertOnConflictUpdate(KvEntriesCompanion.insert(key: key, value: value));

  Future<void> deleteKv(String key) => (delete(kvEntries)..where((t) => t.key.equals(key))).go();
}
