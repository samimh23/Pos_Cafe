import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../ids.dart';

/// Records events and gives them to the sync engine.
///
/// Feature repositories call [record] INSIDE their own transaction
/// (`db.transaction(() async { …change data…; await outbox.record(…); })`),
/// so the data change and its event are saved together or not at all.
class OutboxRepository {
  OutboxRepository(this._db);
  final AppDatabase _db;

  static const _lastSeqKey = 'last_seq';

  Future<OutboxRow> record({
    required String type,
    required String entityId,
    required Map<String, Object?> payload,
    String? staffId,
    String? approvedBy,
    DateTime? now,
  }) {
    return _db.transaction(() async {
      final seq = (int.tryParse(await _db.getKv(_lastSeqKey) ?? '') ?? 0) + 1;
      await _db.setKv(_lastSeqKey, '$seq');
      return _db
          .into(_db.outboxEvents)
          .insertReturning(
            OutboxEventsCompanion.insert(
              id: newId(),
              type: type,
              entityId: entityId,
              deviceSeq: seq,
              occurredAt: (now ?? DateTime.now()).toUtc(),
              staffId: Value(staffId),
              approvedBy: Value(approvedBy),
              payloadJson: jsonEncode(payload),
            ),
          );
    });
  }

  /// Oldest events first, excluding the ones the server refused.
  Future<List<OutboxRow>> pending({int limit = 500}) =>
      (_db.select(_db.outboxEvents)
            ..where((t) => t.rejectedCode.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.deviceSeq)])
            ..limit(limit))
          .get();

  /// After the server confirms them.
  Future<void> remove(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await (_db.delete(_db.outboxEvents)..where((t) => t.id.isIn(list))).go();
  }

  Future<void> markRejected(Map<String, String> codeById) => _db.batch((b) {
    for (final e in codeById.entries) {
      b.update(_db.outboxEvents, OutboxEventsCompanion(rejectedCode: Value(e.value)), where: (t) => t.id.equals(e.key));
    }
  });

  /// Live count for the status bar ("12 en attente").
  Stream<int> watchPendingCount() {
    final count = _db.outboxEvents.id.count();
    return (_db.selectOnly(_db.outboxEvents)
          ..addColumns([count])
          ..where(_db.outboxEvents.rejectedCode.isNull()))
        .map((r) => r.read(count) ?? 0)
        .watchSingle();
  }
}
