// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

// AppRating keeps ratings on the phone, sends them through the platform
// gateway, and offers the store only to a listed app at 4 stars or more.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Gw extends PlatformGateway {
  _Gw(this.fail);
  final bool fail;
  final calls = <Map<String, dynamic>>[];
  @override
  Future<dynamic> tenant(String cmd, [Map<String, dynamic>? payload]) async {
    expect(cmd, AppRating.cmd);
    if (fail) throw Exception('offline');
    calls.add(payload!);
    return {'ok': true};
  }
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test('a listed app offers the store to every rating; low stars also ask for a note', () {
    expect(AppRating.offersStore(listed: true), isTrue);
    expect(AppRating.offersStore(listed: false), isFalse);
    expect(AppRating.offersStore(), isFalse, reason: 'STORE_LISTED is off by default');
    expect(AppRating.asksNote(3), isTrue);
    expect(AppRating.asksNote(4), isFalse);
  });

  test('an unsent rating is kept and sent by the next flush', () async {
    await AppRating.save(2, comment: 'slow', gateway: _Gw(true));
    expect(AppRating.pending(), hasLength(1));
    final ok = _Gw(false);
    await AppRating.flush(gateway: ok);
    expect(AppRating.pending(), isEmpty);
    expect(ok.calls.single['stars'], 2);
    expect(ok.calls.single['comment'], 'slow');
  });
}
