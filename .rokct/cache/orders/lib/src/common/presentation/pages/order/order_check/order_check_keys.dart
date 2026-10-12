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

/// The wire translation keys the order checkout screen uses that base_sdk's
/// `TrKeys` does not define.
///
/// `lib/` references these by WIRE STRING (the LoadKeys precedent): raw
/// base_sdk has no `TrKeys.payment`, and `AppHelpers.getTranslation`
/// humanizes any key the translation store has not been seeded with yet.
abstract final class OrderCheckKeys {
  static const String payment = 'payment';
}
