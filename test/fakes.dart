import 'package:pos_cafe/core/api/pos_api.dart';

/// In-memory backend for tests. Mirrors the real server rules (idempotent push).
class FakePosApi implements PosApi {
  final pushed = <String, Map<String, Object?>>{};
  final validCodes = <String>{'ABCD-EFGH'};
  ApiException? failWith;
  int devices = 0;
  Set<String> rejectIds = {};

  List<Map<String, dynamic>> categories = [
    {'id': 'c1', 'name': 'Boissons chaudes', 'sortOrder': 1, 'color': '#8B5E3C'},
  ];
  List<Map<String, dynamic>> products = [
    {
      'id': 'p1',
      'categoryId': 'c1',
      'name': 'Express',
      'price': 1200,
      'vatRateBp': 1900,
      'station': 'bar',
      'modifierGroups': [],
      'available': true,
    },
  ];

  /// What GET /v1/devices/lan returns. No Hub by default (each POS works on its own).
  Map<String, dynamic> lan = {'lanKey': 'test-lan-key', 'hub': null, 'devices': []};
  final reportedLan = <(List<String>, int)>[];

  @override
  Future<Map<String, dynamic>> lanInfo() async {
    _maybeFail();
    return lan;
  }

  @override
  Future<void> reportLan(List<String> addresses, int port) async {
    _maybeFail();
    reportedLan.add((addresses, port));
  }

  void _maybeFail() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<PairResponse> pair({required String code, required String name, required String publicKey}) async {
    _maybeFail();
    if (!validCodes.remove(code)) {
      throw const ApiException('PAIRING_CODE_INVALID', 'invalid', 400);
    }
    devices++;
    return PairResponse.fromJson({
      'deviceId': 'dev-$devices',
      'deviceCode': 'T$devices',
      'role': 'hub',
      'tenantId': 'tenant-1',
      'branchId': 'branch-1',
      'token': 'secret-token-$devices',
    });
  }

  @override
  Future<void> me() async => _maybeFail();

  @override
  Future<PushResponse> push(List<Map<String, Object?>> events) async {
    _maybeFail();
    var dup = 0;
    final accepted = <String>[], rejected = <Map<String, String>>[];
    for (final e in events) {
      final id = e['id'] as String;
      if (rejectIds.contains(id)) {
        rejected.add({'id': id, 'code': 'WRONG_DEVICE_OR_BRANCH'});
        continue;
      }
      if (pushed.containsKey(id)) dup++;
      pushed[id] = e;
      accepted.add(id);
    }
    return PushResponse.fromJson({'accepted': accepted, 'rejected': rejected, 'duplicates': dup});
  }

  @override
  Future<PullResponse> pull(String? cursor) async {
    _maybeFail();
    return PullResponse.fromJson({
      'cursor': '2026-11-17T10:00:00.000Z',
      'categories': cursor == null ? categories : changedCategories,
      'products': cursor == null ? products : changedProducts,
      'staff': cursor == null ? staff.where((s) => s['active'] == true).toList() : changedStaff,
      'areas': cursor == null ? areas : changedAreas,
      'tables': cursor == null ? tables : changedTables,
    });
  }

  /// Ahmed, PIN 1234 (shared test vector with the backend, 1000 iterations = fast tests).
  List<Map<String, dynamic>> staff = [
    {'id': 'staff-ahmed', 'name': 'Ahmed', 'role': 'server', 'pinHash': ahmedPinHash, 'active': true},
  ];
  List<Map<String, dynamic>> changedStaff = [];

  /// Rooms and tables — empty by default (a café without tables goes straight to the counter).
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> tables = [];
  List<Map<String, dynamic>> changedAreas = [];
  List<Map<String, dynamic>> changedTables = [];

  /// "Salle" with tables 1–4 and "Terrasse" with T1.
  void withFloor() {
    areas = [
      {'id': 'area-salle', 'name': 'Salle', 'sortOrder': 0, 'deleted': false},
      {'id': 'area-terrasse', 'name': 'Terrasse', 'sortOrder': 1, 'deleted': false},
    ];
    tables = [
      for (var i = 1; i <= 4; i++)
        {'id': 'table-$i', 'areaId': 'area-salle', 'name': '$i', 'seats': 4, 'sortOrder': i, 'deleted': false},
      {'id': 'table-t1', 'areaId': 'area-terrasse', 'name': 'T1', 'seats': 2, 'sortOrder': 0, 'deleted': false},
    ];
  }

  /// What the next pull (with a cursor) returns — e.g. a price change or `deleted: true`.
  List<Map<String, dynamic>> changedCategories = [];
  List<Map<String, dynamic>> changedProducts = [];
}

/// PIN "1234" — same vector as Backend_Platform test/staff.test.ts.
const ahmedPinHash = r'pbkdf2-sha256$1000$a2Fod3RpLXRlc3Qtc2FsdA$I4Uu_ofD4UQbzJa60p4IWhObH52R4TW-SLj5lfbAnFU';
