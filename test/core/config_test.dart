import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/config.dart';

void main() {
  test('default profile keeps today’s names (existing POS keep their data and pairing)', () {
    final p = PosProfile.parse(null);
    expect(p.isDefault, isTrue);
    expect(p.databaseName, 'pos_cafe');
    expect(p.secretKey('device_token'), 'device_token');
    expect(PosProfile.parse('  ').isDefault, isTrue);
  });

  test('profile "2" gets its own database and secrets', () {
    final p = PosProfile.parse(' 2 ');
    expect(p.databaseName, 'pos_cafe_2');
    expect(p.secretKey('device_token'), 'profile_2.device_token');
    expect(PosProfile.parse('terrasse_2').databaseName, 'pos_cafe_terrasse_2');
  });

  test('unsafe names fall back to the default (they end up in a file name)', () {
    for (final bad in ['../x', 'a b', 'é', 'x' * 21]) {
      expect(PosProfile.parse(bad).isDefault, isTrue, reason: bad);
    }
  });
}
