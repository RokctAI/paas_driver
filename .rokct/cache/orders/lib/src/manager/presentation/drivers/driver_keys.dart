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

/// The wire translation keys the shop's own-driver roster uses.
///
/// `lib/` references translation keys by WIRE STRING, not through base_sdk's
/// `TrKeys`: this package analyzes against raw base_sdk, where the
/// composer-injected constants do not exist (the [LoadKeys] precedent next
/// door). The values are declared in `manifest.json` under the manager
/// block, and `AppHelpers.getTranslation` humanizes any key the translation
/// store has not been seeded with yet.
abstract final class DriverKeys {
  static const String myDrivers = 'my_drivers';
  static const String manageDrivers = 'manage_drivers';
  static const String addDriver = 'add_driver';
  static const String removeDriver = 'remove_driver';
  static const String noOwnDriversYet = 'no_own_drivers_yet';
  static const String ownDriversExplainer =
      'a_shop_with_its_own_drivers_can_only_load_those_drivers';
  static const String couldNotReadYourDrivers = 'could_not_read_your_drivers';
  static const String couldNotAddDriver = 'could_not_add_driver';
  static const String couldNotRemoveDriver = 'could_not_remove_driver';
  static const String driverAdded = 'driver_added';
  static const String driverRemoved = 'driver_removed';
  static const String searchDrivers = 'search_drivers';
  static const String noDriversToAdd = 'no_drivers_left_to_add';
  static const String retired = 'retired';
  static const String removeDriverFromRoster =
      'take_this_driver_off_your_roster';
  static const String theyCanNoLongerBeLoaded =
      'they_can_no_longer_be_issued_a_load_from_this_shop';
  static const String cancel = 'cancel';
  static const String drivers = 'drivers';
}
