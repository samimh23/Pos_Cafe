import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ids.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_controller.dart';

/// Menu read from the LOCAL database (never from the internet).
/// Updates automatically when the sync pulls changes.
final categoriesProvider = StreamProvider<List<CategoryRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();
});

final productsProvider = StreamProvider.family<List<ProductRow>, String>((ref, categoryId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.products)
        ..where((t) => t.categoryId.equals(categoryId) & t.available.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();
});

/// ViewModel of the home screen: which category is selected + actions.
class HomeViewModel extends Notifier<String?> {
  @override
  String? build() {
    // Select the first category once the menu is loaded.
    final cats = ref.watch(categoriesProvider).value;
    return cats == null || cats.isEmpty ? null : cats.first.id;
  }

  void selectCategory(String id) => state = id;

  Future<void> syncNow() => ref.read(syncControllerProvider.notifier).syncNow();

  /// Development only: create one event to check the sync end to end.
  Future<void> recordTestEvent() async {
    assert(kDebugMode);
    await ref.read(outboxRepositoryProvider).record(
      type: 'debug.test',
      entityId: newId(),
      payload: {'message': 'hello from the POS'},
    );
  }

  /// Development only: unpair this POS.
  Future<void> forgetDevice() async {
    await ref.read(deviceRepositoryProvider).forget();
    ref.invalidate(deviceIdentityProvider);
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, String?>(HomeViewModel.new);
