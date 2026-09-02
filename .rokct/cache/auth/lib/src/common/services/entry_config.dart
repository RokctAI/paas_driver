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
