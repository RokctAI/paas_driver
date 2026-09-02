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

// compliance-ignore-file: obs-flutter-trace
// Constants-only file: it makes no HTTP calls and holds no client; it is
// flagged solely because it lives under infrastructure/services/.

/// Courier-only constants carried out of paas_driver's host `AppConstants`.
///
/// base_sdk's AppConstants has no counterparts for these and the composer's
/// manifest "constants" key only OVERRIDES existing base fields (it never
/// adds new ones), so they live here as SDK-owned declarations.
abstract class CourierConstants {
  CourierConstants._();

  /// Hero tag shared by the profile avatar on the profile page and the
  /// edit-profile modal.
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// Legacy auth-phone-field switch, kept dart-define-driven exactly as the
  /// host declared it (used by the profile edit modal's phone field).
  static bool isSpecificNumberEnabled =
      const bool.fromEnvironment('IS_SPECIFIC_NUMBER_ENABLED');
}
