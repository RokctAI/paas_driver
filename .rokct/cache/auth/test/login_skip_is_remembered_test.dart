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


// Ray, 2026-10-10: "make skip remember that I have skipped before". The
// login page's Skip must be stored, so base_sdk's splash (SignedOutEntry)
// lands the next cold start home instead of back on this page. A widget test
// would need Firebase, the language sheet and a host router; the contract is
// one call in one method, so it is pinned on the source like the load-silence
// test beside this one.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _page =
    'lib/src/common/presentation/pages/auth/login/login_page.dart';

void main() {
  final src = File(_page).readAsStringSync();

  String skipBody() {
    final start = src.indexOf('void _skip() {');
    expect(start, greaterThan(0), reason: '_skip() not found');
    final end = src.indexOf('\n  }\n', start);
    return src.substring(start, end);
  }

  test('Skip remembers the guest choice before landing', () {
    final body = skipBody();
    final remember = body.indexOf('SignedOutEntry.rememberGuest()');
    final land = body.indexOf('RegistrationFlow.defaultLanding(context)');
    expect(remember, greaterThan(0));
    expect(land, greaterThan(remember));
  });

  test('Skip is remembered with a composed onboarding intro too', () {
    // supacharge composes an intro; Skip there must be remembered like the
    // launcher's, so the next cold start does not force the login page.
    final body = skipBody();
    final intro = body.indexOf('_showIntroPage();');
    final remember = body.indexOf('SignedOutEntry.rememberGuest()');
    expect(intro, greaterThan(0));
    expect(remember, greaterThan(0));
    expect(remember, lessThan(intro));
  });
}
