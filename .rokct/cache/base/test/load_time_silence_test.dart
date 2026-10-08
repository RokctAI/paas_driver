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

// Ray, 2026-10-05: an auth/backend error still showed when the app loaded,
// before he did anything. Pins the rule (load-time = silent, offline =
// never an error) and the load-time call sites that follow it. The
// notifiers need a live repository and BuildContext, so the call sites are
// pinned on their source, the same way the auth_sdk tests do.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/services/load_silence.dart';

String _src(String path) => File(path).readAsStringSync();

void main() {
  group('shouldSurfaceLoadError', () {
    test('load-time work never surfaces', () {
      expect(shouldSurfaceLoadError(userInitiated: false), isFalse);
      expect(
        shouldSurfaceLoadError(userInitiated: false, offline: true),
        isFalse,
      );
    });

    test('offline is never an error, even for a user action', () {
      expect(shouldSurfaceLoadError(userInitiated: true, offline: true),
          isFalse);
    });

    test('a user action may surface a server-answered failure', () {
      expect(shouldSurfaceLoadError(userInitiated: true), isTrue);
    });
  });

  group('load-time call sites', () {
    test('LanguageNotifier is silent unless the person acted', () {
      final s = _src('lib/src/application/language/language_notifier.dart');
      expect(s, isNot(contains('showNoConnectionSnackBar')));
      expect(s, isNot(contains('replaceNoConnectionRoute')));
      expect(
        'shouldSurfaceLoadError(userInitiated: userInitiated)'
            .allMatches(s)
            .length,
        2,
      );
      expect(s, contains('bool userInitiated = false'));
    });

    test('ProfileNotifier.fetchUser is silent on load and offline', () {
      final s = _src('lib/src/application/profile/profile_notifier.dart');
      final start = s.indexOf('Future<void> fetchUser(');
      final end = s.indexOf('\n  }\n', start);
      final body = s.substring(start, end);
      expect(body, contains('bool userInitiated = false'));
      expect(body, isNot(contains('showNoConnectionSnackBar')));
      expect(body, contains('shouldSurfaceLoadError('));
    });

    test('splash never opens on the no-connection page for offline', () {
      final s = _src(
          'lib/src/presentation/pages/initial/splash/splash_page.dart');
      // Only the composition-bug fallback in _leaveSplash may still use it.
      expect('replaceNoConnectionRoute'.allMatches(s).length, 1);
      expect(s, contains("goNoInternet: () => unawaited(_proceedOffline())"));
    });
  });
}
