import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/db/app_database.dart';

/// A POS already in a café has a v2 database with sales in it.
/// Updating the app must upgrade it to v3 without losing anything.
void main() {
  test('v2 database upgrades to v3 and keeps its data', () async {
    final dir = await Directory.systemTemp.createTemp('pos_migration');
    final file = File('${dir.path}/pos.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    // 1. Build a database, add data, then make it look like v2 (no products.sort_order).
    var db = AppDatabase(NativeDatabase(file));
    await db
        .into(db.products)
        .insert(ProductsCompanion.insert(id: 'p1', categoryId: 'c1', name: 'Express', price: 1200));
    await db.setKv('last_seq', '42');
    await db.customStatement('ALTER TABLE products DROP COLUMN sort_order');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();

    // 2. Open with the new app version → migration v2 → v3 runs.
    db = AppDatabase(NativeDatabase(file));
    final p = await db.select(db.products).getSingle();
    expect((p.name, p.price, p.sortOrder), ('Express', 1200, 0));
    expect(await db.getKv('last_seq'), '42');
    expect((await db.customSelect('PRAGMA user_version').getSingle()).data.values.first, 3);
    await db.close();
  });
}
