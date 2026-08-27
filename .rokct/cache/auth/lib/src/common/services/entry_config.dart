// Copyright (c) 2026 RokctAI
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

// compliance-ignore-file: obs-flutter-trace (false positive: this file makes
// no network calls at all — it is pure composition config with no imports;
// the check fires solely because the file's path contains "services")

/// Composition-declared entry-surface capabilities — the login twin of
/// [AuthRegistrationConfig] (registration_config.dart).
///
/// auth_sdk owns the ONE login page every composed app shows, but whether
/// that app wants a guest path past it is composition DATA (Ray's rule:
/// "let it be there in all apps, and make home sdk tell it doesnt need
/// it"). The default keeps the affordance ON, so consumer apps
/// (customer/supacharge) get guest entry with no declaration at all; an
/// app whose home surface has nothing for a guest (driver/manager) turns
/// it off through the existing manifest "integrations" channel, targeting
/// the `// @auth-entry-config` placeholder in the installed
/// auth_route_pages.dart shell (e.g. delivery_sdk's driver flavor
/// contributing `AuthEntryConfig.showsGuestSkip = false;`).
class AuthEntryConfig {
  AuthEntryConfig._();

  /// Whether the login page offers its "Skip" affordance — using the app
  /// without an account. ON by default: only a composition whose home SDK
  /// declares it has no guest surface hides it.
  static bool showsGuestSkip = true;
}
