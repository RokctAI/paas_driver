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

import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:merchants_sdk/src/manager/utils/week_days.dart';

/// Small display helpers ported from paas_manager's `AppHelpers` members
/// that base_sdk does not carry (`truncate`,
/// `getShopWorkingTimeForToday`).
abstract class RestaurantHelpers {
  RestaurantHelpers._();

  static String truncate(String value, int length) =>
      value.length > length ? value.substring(0, length) : value;

  /// Today's opening hours as `'HH:mm - HH:mm'`, or null when the shop is
  /// closed today / has no schedule — the caller renders its own
  /// "closed today" translation (the legacy helper returned the translated
  /// string itself; returning null keeps raw tr-key strings out of SDK lib
  /// code, where injected TrKeys members don't exist yet).
  ///
  /// Works from the passed [shop] instead of the legacy typed
  /// `LocalStorage.getShop()`, which base_sdk does not have. Time strings
  /// tolerate both legacy `'HH-mm'` and `'HH:mm(:ss)'` storage — only the
  /// digit positions are read.
  static String? workingTimeForToday(ShopData? shop) {
    final days = shop?.shopWorkingDays;
    if (days == null || days.isEmpty) return null;
    final today = WeekDays.values[DateTime.now().weekday - 1].name;
    for (final day in days) {
      if (day.day?.toLowerCase() == today) {
        if (day.disabled ?? false) return null;
        final from = day.from;
        final to = day.to;
        if (from == null || to == null || from.length < 5 || to.length < 5) {
          return null;
        }
        return '${from.substring(0, 2)}:${from.substring(3, 5)}'
            ' - ${to.substring(0, 2)}:${to.substring(3, 5)}';
      }
    }
    return null;
  }
}
