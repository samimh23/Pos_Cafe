import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/pos_api.dart';
import '../db/app_database.dart';
import '../device/device_repository.dart';
import 'outbox_repository.dart';

class SyncResult {
  final int pushed;
  final int rejected;
  final int menuChanges;
  const SyncResult({this.pushed = 0, this.rejected = 0, this.menuChanges = 0});
}

/// Moves data between the local DB and the cloud. Never called by the UI directly —
/// the SyncController runs it in the background.
class SyncEngine {
  SyncEngine(this._db, this._api, this._outbox, this._identity);

  final AppDatabase _db;
  final PosApi _api;
  final OutboxRepository _outbox;
  final DeviceIdentity _identity;

  static const _cursorKey = 'pull_cursor';
  static const batchSize = 500;

  Future<SyncResult> syncNow() async {
    final push = await pushPending();
    final menu = await pullMenu();
    return SyncResult(pushed: push.pushed, rejected: push.rejected, menuChanges: menu);
  }

  /// Sends the outbox in batches until it is empty.
  Future<SyncResult> pushPending() async {
    var pushed = 0, rejected = 0;
    while (true) {
      final batch = await _outbox.pending(limit: batchSize);
      if (batch.isEmpty) break;

      final res = await _api.push([for (final e in batch) _toJson(e)]);
      await _outbox.remove(res.accepted);
      await _outbox.markRejected(res.rejected);
      pushed += res.accepted.length;
      rejected += res.rejected.length;

      if (batch.length < batchSize) break;
    }
    return SyncResult(pushed: pushed, rejected: rejected);
  }

  /// Gets menu changes since the last cursor and saves them locally.
  /// Items the owner deleted come with `deleted: true` and are removed here.
  /// (Past orders keep their own copy of name and price, so they are not affected.)
  Future<int> pullMenu() async {
    final res = await _api.pull(await _db.getKv(_cursorKey));
    bool isDeleted(Map<String, dynamic> row) => row['deleted'] == true;

    await _db.transaction(() async {
      await _db.batch((b) {
        final goneProducts = [
          for (final p in res.products)
            if (isDeleted(p)) p['id'] as String,
        ];
        final goneCategories = [
          for (final c in res.categories)
            if (isDeleted(c)) c['id'] as String,
        ];
        if (goneProducts.isNotEmpty) b.deleteWhere(_db.products, (t) => t.id.isIn(goneProducts));
        if (goneCategories.isNotEmpty) b.deleteWhere(_db.categories, (t) => t.id.isIn(goneCategories));

        // Staff: active → upsert, deactivated → remove (can no longer log in here).
        final goneStaff = [
          for (final st in res.staff)
            if (st['active'] != true) st['id'] as String,
        ];
        if (goneStaff.isNotEmpty) b.deleteWhere(_db.staffMembers, (t) => t.id.isIn(goneStaff));
        b.insertAllOnConflictUpdate(_db.staffMembers, [
          for (final st in res.staff)
            if (st['active'] == true)
              StaffMembersCompanion.insert(id: st['id'], name: st['name'], role: st['role'], pinHash: st['pinHash']),
        ]);

        // Rooms and tables: same rules as the menu.
        final goneAreas = [
          for (final a in res.areas)
            if (isDeleted(a)) a['id'] as String,
        ];
        final goneTables = [
          for (final t in res.tables)
            if (isDeleted(t)) t['id'] as String,
        ];
        if (goneTables.isNotEmpty) b.deleteWhere(_db.diningTables, (t) => t.id.isIn(goneTables));
        if (goneAreas.isNotEmpty) b.deleteWhere(_db.floorAreas, (t) => t.id.isIn(goneAreas));
        b.insertAllOnConflictUpdate(_db.floorAreas, [
          for (final a in res.areas)
            if (!isDeleted(a))
              FloorAreasCompanion.insert(id: a['id'], name: a['name'], sortOrder: Value((a['sortOrder'] as int?) ?? 0)),
        ]);
        b.insertAllOnConflictUpdate(_db.diningTables, [
          for (final t in res.tables)
            if (!isDeleted(t))
              DiningTablesCompanion.insert(
                id: t['id'],
                areaId: t['areaId'],
                name: t['name'],
                seats: Value((t['seats'] as int?) ?? 4),
                sortOrder: Value((t['sortOrder'] as int?) ?? 0),
              ),
        ]);

        b.insertAllOnConflictUpdate(_db.categories, [
          for (final c in res.categories)
            if (!isDeleted(c))
              CategoriesCompanion.insert(
                id: c['id'],
                name: c['name'],
                sortOrder: Value(c['sortOrder'] as int),
                color: Value(c['color'] as String?),
              ),
        ]);
        b.insertAllOnConflictUpdate(_db.products, [
          for (final p in res.products)
            if (!isDeleted(p))
              ProductsCompanion.insert(
                id: p['id'],
                categoryId: p['categoryId'],
                name: p['name'],
                price: p['price'] as int,
                vatRateBp: Value(p['vatRateBp'] as int),
                station: Value(p['station'] as String),
                modifierGroupsJson: Value(jsonEncode(p['modifierGroups'] ?? const [])),
                available: Value(p['available'] as bool),
                sortOrder: Value((p['sortOrder'] as int?) ?? 0),
              ),
        ]);
      });
      await _db.setKv(_cursorKey, res.cursor);
    });
    return res.categories.length + res.products.length + res.staff.length + res.areas.length + res.tables.length;
  }

  Map<String, Object?> _toJson(OutboxRow e) => {
    'id': e.id,
    'type': e.type,
    'version': e.version,
    'branchId': _identity.branchId,
    'deviceId': _identity.deviceId,
    'staffId': e.staffId,
    'entityId': e.entityId,
    'deviceSeq': e.deviceSeq,
    'occurredAt': e.occurredAt.toUtc().toIso8601String(),
    'approvedBy': e.approvedBy,
    'payload': jsonDecode(e.payloadJson),
  };
}
