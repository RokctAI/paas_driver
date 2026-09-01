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

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The two order-queue helpers `paas_manager` kept on its `AppHelpers`
/// (`getUpdatableStatus` / `changeStatusButtonText`). base_sdk's AppHelpers is
/// a different, customer-shaped file (5.9% similar), so only these two moved —
/// they encode the seller's swipe-forward state machine and belong to the
/// order queues, not to base.
///
/// Enum members are base_sdk's `OrderStatus`: legacy `newOrder` -> `open`,
/// `onAWay` -> `onWay`; the wire strings switched on here are unchanged.
class SellerOrderStatus {
  SellerOrderStatus._();

  /// The next status a swipe should move an order with wire-status [value] to.
  static OrderStatus getUpdatableStatus(String? value) {
    switch (value) {
      case 'new':
        return OrderStatus.accepted;
      case 'accepted':
        return OrderStatus.ready;
      case 'ready':
        return OrderStatus.onWay;
      case 'on_a_way':
        return OrderStatus.delivered;
      case 'delivered':
        return OrderStatus.open;
      case 'canceled':
        return OrderStatus.canceled;
      default:
        return OrderStatus.accepted;
    }
  }

  /// The swipe-button label for an order currently in wire-status [value].
  static String changeStatusButtonText(String? value) {
    switch (value) {
      case 'new':
        return AppHelpers.getTranslation(TrKeys.swipeToAccept);
      case 'accepted':
        return AppHelpers.getTranslation(TrKeys.swipeToReady);
      case 'ready':
        return AppHelpers.getTranslation(TrKeys.swipeToWay);
      case 'on_a_way':
        return AppHelpers.getTranslation(TrKeys.swipeToDelivered);
      default:
        return AppHelpers.getTranslation(TrKeys.swipeToAccept);
    }
  }
}
