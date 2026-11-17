import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/menu/modifiers.dart';
import '../../../core/money/money.dart';
import '../../../core/money/order_totals.dart';
import '../../../core/providers.dart';
import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(databaseProvider), ref.watch(outboxRepositoryProvider)),
);

/// The open order (null when the ticket is empty and nothing was started).
final openOrderProvider = StreamProvider<OrderRow?>((ref) => ref.watch(orderRepositoryProvider).watchOpenOrder());

/// Lines of the open order, live from the local DB.
final ticketLinesProvider = StreamProvider<List<OrderLineRow>>((ref) {
  final order = ref.watch(openOrderProvider).value;
  if (order == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).watchLines(order.id);
});

/// What the ticket panel shows.
class TicketState {
  final List<OrderLineRow> lines;
  final OrderTotals totals;
  const TicketState(this.lines, this.totals);
  bool get isEmpty => totals.isEmpty;
}

final ticketProvider = Provider<TicketState>((ref) {
  final lines = ref.watch(ticketLinesProvider).value ?? const [];
  return TicketState(lines, OrderTotals.of(lines.map(amountsOf)));
});

/// ViewModel of the order: actions only — the ticket itself comes from [ticketProvider].
/// State = true while an action is running (to disable buttons).
class OrderViewModel extends Notifier<bool> {
  @override
  bool build() => false;

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  Future<void> addProduct(ProductRow p, [List<ModifierOption> modifiers = const []]) =>
      _repo.addProduct(p, modifiers: modifiers);

  Future<void> increment(OrderLineRow l) => _repo.setQty(l.id, l.qty + 1);

  Future<void> decrement(OrderLineRow l) => _repo.setQty(l.id, l.qty - 1);

  Future<void> remove(OrderLineRow l) => _repo.removeLine(l.id);

  Future<void> cancelOrder() => _repo.cancelOpenOrder();

  /// Returns the result to show (receipt number, change). Throws [OrderException].
  Future<PaymentResult> payCash(Money tendered) async {
    final identity = await ref.read(deviceIdentityProvider.future);
    if (identity == null) throw const OrderException('Caisse non associée.');
    state = true;
    try {
      return await _repo.payCash(tendered: tendered, deviceCode: identity.deviceCode);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

final orderViewModelProvider = NotifierProvider<OrderViewModel, bool>(OrderViewModel.new);
