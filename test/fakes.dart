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
    });
  }

  /// What the next pull (with a cursor) returns — e.g. a price change or `deleted: true`.
  List<Map<String, dynamic>> changedCategories = [];
  List<Map<String, dynamic>> changedProducts = [];
}
