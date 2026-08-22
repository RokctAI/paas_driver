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
