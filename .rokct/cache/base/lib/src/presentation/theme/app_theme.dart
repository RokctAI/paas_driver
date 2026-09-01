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


/// Per-app theme configuration seam.
///
/// Mutable static by design — the same injection pattern as
/// `AppStyle.injectBrandColors` / the shimmer statics: base_sdk must not own
/// a composed app's default look, so app glue sets this in `main()` before
/// `runApp` and the kernel merely reads it.
abstract class AppTheme {
  AppTheme._();

  /// The theme polarity a composed app boots with when the user has never
  /// chosen a theme (no persisted `keyAppThemeMode` preference yet).
  ///
  /// Consulted by `LocalStorage.getAppThemeMode()` as the fallback value, so
  /// both the Material `themeMode` (via `AppNotifier`) and the AppStyle
  /// surface tokens resolve to this polarity on a fresh install. Once the
  /// user flips the profile theme toggle, the stored preference always wins.
  ///
  /// Kernel default is `false` (light). Dark-first apps (driver, manager)
  /// set `AppTheme.defaultDarkMode = true;` in their app glue before
  /// `runApp` to keep their current look.
  static bool defaultDarkMode = false;
}
