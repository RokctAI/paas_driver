import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/handlers/demo_gateway_interceptor.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 9, 25, 12, 30);
  Object? r(String s) => DemoFixtures.resolveTimeToken(s, now);

  test('plain tokens', () {
    expect(r(r'$now_iso'), '2026-09-25T12:30:00.000Z');
    expect(r(r'$now_ms'), now.millisecondsSinceEpoch);
    expect(r(r'$today'), '2026-09-25');
  });

  test('offsets in every unit', () {
    expect(r(r'$now_iso-30d'), '2026-08-26T12:30:00.000Z');
    expect(r(r'$now_iso+2h'), '2026-09-25T14:30:00.000Z');
    expect(r(r'$now_iso-45m'), '2026-09-25T11:45:00.000Z');
    expect(r(r'$now_ms-7d'),
        now.subtract(const Duration(days: 7)).millisecondsSinceEpoch);
    expect(r(r'$today+2w'), '2026-10-09');
    expect(r(r'$today-1d'), '2026-09-24');
  });

  test('non-tokens are left alone', () {
    for (final s in [r'$now_iso-1y', r'$now_iso -2d', r'$now_iso-d',
        r'x$now_iso', r'$now_iso-2d ', r'$yesterday', 'hello']) {
      expect(r(s), isNull, reason: s);
    }
  });

  test('tokens resolve inside fixtures', () async {
    DemoFixtures.reset();
    addTearDown(DemoFixtures.reset);
    DemoFixtures.loader = (k) async => k == 'd/x.json'
        ? r'{"due": "$today+3d", "at": ["$now_iso-1h"], "keep": "$now_iso-1y"}'
        : null;
    DemoFixtures.registerAssetDirectory('d');
    final m = await DemoFixtures.answer('x', {}) as Map;
    expect(m['due'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(DateTime.parse((m['at'] as List).first as String).isUtc, isTrue);
    expect(m['keep'], r'$now_iso-1y');
  });
}
