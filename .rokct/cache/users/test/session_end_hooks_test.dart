// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter_test/flutter_test.dart';

import 'package:users_sdk/src/common/services/session_end_hooks.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(SessionEndHooks.clearAll);
  tearDown(SessionEndHooks.clearAll);

  test('with nothing registered, running is a no-op', () async {
    // The state every existing consumer is in: behaviour is unchanged.
    await SessionEndHooks.run();
    expect(SessionEndHooks.registeredIds, isEmpty);
  });

  test('a registered hook runs on session end', () async {
    var ran = 0;
    SessionEndHooks.register('restore_credentials', () async => ran++);
    await SessionEndHooks.run();
    expect(ran, 1);
  });

  test('re-registering the same id replaces rather than stacks', () async {
    var first = 0;
    var second = 0;
    SessionEndHooks.register('dup', () async => first++);
    SessionEndHooks.register('dup', () async => second++);
    await SessionEndHooks.run();
    expect(first, 0);
    expect(second, 1);
    expect(SessionEndHooks.registeredIds.length, 1);
  });

  test('unregister removes a hook', () async {
    var ran = 0;
    SessionEndHooks.register('x', () async => ran++);
    SessionEndHooks.unregister('x');
    await SessionEndHooks.run();
    expect(ran, 0);
  });

  test('one failing hook does not stop the others', () async {
    // Sign-out must never be blocked by tidy-up that went wrong.
    var ran = 0;
    SessionEndHooks.register('bad', () async => throw StateError('boom'));
    SessionEndHooks.register('good', () async => ran++);
    await SessionEndHooks.run();
    expect(ran, 1);
  });
}
