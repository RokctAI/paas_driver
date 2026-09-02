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
