import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../order/data/order_repository.dart';
import '../../order/view_model/order_view_model.dart';
import '../../staff_login/view_model/staff_session.dart';

/// Rooms, from the LOCAL database (filled by sync).
final areasProvider = StreamProvider<List<AreaRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.floorAreas)
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)])).watch();
});

/// Tables, from the LOCAL database (filled by sync).
final tablesProvider = StreamProvider<List<DiningTableRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.diningTables)
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)])).watch();
});

/// Every open ticket with its total and what is already paid.
final openTicketsProvider = StreamProvider<List<OpenTicket>>(
  (ref) => ref.watch(orderRepositoryProvider).watchOpenTickets(),
);

/// Which ticket is on screen.
sealed class TicketTarget {
  const TicketTarget();

  /// null = the counter (takeaway).
  String? get tableId;
}

class CounterTarget extends TicketTarget {
  const CounterTarget();
  @override
  String? get tableId => null;
  @override
  bool operator ==(Object other) => other is CounterTarget;
  @override
  int get hashCode => 0;
}

class TableTarget extends TicketTarget {
  const TableTarget(this.table);
  final DiningTableRow table;
  @override
  String? get tableId => table.id;
  @override
  bool operator ==(Object other) => other is TableTarget && other.table.id == table.id;
  @override
  int get hashCode => table.id.hashCode;
}

/// What the staff member opened from the tables screen. Reset when someone else logs in.
class TicketTargetNotifier extends Notifier<TicketTarget?> {
  @override
  TicketTarget? build() {
    ref.watch(staffSessionProvider.select((s) => s?.id));
    return null;
  }

  void open(TicketTarget target) => state = target;

  /// Back to the tables screen.
  void backToFloor() => state = null;
}

final ticketTargetProvider = NotifierProvider<TicketTargetNotifier, TicketTarget?>(TicketTargetNotifier.new);

/// The ticket on screen. A café without tables goes straight to the counter;
/// null = show the tables screen.
final activeTargetProvider = Provider<TicketTarget?>((ref) {
  final chosen = ref.watch(ticketTargetProvider);
  if (chosen != null) return chosen;
  final tables = ref.watch(tablesProvider).value;
  if (tables == null) return null;
  return tables.isEmpty ? const CounterTarget() : null;
});

/// The café has tables (so the "Tables" button makes sense).
final hasTablesProvider = Provider<bool>((ref) => ref.watch(tablesProvider).value?.isNotEmpty ?? false);
