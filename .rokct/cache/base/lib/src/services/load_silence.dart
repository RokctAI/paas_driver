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

import 'package:flutter/foundation.dart';

/// The one load-time silence rule (Ray, 2026-10-05: an auth or backend
/// error still showed when the app loaded, before he did anything).
///
/// Work the app starts by itself — splash, app start, a page's initState,
/// the language list, translations, the profile refresh — has no person
/// waiting on it, so its failures are debug output only. An error is shown
/// only for something the person did (a tap, a save, a pull-to-refresh),
/// and being offline is never an error either way.
bool shouldSurfaceLoadError({
  required bool userInitiated,
  bool offline = false,
}) =>
    userInitiated && !offline;

/// Debug-only record of a failure [shouldSurfaceLoadError] kept off screen.
void logSilencedLoadError(String where, Object? detail) {
  debugPrint('==> $where: silent load-time failure: $detail');
}
