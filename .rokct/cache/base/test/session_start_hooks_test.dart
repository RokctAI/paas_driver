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

import 'package:base_sdk/src/services/session_start_hooks.dart';

void main() {
  setUp(SessionStartHooks.clearAll);
  tearDown(SessionStartHooks.clearAll);

  test('is inert with nothing registered', () async {
    await SessionStartHooks.run();
    expect(SessionStartHooks.registeredIds, isEmpty);
  });

  test('runs a registered hook', () async {
    var ran = 0;
    SessionStartHooks.register('push', () async => ran++);
    await SessionStartHooks.run();
    expect(ran, 1);
  });

  test('re-registering an id replaces it instead of stacking', () async {
    var first = 0;
    var second = 0;
    SessionStartHooks.register('dup', () async => first++);
    SessionStartHooks.register('dup', () async => second++);
    await SessionStartHooks.run();
    expect(first, 0);
    expect(second, 1);
    expect(SessionStartHooks.registeredIds.length, 1);
  });

  test('a throwing hook does not stop the others', () async {
    var ran = 0;
    SessionStartHooks.register('bad', () async => throw StateError('boom'));
    SessionStartHooks.register('good', () async => ran++);
    await SessionStartHooks.run();
    expect(ran, 1);
  });

  test('unregister drops a hook', () async {
    var ran = 0;
    SessionStartHooks.register('gone', () async => ran++);
    SessionStartHooks.unregister('gone');
    await SessionStartHooks.run();
    expect(ran, 0);
  });
}
