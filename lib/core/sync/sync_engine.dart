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
  Future<int> pullMenu() async {
    final res = await _api.pull(await _db.getKv(_cursorKey));
    await _db.transaction(() async {
      await _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.categories, [
          for (final c in res.categories)
            CategoriesCompanion.insert(
              id: c['id'],
              name: c['name'],
              sortOrder: Value(c['sortOrder'] as int),
              color: Value(c['color'] as String?),
            ),
        ]);
        b.insertAllOnConflictUpdate(_db.products, [
          for (final p in res.products)
            ProductsCompanion.insert(
              id: p['id'],
              categoryId: p['categoryId'],
              name: p['name'],
              price: p['price'] as int,
              vatRateBp: Value(p['vatRateBp'] as int),
              station: Value(p['station'] as String),
              modifierGroupsJson: Value(jsonEncode(p['modifierGroups'] ?? const [])),
              available: Value(p['available'] as bool),
            ),
        ]);
      });
      await _db.setKv(_cursorKey, res.cursor);
    });
    return res.categories.length + res.products.length;
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
