import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/loyalty/reward_actions.dart';
import '../../features/order/data/order_repository.dart';
import '../../features/order/view_model/order_view_model.dart';
import '../../features/print/print_providers.dart';
import '../../features/staff_login/view_model/staff_session.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'hub_client.dart';
import 'hub_server.dart';
import 'lan_auth.dart';
import 'lan_info.dart';

/// Hub address, LAN key and payment rights — from the local DB (refreshed by sync).
final lanInfoProvider = StreamProvider<LanInfo?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.kvEntries)
    ..where((k) => k.key.equals(LanInfo.kvKey))).watchSingleOrNull().map((row) => LanInfo.decode(row?.value));
});

Future<LanInfo?> _readLanInfo(AppDatabase db) async => LanInfo.decode(await db.getKv(LanInfo.kvKey));

/// - hub: the main POS; serves the tablets.
/// - tablet: a secondary POS in a café that has a Hub; works through the Hub.
/// - standalone: no Hub in the café; works on its own (as before).
enum PosMode { standalone, hub, tablet }

final posModeProvider = Provider<PosMode>((ref) {
  final identity = ref.watch(deviceIdentityProvider).value;
  if (identity == null) return PosMode.standalone;
  final lan = ref.watch(lanInfoProvider).value;
  // The cloud has the last word: when the owner pairs a new main POS, the old one
  // becomes a secondary POS at its next sync (its pairing said "hub").
  final role = lan?.device(identity.deviceId)?.role ?? identity.role;
  if (role == 'hub') return PosMode.hub;
  final hub = lan?.hub;
  return hub != null && hub.deviceId != identity.deviceId ? PosMode.tablet : PosMode.standalone;
});

/// Code of the main POS ("T1"), for "Reliée à T1".
final hubCodeProvider = Provider<String?>((ref) => ref.watch(lanInfoProvider).value?.hub?.code);

/// Server tablets take payments only if the owner allowed it (Caisses page).
final canTakePaymentsProvider = Provider<bool>((ref) {
  if (ref.watch(posModeProvider) != PosMode.tablet) return true;
  final id = ref.watch(deviceIdentityProvider).value?.deviceId;
  return ref.watch(lanInfoProvider).value?.device(id ?? '')?.canTakePayments ?? false;
});

// ── Hub ────────────────────────────────────────────────────

/// Running only on the Hub. Started with the app, stopped with it.
final hubServerProvider = Provider<HubServer?>((ref) {
  if (ref.watch(posModeProvider) != PosMode.hub) return null;
  final identity = ref.watch(deviceIdentityProvider).value!;
  final db = ref.watch(databaseProvider);
  final server = HubServer(
    db: db,
    outbox: ref.watch(outboxRepositoryProvider),
    identity: identity,
    lanInfo: () => _readLanInfo(db),
    printer: ref.watch(printerTransportProvider),
    api: ref.watch(posApiProvider),
  );
  Timer? report;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    report?.cancel();
    server.stop();
  });
  unawaited(() async {
    try {
      final port = await server.start();
      // Tell the cloud where the tablets can find us; again every minute (the Wi-Fi address can change).
      Future<void> send() async {
        try {
          await ref.read(posApiProvider).reportLan(await localAddresses(), port);
        } catch (_) {
          // offline: the tablets keep the last known address
        }
      }

      await send();
      // The app may have closed while the first report was being sent.
      if (!disposed) report = Timer.periodic(const Duration(minutes: 1), (_) => send());
    } catch (e) {
      debugPrint('Hub server could not start: $e');
    }
  }());
  return server;
});

/// Tablets connected to this Hub right now.
final hubTabletsProvider = StreamProvider<int>((ref) {
  final server = ref.watch(hubServerProvider);
  return server == null ? Stream.value(0) : server.connectedTablets;
});

/// This computer's private IPv4 addresses (Wi-Fi, Ethernet…), real network cards first:
/// virtual adapters (VirtualBox, VMware, Hyper-V, WSL, Docker) can't be reached by tablets.
Future<List<String>> localAddresses() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  final found = [
    for (final i in interfaces)
      for (final a in i.addresses)
        if (_isPrivate(a.address))
          (
            address: a.address,
            virtual: isVirtualAdapter(i.name),
            wifi: RegExp(r'wi-?fi|wlan|wireless', caseSensitive: false).hasMatch(i.name),
          ),
  ];
  // Wi-Fi first (cafés use Wi-Fi), then other cards; tablets also try them all at once.
  int rank(({String address, bool virtual, bool wifi}) f) => f.wifi ? 0 : (f.virtual ? 2 : 1);
  return [
    for (final f in [...found]..sort((a, b) => rank(a) - rank(b))) f.address,
  ];
}

/// Names Windows/Android give to virtual network adapters.
bool isVirtualAdapter(String name) => RegExp(
  r'virtual|vbox|vmware|vethernet|hyper-v|wsl|docker|loopback|vpn|tap|tun',
  caseSensitive: false,
).hasMatch(name);

bool _isPrivate(String ip) {
  final p = ip.split('.').map(int.tryParse).toList();
  if (p.length != 4 || p.contains(null)) return false;
  final (a, b) = (p[0]!, p[1]!);
  return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
}

// ── Server tablet ──────────────────────────────────────────

final hubClientProvider = Provider<HubClient?>((ref) {
  if (ref.watch(posModeProvider) != PosMode.tablet) return null;
  final identity = ref.watch(deviceIdentityProvider).value!;
  final db = ref.watch(databaseProvider);
  final client = HubClient(
    identity: identity,
    lanInfo: () => _readLanInfo(db),
    mirror: HubMirror(db),
    // Hub and tablet on the same PC (testing with POS_PROFILE).
    extraAddresses: Platform.isWindows ? ['127.0.0.1:${HubProtocol.port}'] : const [],
  )..start();
  ref.onDispose(client.stop);
  return client;
});

final hubLinkProvider = StreamProvider<HubLink>((ref) {
  final client = ref.watch(hubClientProvider);
  if (client == null) return Stream.value(const HubLink(HubLinkState.connected));
  return Stream.multi((c) {
    c.add(client.link);
    final sub = client.status.listen(c.add);
    c.onCancel = sub.cancel;
  });
});

/// Where the order screen's actions go: the local DB, or the Hub.
final orderActionsProvider = Provider<OrderActions>((ref) {
  final client = ref.watch(hubClientProvider);
  if (client == null) return ref.watch(orderRepositoryProvider);
  return HubOrderActions(client, staffId: () => ref.read(staffSessionProvider)?.id);
});

/// Loyalty reward codes: here, or through the main POS on a server tablet.
final rewardActionsProvider = Provider<RewardActions>((ref) {
  final client = ref.watch(hubClientProvider);
  if (client == null) return LocalRewardActions(ref.watch(posApiProvider), ref.watch(orderRepositoryProvider));
  return HubRewardActions(client, staffId: () => ref.read(staffSessionProvider)?.id);
});
