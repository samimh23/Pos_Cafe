import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/staff/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(databaseProvider), ref.watch(outboxRepositoryProvider)),
);

/// Staff who can log in here (live from the local DB, updated by sync).
final staffListProvider = StreamProvider<List<StaffRow>>((ref) => ref.watch(staffRepositoryProvider).watchStaff());

/// Who is using the POS right now. Not saved: after a restart, staff log in again.
class StaffSession extends Notifier<StaffRow?> {
  @override
  StaffRow? build() {
    // If the logged-in person is deactivated by the owner, log them out.
    final list = ref.watch(staffListProvider).value;
    final current = stateOrNull;
    if (list != null && current != null && !list.any((s) => s.id == current.id)) return null;
    return current;
  }

  void loggedIn(StaffRow staff) => state = staff;

  Future<void> logout() async {
    final current = state;
    state = null;
    if (current != null) await ref.read(staffRepositoryProvider).logout(current);
  }
}

final staffSessionProvider = NotifierProvider<StaffSession, StaffRow?>(StaffSession.new);
