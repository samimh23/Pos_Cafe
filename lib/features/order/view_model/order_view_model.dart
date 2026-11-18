import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/lan/lan_providers.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../../core/providers.dart';
import '../../floor/view_model/floor_view_model.dart';
import '../../staff_login/view_model/staff_session.dart';
import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(
    ref.watch(databaseProvider),
    ref.watch(outboxRepositoryProvider),
    staffId: () => ref.read(staffSessionProvider)?.id,
  ),
);

/// The open order of the ticket on screen (null when nothing was started yet).
/// autoDispose: rebuilt fresh each time a ticket opens (target changes while off screen).
final openOrderProvider = StreamProvider.autoDispose<OrderRow?>((ref) {
  final target = ref.watch(activeTargetProvider);
  if (target == null) return Stream.value(null);
  return ref.watch(orderRepositoryProvider).watchOpenOrder(tableId: target.tableId);
});

/// Lines of the open order, live from the local DB.
final ticketLinesProvider = StreamProvider.autoDispose<List<OrderLineRow>>((ref) {
  final order = ref.watch(openOrderProvider).value;
  if (order == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).watchLines(order.id);
});

/// Already paid on the open order (split payments).
final ticketPaidProvider = StreamProvider.autoDispose<Money>((ref) {
  final order = ref.watch(openOrderProvider).value;
  if (order == null) return Stream.value(Money.zero);
  return ref.watch(orderRepositoryProvider).watchPaid(order.id);
});

/// What the ticket panel shows.
class TicketState {
  final OrderRow? order;
  final List<OrderLineRow> lines;
  final OrderTotals totals;
  final Money paid;
  const TicketState(this.order, this.lines, this.totals, this.paid);
  bool get isEmpty => totals.isEmpty;
  Money get remaining => totals.total - paid;

  /// Lines not paid on their own yet (for "split by items").
  List<OrderLineRow> get unpaidLines => [
    for (final l in lines)
      if (l.paymentId == null) l,
  ];
}

final ticketProvider = Provider.autoDispose<TicketState>((ref) {
  final lines = ref.watch(ticketLinesProvider).value ?? const [];
  return TicketState(
    ref.watch(openOrderProvider).value,
    lines,
    OrderTotals.of(lines.map(amountsOf)),
    ref.watch(ticketPaidProvider).value ?? Money.zero,
  );
});

/// ViewModel of the order: actions only — the ticket itself comes from [ticketProvider].
/// State = true while an action is running (to disable buttons).
class OrderViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  /// Local DB, or the Hub on a server tablet.
  OrderActions get _repo => ref.read(orderActionsProvider);

  DiningTableRow? get _table => switch (ref.read(activeTargetProvider)) {
    TableTarget(:final table) => table,
    _ => null,
  };

  String? get _orderId => ref.read(openOrderProvider).value?.id;

  Future<void> addProduct(ProductRow p, [List<ModifierOption> modifiers = const []]) =>
      _repo.addProduct(p, table: _table, modifiers: modifiers);

  Future<void> increment(OrderLineRow l) => _repo.setQty(l.id, l.qty + 1);

  Future<void> decrement(OrderLineRow l) => _repo.setQty(l.id, l.qty - 1);

  Future<void> remove(OrderLineRow l) => _repo.removeLine(l.id);

  Future<void> cancelOrder() async {
    final id = _orderId;
    if (id != null) await _repo.cancelOrder(id);
  }

  /// "Demander l'addition": the cashier sees it on the Hub's tables screen.
  Future<void> requestBill() async {
    final id = _orderId;
    if (id != null) await _repo.requestBill(id);
  }

  /// Moves the ticket on screen to [to] (null = counter) and follows it there.
  Future<void> moveTo(DiningTableRow? to) async {
    final id = _orderId;
    if (id == null) return;
    await _repo.moveOrder(id, to);
    ref.read(ticketTargetProvider.notifier).open(to == null ? const CounterTarget() : TableTarget(to));
  }

  /// Returns the result to show (receipt number or what is left, change). Throws [OrderException].
  /// A table that is fully paid goes back to the tables screen.
  Future<PaymentResult> pay(PaymentRequest request) async {
    final identity = await ref.read(deviceIdentityProvider.future);
    if (identity == null) throw const OrderException('Caisse non associée.');
    final id = _orderId;
    if (id == null) throw const OrderException('Aucune commande en cours.');
    state = true;
    try {
      final r = await _repo.pay(id, request, deviceCode: identity.deviceCode);
      if (r.closed && ref.read(activeTargetProvider) is TableTarget) {
        ref.read(ticketTargetProvider.notifier).backToFloor();
      }
      return r;
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final orderViewModelProvider = NotifierProvider<OrderViewModel, bool>(OrderViewModel.new);
