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

import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/services/minimum_build.dart';

void main() {
  UpdateRequired? decide(Map<String, dynamic> data, {List<String> keys = const ['app.sticks.work', 'sticks'], int? build = 7, String platform = 'android'}) =>
      MinimumBuild.decide(data, keys: keys, build: build, platform: platform);

  test('below the app\'s minimum needs an update, with this platform\'s link', () {
    final u = decide({
      'min_builds': {'app.sticks.work': 9},
      'update_urls': {'app.sticks.work': {'android': 'https://x.test/a.apk', 'windows': 'https://x.test/w.exe'}},
    })!;
    expect(u.minBuild, 9);
    expect(u.build, 7);
    expect(u.app, 'app.sticks.work');
    expect(u.url, 'https://x.test/a.apk');
    expect(decide({'min_builds': {'app.sticks.work': 9}, 'update_urls': {'*': 'https://x.test/all'}}, platform: 'windows')!.url, 'https://x.test/all');
  });

  test('at or above the minimum, or no entry, needs nothing', () {
    expect(decide({'min_builds': {'app.sticks.work': 7}}), isNull);
    expect(decide({'min_builds': {'other.app': 99}}), isNull);
    expect(decide({'status': 'ok'}), isNull);
  });

  test('a later key and "*" cover apps listed under another name', () {
    expect(decide({'min_builds': {'sticks': '8'}})!.app, 'sticks');
    expect(decide({'min_builds': {'*': 8}})!.minBuild, 8);
    expect(decide({'min_builds': {'app.sticks.work': 1, '*': 99}}), isNull);
  });

  test('fails open: unreadable build, bad minimum, unsafe link', () {
    expect(decide({'min_builds': {'*': 9}}, build: null), isNull);
    expect(decide({'min_builds': {'*': 9}}, build: 0), isNull);
    expect(decide({'min_builds': {'*': 'soon'}}), isNull);
    expect(decide({'min_builds': {'*': 9}, 'update_urls': {'*': 'javascript:alert(1)'}})!.url, isNull);
  });

  test('check() uses the latest answer and forgets it when there is none', () async {
    addTearDown(MinimumBuild.reset);
    MinimumBuild.identity = () async => (keys: <String>['app.sticks.work'], build: 3);
    MinimumBuild.platform = () => 'android';
    MinimumBuild.remember({'min_builds': {'*': 4}});
    expect((await MinimumBuild.check())!.minBuild, 4);
    MinimumBuild.remember(null);
    expect(await MinimumBuild.check(), isNull);
  });
}
