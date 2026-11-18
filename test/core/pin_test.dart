import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cafe/core/staff/pin.dart';

void main() {
  // Shared test vector — Backend_Platform test/staff.test.ts produces exactly this hash.
  const vector = r'pbkdf2-sha256$1000$a2Fod3RpLXRlc3Qtc2FsdA$I4Uu_ofD4UQbzJa60p4IWhObH52R4TW-SLj5lfbAnFU';

  test('backend hash verifies with the right PIN only', () async {
    expect(await verifyPin('1234', vector), isTrue);
    expect(await verifyPin('1235', vector), isFalse);
    expect(await verifyPin('', vector), isFalse);
  });

  test('malformed hashes are refused, not crashing', () async {
    for (final bad in ['', 'garbage', r'md5$1$a$b', r'pbkdf2-sha256$x$a$b', r'pbkdf2-sha256$1000$!!!$###']) {
      expect(await verifyPin('1234', bad), isFalse, reason: bad);
    }
  });

  test('production cost (20 000 iterations) stays fast enough for a PIN pad', () async {
    // Same salt/pin, production iteration count; we only measure time here.
    final sw = Stopwatch()..start();
    await verifyPin('1234', r'pbkdf2-sha256$20000$a2Fod3RpLXRlc3Qtc2FsdA$I4Uu_ofD4UQbzJa60p4IWhObH52R4TW-SLj5lfbAnFU');
    // ignore: avoid_print
    print('PBKDF2 20k iterations in Dart: ${sw.elapsedMilliseconds} ms');
    expect(sw.elapsedMilliseconds, lessThan(2000));
  });

  test('isValidPin', () {
    expect(isValidPin('1234'), isTrue);
    expect(isValidPin('123456'), isTrue);
    expect(isValidPin('123'), isFalse);
    expect(isValidPin('12a4'), isFalse);
  });
}
