import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/pos_api.dart';
import 'config.dart';
import 'db/app_database.dart';
import 'device/device_repository.dart';
import 'device/secret_store.dart';
import 'sync/outbox_repository.dart';

/// Shared services (the Model layer). ViewModels get them with ref.watch / ref.read.
/// Tests replace them with `ProviderScope(overrides: [...])`.

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final secretStoreProvider = Provider<SecretStore>((ref) => SecureSecretStore());

final posApiProvider = Provider<PosApi>((ref) {
  final secrets = ref.watch(secretStoreProvider);
  return DioPosApi(baseUrl: AppConfig.apiUrl, token: () => secrets.read(SecretKeys.deviceToken));
});

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(ref.watch(databaseProvider), ref.watch(secretStoreProvider), ref.watch(posApiProvider)),
);

final outboxRepositoryProvider = Provider<OutboxRepository>((ref) => OutboxRepository(ref.watch(databaseProvider)));

/// The paired identity, or null if this POS is not paired yet.
/// Invalidate it after pairing / forgetting to update the whole app.
final deviceIdentityProvider = FutureProvider<DeviceIdentity?>((ref) => ref.watch(deviceRepositoryProvider).load());
