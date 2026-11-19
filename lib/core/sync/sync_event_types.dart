/// Event types sent to the backend. Keep in sync with Notion → Sync protocol.
abstract final class EventTypes {
  static const orderOpened = 'order.opened';
  static const orderItemAdded = 'order.item_added';
  static const orderItemUpdated = 'order.item_updated';
  static const orderItemVoided = 'order.item_voided';
  static const orderCancelled = 'order.cancelled';
  static const orderClosed = 'order.closed';
  static const orderTableChanged = 'order.table_changed';
  static const orderBillRequested = 'order.bill_requested';
  static const cashSessionOpened = 'cash_session.opened';
  static const cashMoved = 'cash.moved';
  static const cashSessionClosed = 'cash_session.closed';
  static const orderSent = 'order.sent';
  static const paymentAdded = 'payment.added';
}
