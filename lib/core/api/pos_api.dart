import 'package:dio/dio.dart';

/// Error from the backend ({ error: { code, message } }) or from the network.
class ApiException implements Exception {
  final String code;
  final String message;

  /// null = no answer from the server (offline, timeout).
  final int? statusCode;

  const ApiException(this.code, this.message, [this.statusCode]);

  bool get isNetwork => statusCode == null;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException('${err['code']}', '${err['message']}', e.response?.statusCode);
    }
    if (e.response == null) return const ApiException('NETWORK', 'Server unreachable');
    return ApiException('HTTP_${e.response!.statusCode}', e.message ?? 'HTTP error', e.response!.statusCode);
  }

  @override
  String toString() => 'ApiException($code, $message)';
}

class PairResponse {
  final String deviceId, deviceCode, role, tenantId, branchId, token;
  PairResponse.fromJson(Map<String, dynamic> j)
    : deviceId = j['deviceId'],
      deviceCode = j['deviceCode'],
      role = j['role'],
      tenantId = j['tenantId'],
      branchId = j['branchId'],
      token = j['token'];
}

class PushResponse {
  final List<String> accepted;
  final Map<String, String> rejected;
  final int duplicates;
  PushResponse.fromJson(Map<String, dynamic> j)
    : accepted = (j['accepted'] as List).cast<String>(),
      rejected = {for (final r in (j['rejected'] as List)) r['id'] as String: r['code'] as String},
      duplicates = j['duplicates'] as int;
}

class PullResponse {
  final String cursor;
  final List<Map<String, dynamic>> categories, products, staff, areas, tables;
  PullResponse.fromJson(Map<String, dynamic> j)
    : cursor = j['cursor'],
      categories = (j['categories'] as List).cast<Map<String, dynamic>>(),
      products = (j['products'] as List).cast<Map<String, dynamic>>(),
      // Older backends don't send staff yet.
      staff = ((j['staff'] as List?) ?? const []).cast<Map<String, dynamic>>(),
      areas = ((j['areas'] as List?) ?? const []).cast<Map<String, dynamic>>(),
      tables = ((j['tables'] as List?) ?? const []).cast<Map<String, dynamic>>();
}

/// Backend calls the POS needs. An interface so tests can use a fake.
abstract class PosApi {
  Future<PairResponse> pair({required String code, required String name, required String publicKey});
  Future<void> me();
  Future<PushResponse> push(List<Map<String, Object?>> events);
  Future<PullResponse> pull(String? cursor);

  /// Hub address on the café network, LAN key, devices and their payment rights.
  Future<Map<String, dynamic>> lanInfo();

  /// The Hub tells the cloud where the other POS can reach it.
  Future<void> reportLan(List<String> addresses, int port);

  /// Café details printed on receipts (name, matricule fiscal, address…).
  Future<Map<String, dynamic>> business();

  /// A loyalty reward code from the customer's app: what it is (nothing spent).
  Future<Map<String, dynamic>> checkReward(String code);

  /// Spends the customer's points for that reward, on [orderId].
  Future<Map<String, dynamic>> redeemReward(String code, {required String orderId});
}

class DioPosApi implements PosApi {
  DioPosApi({required String baseUrl, required Future<String?> Function() token})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await token();
          if (t != null) options.headers['authorization'] = 'Device $t';
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> _call(Future<Response<dynamic>> Function() request) async {
    try {
      return ((await request()).data as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<PairResponse> pair({required String code, required String name, required String publicKey}) async =>
      PairResponse.fromJson(
        await _call(() => _dio.post('/v1/devices/pair', data: {'code': code, 'name': name, 'publicKey': publicKey})),
      );

  @override
  Future<void> me() => _call(() => _dio.get('/v1/devices/me'));

  @override
  Future<PushResponse> push(List<Map<String, Object?>> events) async =>
      PushResponse.fromJson(await _call(() => _dio.post('/v1/sync/push', data: {'events': events})));

  @override
  Future<PullResponse> pull(String? cursor) async => PullResponse.fromJson(
    await _call(() => _dio.get('/v1/sync/pull', queryParameters: {if (cursor != null) 'cursor': cursor})),
  );

  @override
  Future<Map<String, dynamic>> lanInfo() => _call(() => _dio.get('/v1/devices/lan'));

  @override
  Future<Map<String, dynamic>> business() => _call(() => _dio.get('/v1/devices/business'));

  @override
  Future<Map<String, dynamic>> checkReward(String code) =>
      _call(() => _dio.get('/v1/devices/loyalty/redemptions/${Uri.encodeComponent(code)}'));

  @override
  Future<Map<String, dynamic>> redeemReward(String code, {required String orderId}) => _call(
    () => _dio.post('/v1/devices/loyalty/redemptions/${Uri.encodeComponent(code)}/redeem', data: {'orderId': orderId}),
  );

  @override
  Future<void> reportLan(List<String> addresses, int port) =>
      _call(() => _dio.post('/v1/devices/me/lan', data: {'addresses': addresses, 'port': port}));
}
