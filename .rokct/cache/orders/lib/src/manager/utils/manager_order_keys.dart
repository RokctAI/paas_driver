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

/// The wire translation keys the manager's order surfaces use (the
/// swipe-to-advance button and the POS customer picker).
///
/// `lib/` references translation keys by WIRE STRING, not through
/// base_sdk's `TrKeys`: this package analyzes against raw base_sdk, where
/// the composer-injected constants do not exist (the LoadKeys precedent).
/// The values are declared in `manifest.json` under the manager block, and
/// `AppHelpers.getTranslation` humanizes any key the translation store has
/// not been seeded with yet.
abstract final class ManagerOrderKeys {
  static const String swipeToAccept = 'swipe_to_accept';
  static const String swipeToReady = 'swipe_to_ready';
  static const String swipeToWay = 'swipe_to_way';
  static const String swipeToDelivered = 'swipe_to_delivered';
  static const String noName = 'no_name';
}
