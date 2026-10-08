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

// Ray, 2026-10-05: an error still showed when the app loaded, after #129
// silenced checkLanguage. Pins every call the login page makes by itself
// on load: none of them may surface an error. LoginPage needs Firebase and
// the host's registry, so its source is pinned, like the other auth tests.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _page =
    'lib/src/common/presentation/pages/auth/login/login_page.dart';

void main() {
  final src = File(_page).readAsStringSync();

  test('initState probes languages without userInitiated (silent)', () {
    expect(
      src,
      contains('ref.read(loginProvider.notifier).checkLanguage(context);'),
    );
    expect(src, isNot(contains('userInitiated: true')));
  });

  test('the auto-select of a single language stays silent', () {
    // base_sdk 1.83.5: makeSelectedLang defaults to userInitiated: false.
    expect(
      src,
      contains('ref.read(languageProvider.notifier).makeSelectedLang(context);'),
    );
  });

  test('the initial dynamic link lookup cannot escape as an error', () {
    final call = src.indexOf('dynamicLinks.getInitialLink()');
    expect(call, greaterThan(0));
    final tryAt = src.lastIndexOf('try {', call);
    expect(tryAt, greaterThan(0));
    expect(src.substring(tryAt, call), isNot(contains('}')));
    expect(src, isNot(contains('FirebaseDynamicLinks.instance.getInitialLink')));
  });

  test('no load-time path on the page shows a snackbar', () {
    expect(src, isNot(contains('showCheckTopSnackBar')));
    expect(src, isNot(contains('showNoConnectionSnackBar')));
    expect(src, isNot(contains('AuthErrorPresenter')));
  });
}
