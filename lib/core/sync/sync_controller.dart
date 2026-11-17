import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/pos_api.dart';
import '../config.dart';
import '../device/device_repository.dart';
import '../providers.dart';
import 'sync_engine.dart';

enum Connection { unknown, online, offline }

class SyncStatus {
  final Connection connection;
  final bool syncing;
  final DateTime? lastSyncAt;
  final String? lastError;

  const SyncStatus({this.connection = Connection.unknown, this.syncing = false, this.lastSyncAt, this.lastError});

  SyncStatus copyWith({
    Connection? connection,
    bool? syncing,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) => SyncStatus(
    connection: connection ?? this.connection,
    syncing: syncing ?? this.syncing,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

/// Runs the sync in the background every few seconds and exposes its status to the UI.
class SyncController extends Notifier<SyncStatus> {
  late SyncEngine _engine;

  @override
  SyncStatus build() {
    final identity = ref.watch(deviceIdentityProvider).value;
    if (identity == null) return const SyncStatus();

    _engine = _buildEngine(identity);
    final timer = Timer.periodic(AppConfig.syncInterval, (_) => syncNow());
    ref.onDispose(timer.cancel);
    Future.microtask(syncNow); // first sync right away
    return const SyncStatus();
  }

  SyncEngine _buildEngine(DeviceIdentity identity) =>
      SyncEngine(ref.read(databaseProvider), ref.read(posApiProvider), ref.read(outboxRepositoryProvider), identity);

  Future<void> syncNow() async {
    if (state.syncing || ref.read(deviceIdentityProvider).value == null) return;
    state = state.copyWith(syncing: true);
    try {
      await _engine.syncNow();
      if (!ref.mounted) return;
      state = state.copyWith(
        syncing: false,
        connection: Connection.online,
        lastSyncAt: DateTime.now(),
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        syncing: false,
        connection: e.isNetwork ? Connection.offline : Connection.online,
        lastError: e.isNetwork ? null : '${e.code}: ${e.message}',
      );
      // The owner disabled this POS → forget the pairing, the app goes back to the pairing screen.
      if (e.code == 'DEVICE_DISABLED' || e.code == 'UNAUTHORIZED') {
        await ref.read(deviceRepositoryProvider).forget();
        ref.invalidate(deviceIdentityProvider);
      }
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

final pendingEventsProvider = StreamProvider<int>((ref) => ref.watch(outboxRepositoryProvider).watchPendingCount());
