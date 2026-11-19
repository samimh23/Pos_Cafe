import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../sync/outbox_repository.dart';
import 'pin.dart';

sealed class PinResult {
  const PinResult();
}

class PinOk extends PinResult {
  final StaffRow staff;
  const PinOk(this.staff);
}

class PinWrong extends PinResult {
  /// Tries left before the lock.
  final int remaining;
  const PinWrong(this.remaining);
}

class PinLocked extends PinResult {
  final DateTime until;
  const PinLocked(this.until);
}

/// Staff login on the POS — works fully offline.
/// After [maxTries] wrong PINs a person is locked for [lockFor]. The counter is
/// saved in the local DB, so restarting the app does not reset it.
class StaffRepository {
  StaffRepository(this._db, this._outbox, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final OutboxRepository _outbox;
  final DateTime Function() _now;

  static const maxTries = 5;
  static const lockFor = Duration(seconds: 60);

  Stream<List<StaffRow>> watchStaff() =>
      (_db.select(_db.staffMembers)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  /// A manager approves a sensitive action (discount, cancellation, refund) with their
  /// PIN, on the spot. Same lockout as the login; nobody is logged in or out.
  Future<PinResult> approve(StaffRow manager, String pin) => _check(manager, pin, onSuccess: null);

  Future<PinResult> login(StaffRow staff, String pin) => _check(
    staff,
    pin,
    onSuccess:
        (current) => _outbox.record(
          type: 'staff.logged_in',
          entityId: current.id,
          staffId: current.id,
          payload: {'name': current.name},
        ),
  );

  Future<PinResult> _check(StaffRow staff, String pin, {required Future<void> Function(StaffRow)? onSuccess}) async {
    final key = 'pin_lock_${staff.id}';
    final state = _decode(await _db.getKv(key));
    final now = _now();
    if (state.lockedUntil != null && state.lockedUntil!.isAfter(now)) return PinLocked(state.lockedUntil!);

    // Read the latest hash (the owner may have changed the PIN since the list was shown).
    final current = await (_db.select(_db.staffMembers)..where((t) => t.id.equals(staff.id))).getSingleOrNull();
    if (current != null && isValidPin(pin) && await verifyPin(pin, current.pinHash)) {
      await _db.deleteKv(key);
      await onSuccess?.call(current);
      return PinOk(current);
    }

    final failures = state.failures + 1;
    if (failures >= maxTries) {
      final until = now.add(lockFor);
      await _db.setKv(key, jsonEncode({'failures': 0, 'lockedUntil': until.toIso8601String()}));
      await _outbox.record(
        type: 'staff.pin_locked',
        entityId: staff.id,
        staffId: staff.id,
        payload: {'tries': failures},
      );
      return PinLocked(until);
    }
    await _db.setKv(key, jsonEncode({'failures': failures}));
    return PinWrong(maxTries - failures);
  }

  Future<void> logout(StaffRow staff) =>
      _outbox.record(type: 'staff.logged_out', entityId: staff.id, staffId: staff.id, payload: const {});

  ({int failures, DateTime? lockedUntil}) _decode(String? raw) {
    if (raw == null) return (failures: 0, lockedUntil: null);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final until = j['lockedUntil'] as String?;
    return (failures: (j['failures'] as int?) ?? 0, lockedUntil: until == null ? null : DateTime.parse(until));
  }
}
