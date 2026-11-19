import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/lan/hub_client.dart';
import '../../../core/lan/lan_providers.dart';
import '../../../core/providers.dart';
import '../../staff_login/view_model/staff_session.dart';
import '../data/cash_repository.dart';

/// This POS's drawer: local on the main POS (or a POS alone), through the main POS on a tablet.
final cashActionsProvider = Provider<CashActions>((ref) {
  String? staffId() => ref.read(staffSessionProvider)?.id;
  final client = ref.watch(hubClientProvider);
  if (client != null) return HubCashActions(client, staffId: staffId);
  return CashRepository(
    ref.watch(databaseProvider),
    ref.watch(outboxRepositoryProvider),
    drawerId: ref.watch(deviceIdentityProvider).value?.deviceId ?? '',
    staffId: staffId,
  );
});

/// The open session of this POS's drawer, live (on a tablet: from the main POS's copy).
final openCashSessionProvider = StreamProvider<CashSessionRow?>((ref) {
  final db = ref.watch(databaseProvider);
  final drawerId = ref.watch(deviceIdentityProvider).value?.deviceId;
  if (drawerId == null) return Stream.value(null);
  return (db.select(db.cashSessions)
        ..where((t) => t.drawerId.equals(drawerId) & t.status.equals('open'))
        ..limit(1))
      .watchSingleOrNull();
});

/// Totals of the open session, refreshed when the Caisse screen opens or after an action.
final cashSummaryProvider = FutureProvider.autoDispose<CashSummary?>((ref) {
  ref.watch(openCashSessionProvider); // opened / closed elsewhere → recompute
  return ref.watch(cashActionsProvider).summary();
});
