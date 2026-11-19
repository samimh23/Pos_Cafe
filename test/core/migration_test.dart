import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';

/// A POS already in a café has a v2 database with sales in it.
/// Updating the app must upgrade it to the latest version without losing anything.
void main() {
  test('v2 database upgrades to the latest version and keeps its data', () async {
    final dir = await Directory.systemTemp.createTemp('pos_migration');
    final file = File('${dir.path}/pos.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // 1. Build a database, add data, then make it look like v2 (no products.sort_order).
    var db = AppDatabase(NativeDatabase(file));
    await db
        .into(db.products)
        .insert(ProductsCompanion.insert(id: 'p1', categoryId: 'c1', name: 'Express', price: 1200));
    await db.setKv('last_seq', '42');
    await db.into(db.orders).insert(OrdersCompanion.insert(id: 'o1', openedAt: DateTime.utc(2026, 11, 1)));
    await db.customStatement('ALTER TABLE products DROP COLUMN sort_order');
    await db.customStatement('DROP TABLE staff_members'); // v4 table didn't exist in v2
    // v5 additions
    await db.customStatement('DROP TABLE floor_areas');
    await db.customStatement('DROP TABLE dining_tables');
    await db.customStatement('ALTER TABLE orders DROP COLUMN table_id');
    await db.customStatement('ALTER TABLE order_lines DROP COLUMN payment_id');
    // v6 addition
    await db.customStatement('ALTER TABLE orders DROP COLUMN bill_requested_at');
    // v7 additions
    await db.customStatement('DROP TABLE cash_sessions');
    await db.customStatement('DROP TABLE cash_movements');
    await db.customStatement('ALTER TABLE payments DROP COLUMN drawer_id');
    // v8 addition
    await db.customStatement('ALTER TABLE order_lines DROP COLUMN sent_at');
    // v9 additions
    for (final c in ['discount_type', 'discount_value', 'discount_reason', 'discount_approved_by']) {
      await db.customStatement('ALTER TABLE order_lines DROP COLUMN $c');
    }
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();

    // 2. Open with the new app version → migrations v2 → latest run.
    db = AppDatabase(NativeDatabase(file));
    final p = await db.select(db.products).getSingle();
    expect((p.name, p.price, p.sortOrder), ('Express', 1200, 0));
    expect(await db.getKv('last_seq'), '42');
    expect((await db.customSelect('PRAGMA user_version').getSingle()).data.values.first, db.schemaVersion);
    expect(await db.select(db.staffMembers).get(), isEmpty); // v4 table created
    expect(await db.select(db.diningTables).get(), isEmpty); // v5 tables created
    expect(await db.select(db.cashSessions).get(), isEmpty); // v7 tables created
    final old = await db.select(db.orders).getSingle(); // old ticket kept: counter, no bill request
    expect((old.tableId, old.billRequestedAt), (null, null));
    await db.close();
  });
}
