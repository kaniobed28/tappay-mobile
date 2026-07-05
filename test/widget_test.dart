import 'package:flutter_test/flutter_test.dart';

import 'package:tappay/screens/pay/scan_screen.dart';

void main() {
  test('parseSessionId extracts id from tappay uri', () {
    expect(parseSessionId('tappay://s/abc-123'), 'abc-123');
  });

  test('parseSessionId falls back to raw value', () {
    expect(parseSessionId('raw-id'), 'raw-id');
  });

  test('parseSessionId handles null/empty', () {
    expect(parseSessionId(null), isNull);
    expect(parseSessionId(''), isNull);
  });
}
