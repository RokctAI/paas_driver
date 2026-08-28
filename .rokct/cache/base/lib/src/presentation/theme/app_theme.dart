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
