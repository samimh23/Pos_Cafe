import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The POS local database (SQLite). The UI reads from it; sync fills and empties it.
@DriftDatabase(tables: [KvEntries, Categories, Products, OutboxEvents, Orders, OrderLines, Payments, StaffMembers, FloorAreas, DiningTables])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'pos_cafe'));

  /// Bump when tables change, and add the upgrade step below.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: sales tables
        await m.createTable(orders);
        await m.createTable(orderLines);
        await m.createTable(payments);
      }
      if (from < 3) {
        // v3: product order chosen by the owner
        await m.addColumn(products, products.sortOrder);
      }
      if (from < 4) {
        // v4: staff PIN login
        await m.createTable(staffMembers);
      }
      if (from < 5) {
        // v5: rooms and tables, several open tickets, split payments
        await m.createTable(floorAreas);
        await m.createTable(diningTables);
        // Before v2 the sales tables didn't exist: created above WITH these columns.
        if (from >= 2) {
          await m.addColumn(orders, orders.tableId);
          await m.addColumn(orderLines, orderLines.paymentId);
        }
      }
    },
  );

  // ── Key/value helpers ──────────────────────────────────

  Future<String?> getKv(String key) async =>
      (await (select(kvEntries)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setKv(String key, String value) =>
      into(kvEntries).insertOnConflictUpdate(KvEntriesCompanion.insert(key: key, value: value));

  Future<void> deleteKv(String key) => (delete(kvEntries)..where((t) => t.key.equals(key))).go();
}
