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
