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

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/canceled/canceled_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/cooking/cooking_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/delivered/delivered_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/ready/ready_orders_provider.dart';

import 'board_prefs.dart';
import 'board_status.dart';

/// One switchboard for the seven queue notifiers, so the board columns,
/// the phone list tabs and the header's date filter all refresh/page the
/// same way. [isRefresh] false = page in the next 10 ("View more · +N").
/// The current [boardPrefsProvider] date range always rides along.
void fetchBoardColumn(
  WidgetRef ref,
  BuildContext context,
  BoardStatus status, {
  required bool isRefresh,
}) {
  final prefs = ref.read(boardPrefsProvider);
  final from = prefs.fromWire;
  final to = prefs.toWire;
  switch (status) {
    case BoardStatus.newOrder:
      // activeTabIndex -1: neither board nor list mode builds the legacy
      // tab layout's pull-to-refresh controller, so the notifier must not
      // poke it.
      ref
          .read(newOrdersProvider.notifier)
          .fetchNewOrders(
            context: context,
            isRefresh: isRefresh,
            activeTabIndex: -1,
            from: from,
            to: to,
          );
      break;
    case BoardStatus.accepted:
      ref
          .read(acceptedOrdersProvider.notifier)
          .fetchAcceptedOrders(isRefresh: isRefresh, from: from, to: to);
      break;
    case BoardStatus.cooking:
      ref
          .read(cookingOrdersProvider.notifier)
          .fetchCookingOrders(isRefresh: isRefresh, from: from, to: to);
      break;
    case BoardStatus.ready:
      ref
          .read(readyOrdersProvider.notifier)
          .fetchReadyOrders(isRefresh: isRefresh, from: from, to: to);
      break;
    case BoardStatus.onWay:
      ref
          .read(onAWayOrdersProvider.notifier)
          .fetchOnAWayOrders(isRefresh: isRefresh, from: from, to: to);
      break;
    case BoardStatus.delivered:
      ref
          .read(deliveredOrdersProvider.notifier)
          .fetchDeliveredOrders(isRefresh: isRefresh, from: from, to: to);
      break;
    case BoardStatus.canceled:
      ref
          .read(canceledOrdersProvider.notifier)
          .fetchCanceledOrders(isRefresh: isRefresh, from: from, to: to);
      break;
  }
}

/// Refresh every column the current role sees (the date filter changed, or
/// a full board refresh) — the waiter's hidden On-the-way queue included
/// only when the role shows it.
void refreshBoardColumns(WidgetRef ref, BuildContext context, {String? role}) {
  for (final status in BoardRules.columnsFor(role: role)) {
    fetchBoardColumn(ref, context, status, isRefresh: true);
  }
}
