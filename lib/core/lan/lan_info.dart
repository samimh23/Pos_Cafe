import 'dart:convert';

/// A device of the café, as the Hub needs to know it.
class LanDevice {
  final String id, code, name, role;
  final bool canTakePayments, disabled;
  const LanDevice({
    required this.id,
    required this.code,
    required this.name,
    required this.role,
    required this.canTakePayments,
    required this.disabled,
  });

  factory LanDevice.fromJson(Map<String, dynamic> j) => LanDevice(
    id: j['id'],
    code: j['code'],
    name: j['name'],
    role: j['role'],
    canTakePayments: j['canTakePayments'] == true,
    disabled: j['disabled'] == true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'role': role,
    'canTakePayments': canTakePayments,
    'disabled': disabled,
  };
}

/// Where the Hub is on the café network.
class HubAddress {
  final String deviceId, code;
  final List<String> addresses;
  final int? port;
  const HubAddress({required this.deviceId, required this.code, required this.addresses, required this.port});

  factory HubAddress.fromJson(Map<String, dynamic> j) => HubAddress(
    deviceId: j['deviceId'],
    code: j['code'],
    addresses: ((j['addresses'] as List?) ?? const []).cast<String>(),
    port: j['port'] as int?,
  );

  Map<String, Object?> toJson() => {'deviceId': deviceId, 'code': code, 'addresses': addresses, 'port': port};
}

/// Everything the POS of one café need to work together on the local network.
/// Comes from the cloud (GET /v1/devices/lan) and is kept in the local DB, so it
/// still works when the internet is down.
class LanInfo {
  static const kvKey = 'lan_info';

  /// Signs every request between POS (HMAC) — never shown, never sent in clear.
  final String lanKey;
  final HubAddress? hub;
  final List<LanDevice> devices;
  const LanInfo({required this.lanKey, required this.hub, required this.devices});

  factory LanInfo.fromJson(Map<String, dynamic> j) => LanInfo(
    lanKey: j['lanKey'],
    hub: j['hub'] == null ? null : HubAddress.fromJson((j['hub'] as Map).cast<String, dynamic>()),
    devices: [
      for (final d in (j['devices'] as List? ?? const [])) LanDevice.fromJson((d as Map).cast<String, dynamic>()),
    ],
  );

  static LanInfo? decode(String? s) => s == null ? null : LanInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String encode() => jsonEncode({
    'lanKey': lanKey,
    'hub': hub?.toJson(),
    'devices': [for (final d in devices) d.toJson()],
  });

  LanDevice? device(String id) => devices.where((d) => d.id == id).firstOrNull;
}
