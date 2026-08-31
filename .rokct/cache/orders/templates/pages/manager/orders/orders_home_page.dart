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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${package}/presentation/pages/orders/details/order_details_modal.dart';
import 'package:base_sdk/src/presentation/adaptive/adaptive_shell.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'widgets/board/orders_board_view.dart';
import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/ready/ready_orders_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_header.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_map_dialog.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_plane_flow.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_prefs.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/board/orders_list_mode.dart';

/// The manager orders workspace, upgraded to the approved design
/// ("31b adopt 31a but uses our base theme" — Ray 2026-08-29 12:10Z;
/// renders approved 13:06Z "33a is approved" and 13:53Z
/// "approved: 34a , 33d,33b"):
///
/// * WIDE windows — the seven-column colour-coded kanban board (33a) with
///   the workspace header (board/list toggle, date-range filter, sound
///   bell). Per 33d, the page is hosted in base_sdk's plane model: the
///   board declares ALL planes; tapping a card pushes the order detail
///   with the DEFAULT one-plane claim into the LAST plane, the board
///   yields/compresses, and the nav folds to the corner back pill.
/// * PHONES — the POS's list mode (33b): one scrollable row of status
///   tabs with counts over a single list; details open as the modal
///   bottom sheet, exactly the degradation the plane model prescribes for
///   one-plane screens.
///
/// Both layouts share the queue providers, so resizing the window never
/// refetches or loses queue state.
class OrdersHomePage extends ConsumerStatefulWidget {
  const OrdersHomePage({super.key});

  @override
  ConsumerState<OrdersHomePage> createState() => _OrdersHomePageState();
}

class _OrdersHomePageState extends ConsumerState<OrdersHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The four legacy queues; the board/list widgets fetch their own
      // cooking + history columns. activeTabIndex -1: neither mode builds
      // the retired tab layout's pull-to-refresh controller.
      ref
          .read(newOrdersProvider.notifier)
          .fetchNewOrders(
            context: context,
            isRefresh: true,
            activeTabIndex: -1,
          );
      ref
          .read(acceptedOrdersProvider.notifier)
          .fetchAcceptedOrders(isRefresh: true);
      ref.read(readyOrdersProvider.notifier).fetchReadyOrders(isRefresh: true);
      if (LocalStorage.getUser()?.role != BoardRules.waiterRole) {
        ref
            .read(onAWayOrdersProvider.notifier)
            .fetchOnAWayOrders(isRefresh: true);
      }
    });
  }

  void _openDetailModal(OrderData order, BoardStatus status) {
    AppHelpers.showCustomModalBottomSheet(
      paddingTop: MediaQuery.paddingOf(context).top + 60,
      context: context,
      radius: 12,
      modal: OrderDetailsModal(
        order: order,
        isHistoryOrder: status.isHistory ? true : null,
      ),
      isDarkMode: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: AdaptiveShell(compact: _buildCompact, expanded: _buildExpanded),
    );
  }

  /// Phones: header + the POS list mode (33b); board still reachable via
  /// the toggle (it scrolls sideways).
  Widget _buildCompact(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OrdersBoardHeader(compact: true),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final prefs = ref.watch(boardPrefsProvider);
                  return prefs.listView(compact: true)
                      ? OrdersListMode(
                          onOpenDetail: _openDetailModal,
                          onOpenMap: (order) =>
                              BoardMapDialog.show(context, order),
                        )
                      : const OrdersBoardView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wide windows: the plane-hosted workspace (33a + 33d).
  Widget _buildExpanded(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: SafeArea(
        child: OrdersBoardPlaneFlow(
          boardBuilder: (context, flow) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OrdersBoardHeader(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final prefs = ref.watch(boardPrefsProvider);
                    return prefs.listView(compact: false)
                        ? OrdersListMode(
                            onOpenDetail: flow.openDetail,
                            onOpenMap: (order) =>
                                BoardMapDialog.show(context, order),
                          )
                        : OrdersBoardView(
                            onOpenDetail: flow.openDetail,
                            selectedOrderId: flow.openOrderId,
                          );
                  },
                ),
              ),
            ],
          ),
          detailBuilder: (context, order, status, flow) => KeyedSubtree(
            key: ValueKey('order-detail-${order.id}'),
            child: _OrderDetailPane(
              order: order,
              status: status,
              onClosed: flow.closeDetail,
            ),
          ),
        ),
      ),
    );
  }
}

/// The pushed order detail holding the LAST plane (33d): the same
/// [OrderDetailsModal] the phone sheet shows, hosted in a pane-local
/// navigator so the modal's own `Navigator.pop` (fired after a status
/// advance) closes the PLANE — never the workspace route beneath it.
class _OrderDetailPane extends StatelessWidget {
  final OrderData order;
  final BoardStatus status;
  final VoidCallback onClosed;

  const _OrderDetailPane({
    required this.order,
    required this.status,
    required this.onClosed,
  });

  static const String _sentinelName = '_order-detail-sentinel';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppStyle.surfaceDark,
      child: ClipRect(
        child: Navigator(
          observers: [_PopToSentinelObserver(onClosed)],
          onGenerateInitialRoutes: (navigator, initialRoute) => [
            MaterialPageRoute(
              settings: const RouteSettings(name: _sentinelName),
              builder: (_) => ColoredBox(color: AppStyle.surfaceDark),
            ),
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: AppStyle.surfaceDark,
                body: SafeArea(
                  child: OrderDetailsModal(
                    order: order,
                    isHistoryOrder: status.isHistory ? true : null,
                  ),
                ),
              ),
            ),
          ],
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => ColoredBox(color: AppStyle.surfaceDark),
          ),
        ),
      ),
    );
  }
}

/// Watches the pane-local navigator: when the detail pops back onto the
/// sentinel root, the plane has nothing left to show — fold it.
class _PopToSentinelObserver extends NavigatorObserver {
  final VoidCallback onPoppedToSentinel;

  _PopToSentinelObserver(this.onPoppedToSentinel);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.settings.name == _OrderDetailPane._sentinelName) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onPoppedToSentinel());
    }
  }
}
