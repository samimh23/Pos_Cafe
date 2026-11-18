import 'package:drift/drift.dart';

/// Small key/value settings: device identity (non-secret), lastSeq, pull cursor…
/// Secrets (token, private key) live in secure storage, never here.
@DataClassName('KvRow')
class KvEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Menu categories — owned by the cloud, filled by sync pull.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Menu products — owned by the cloud, filled by sync pull.
@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();

  /// Price TTC in millimes.
  IntColumn get price => integer()();

  /// VAT in basis points (1900 = 19 %).
  IntColumn get vatRateBp => integer().withDefault(const Constant(1900))();
  TextColumn get station => text().withDefault(const Constant('none'))();
  TextColumn get modifierGroupsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get available => boolean().withDefault(const Constant(true))();

  /// Order chosen by the owner (v3).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Events waiting to be sent to the cloud (the "outbox").
/// Written in the SAME transaction as the data change, so nothing is ever lost.
@DataClassName('OutboxRow')
class OutboxEvents extends Table {
  /// UUID v7 — idempotency key on the server.
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get entityId => text()();

  /// 1, 2, 3… per device. Gaps on the server = lost events.
  IntColumn get deviceSeq => integer().unique()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get staffId => text().nullable()();
  TextColumn get approvedBy => text().nullable()();
  TextColumn get payloadJson => text()();

  /// Set when the server refuses the event — it stays for investigation, not retried.
  TextColumn get rejectedCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Sales (owned by this device; every change also records an event) ──────

/// One customer order. Several can be open at once: one per table + the counter (v5).
@DataClassName('OrderRow')
class Orders extends Table {
  TextColumn get id => text()();

  /// open | paid | cancelled
  TextColumn get status => text().withDefault(const Constant('open'))();

  /// takeaway | table
  TextColumn get type => text().withDefault(const Constant('takeaway'))();
  /// Table name snapshot ("4") — stays right even if the table is renamed later.
  TextColumn get tableLabel => text().nullable()();

  /// Table the order is on; null = counter / takeaway (v5).
  TextColumn get tableId => text().nullable()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  /// TTC in millimes, set when the order is paid.
  IntColumn get total => integer().withDefault(const Constant(0))();

  /// "T1-000042", set when the order is paid.
  TextColumn get receiptNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A line of an order. Name and prices are SNAPSHOTS taken at sale time:
/// changing the menu later never changes old orders.
@DataClassName('OrderLineRow')
class OrderLines extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();

  /// Product price TTC in millimes (without modifiers).
  IntColumn get unitPrice => integer()();

  /// Sum of the chosen modifiers' extra prices, per unit.
  IntColumn get modifiersPrice => integer().withDefault(const Constant(0))();

  /// [{"id","name","extraPrice"}] — chosen modifiers.
  TextColumn get modifiersJson => text().withDefault(const Constant('[]'))();
  IntColumn get qty => integer()();
  IntColumn get vatRateBp => integer()();
  TextColumn get station => text().withDefault(const Constant('none'))();
  TextColumn get note => text().nullable()();
  BoolColumn get voided => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  /// Set when this line was paid on its own ("split by items", v5) — it can't be changed anymore.
  TextColumn get paymentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();

  /// cash | card
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  IntColumn get tendered => integer()();
  IntColumn get changeGiven => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Staff who can log in on this POS (v4). Filled by sync pull; the PIN is checked
/// OFFLINE against `pinHash` (never the PIN itself).
@DataClassName('StaffRow')
class StaffMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// manager | cashier | server | kitchen
  TextColumn get role => text()();
  TextColumn get pinHash => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Rooms ("Salle", "Terrasse") — owned by the cloud, filled by sync pull (v5).
@DataClassName('AreaRow')
class FloorAreas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tables customers sit at — owned by the cloud, filled by sync pull (v5).
@DataClassName('DiningTableRow')
class DiningTables extends Table {
  TextColumn get id => text()();
  TextColumn get areaId => text()();
  TextColumn get name => text()();
  IntColumn get seats => integer().withDefault(const Constant(4))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
