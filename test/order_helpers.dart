import 'package:pos_cafe/core/money/money.dart';
import 'package:pos_cafe/core/money/order_totals.dart';
import 'package:pos_cafe/features/order/data/order_repository.dart';

/// Counter shortcuts for tests: pay / cancel the whole counter ticket.
extension CounterOrders on OrderRepository {
  Future<PaymentResult> payCounterCash({required Money tendered, required String deviceCode}) async {
    final order = await watchOpenOrder().first;
    if (order == null) throw const OrderException('Aucune commande en cours.');
    final lines = await watchLines(order.id).first;
    final remaining = OrderTotals.of(lines.map(amountsOf)).total - await watchPaid(order.id).first;
    return pay(order.id, PaymentRequest.cash(amount: remaining, tendered: tendered), deviceCode: deviceCode);
  }

  Future<void> cancelCounterOrder() async {
    final order = await watchOpenOrder().first;
    if (order != null) await cancelOrder(order.id);
  }
}
