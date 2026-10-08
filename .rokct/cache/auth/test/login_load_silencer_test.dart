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


// The login screen's load-time probes stay silent; only a user action may
// surface a backend or no-connection error.

import 'package:flutter_test/flutter_test.dart';

import 'package:auth_sdk/src/common/services/login_load_silencer.dart';

void main() {
  test('a load-time probe never surfaces an error', () {
    expect(shouldSurfaceLoginError(userInitiated: false), isFalse);
  });

  test('a user action may surface an error', () {
    expect(shouldSurfaceLoginError(userInitiated: true), isTrue);
  });
}
