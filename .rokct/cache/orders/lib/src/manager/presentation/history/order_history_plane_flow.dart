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

// ORDER HISTORY ON PLANES — the approved 38a plane shape (Ray 2026-08-30
// 12:23Z, "33 list language = STANDARD for all lists"), lifted out of the
// installed `order_history.dart` so the plane behaviour is package code
// with a widget test at every width, the installed file being the thin
// host shell (it supplies the `${package}` OrderDetailsModal).
//
//   * the LIST DECLARES 2 (ListDetailFlow's default): at the two-plane
//     fold it fills the screen exactly, two plane-aligned card columns;
//     at three planes the leftover plane TRAILS BARE at the end (the
//     10:47Z rule 38b draws for the sibling list) — PlaneHost's empty
//     stage, nothing stretched;
//   * a tapped order's details push with the DEFAULT one-plane claim into
//     the LAST plane (38a's 12:02Z sheet fork: the shipped bottom sheet
//     becomes a PANE), the list compressing to what remains;
//   * a pushed page holds a plane, so the corner back pill (347) shows at
//     the bottom-END and pops the pane; back restores the spread;
//   * on one plane (38d) the host never builds this flow — the list is the
//     whole screen and the tap opens the shipped bottom sheet, unchanged.

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import '../board/board_status.dart';
import 'order_history_list.dart';

/// What the pushed pane needs to draw one finished order.
typedef HistoryDetail = ({OrderData order, BoardStatus status});

/// 38a — planes: the list declares TWO, a tapped order's details push
/// into the LAST plane, and back pops the pane.
class OrderHistoryPlaneFlow extends StatelessWidget {
  /// Draws one finished order inside the detail pane — the host passes the
  /// shipped `OrderDetailsModal(isHistoryOrder: true, order: order)`.
  final Widget Function(BuildContext context, OrderData order) detailBuilder;

  /// Back-pill glyph; the host passes its icon pack's arrow.
  final IconData backIcon;

  const OrderHistoryPlaneFlow({
    super.key,
    required this.detailBuilder,
    required this.backIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListDetailFlow<HistoryDetail>(
      backIcon: backIcon,
      detailNameOf: (open) => open.order.id ?? '',
      listBuilder: (context, flow) => OrderHistoryList(
        selectedOrderId: flow.open?.order.id,
        onOpenDetail: (order, status) =>
            flow.openDetail((order: order, status: status)),
      ),
      detailBuilder: (context, open, flow) => OrderHistoryDetailPane(
        order: open.order,
        onClosed: flow.closeDetail,
        detailBuilder: detailBuilder,
      ),
    );
  }
}

/// The ORDER-DETAILS PANE holding the LAST plane (chips 701/702/703): the
/// same [detailBuilder] surface the phone sheet shows, hosted in a
/// pane-local navigator so any `Navigator.pop` inside it closes the PLANE —
/// never the history route beneath it. A finished order carries no
/// status-change buttons, so the pane is the modal's read-only face plus
/// Ray's 12:23Z amendment, the receipt reprint action.
class OrderHistoryDetailPane extends StatelessWidget {
  final OrderData order;
  final VoidCallback onClosed;
  final Widget Function(BuildContext context, OrderData order) detailBuilder;

  const OrderHistoryDetailPane({
    super.key,
    required this.order,
    required this.onClosed,
    required this.detailBuilder,
  });

  static const String sentinelName = '_history-detail-sentinel';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppStyle.surfaceDark,
      child: ClipRect(
        child: Navigator(
          observers: [_PopToSentinelObserver(onClosed)],
          onGenerateInitialRoutes: (navigator, initialRoute) => [
            MaterialPageRoute(
              settings: const RouteSettings(name: sentinelName),
              builder: (_) => ColoredBox(color: AppStyle.surfaceDark),
            ),
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: AppStyle.surfaceDark,
                body: SafeArea(child: detailBuilder(context, order)),
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
    if (previousRoute?.settings.name == OrderHistoryDetailPane.sentinelName) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onPoppedToSentinel());
    }
  }
}
