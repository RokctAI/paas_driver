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


import 'dart:async';
import 'dart:io';

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/session_start_hooks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auth_sdk/src/common/services/platform_support.dart';

class _RecordingUserRepository implements UserRepositoryFacade {
  final List<String?> tokens = <String?>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateFirebaseToken) {
      tokens.add(invocation.positionalArguments.first as String?);
      return Future<void>.value();
    }
    throw StateError('unexpected ${invocation.memberName}');
  }
}

void main() {
  setUp(() {
    SessionStartHooks.clearAll();
    // No Firebase in flutter_test: take the platform where the FCM sync is
    // a guarded no-op, so only the hooks are under test.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  });

  tearDown(() {
    SessionStartHooks.clearAll();
    debugDefaultTargetPlatformOverride = null;
  });

  test('completeSessionStart runs the registered session-start hooks',
      () async {
    var ran = 0;
    SessionStartHooks.register('probe', () async => ran++);
    await completeSessionStart(_RecordingUserRepository());
    await pumpEventQueue();
    expect(ran, 1);
  });

  test('a hook that waits on the user never holds up the sign-in', () async {
    final Completer<void> prompt = Completer<void>();
    SessionStartHooks.register('slow', () => prompt.future);
    await completeSessionStart(_RecordingUserRepository())
        .timeout(const Duration(seconds: 1));
    prompt.complete();
  });

  test('every sign-in path goes through completeSessionStart', () {
    // The notifiers that establish a session must not call syncFcmToken
    // directly any more, or that path would skip the hooks.
    for (final String path in <String>[
      'lib/src/common/application/auth/login/login_notifier.dart',
      'lib/src/common/application/auth/register/register_notifier.dart',
      'lib/src/common/application/auth/confirmation/'
          'register_confirmation_notifier.dart',
      'lib/src/common/services/restore_credential_service.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source.contains('syncFcmToken('), isFalse, reason: path);
      expect(source.contains('completeSessionStart('), isTrue, reason: path);
    }
  });
}
