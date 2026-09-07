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
//   * the history page is ITSELF a pushed route (/order-history over the
//     home shell), so at the flow's ROOT the same corner pill stands in
//     for the nav that folded when it was pushed (38a: "back is the one
//     corner pill"; the 12:36Z two-state rule: "back with no other
//     buttons sit at the corner") — a host passes [onExit] and the pill
//     pops the route; while a detail holds a plane the host's own pill
//     pops the pane instead, so there is never more than one;
//   * on one plane (38d) the host never builds this flow — the list is the
//     whole screen and the tap opens the shipped bottom sheet, unchanged.

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import '../board/board_status.dart';
import 'order_history_list.dart';

/// What the pushed pane needs to draw one finished order.
typedef HistoryDetail = ({OrderData order, BoardStatus status});

/// 38a — planes: the list declares TWO, a tapped order's details push
/// into the LAST plane, and back pops the pane.
class OrderHistoryPlaneFlow extends StatefulWidget {
  /// Draws one finished order inside the detail pane — the host passes the
  /// shipped `OrderDetailsModal(isHistoryOrder: true, order: order)`.
  final Widget Function(BuildContext context, OrderData order) detailBuilder;

  /// Back-pill glyph; the host passes its icon pack's arrow.
  final IconData backIcon;

  /// 347 at the ROOT: the flow's back pill while no detail is open. The
  /// history page is a pushed route, so the host passes what pops it
  /// (the same `Navigator.maybePop` the phone's corner pill falls back
  /// to); null draws no root pill — for a host that is not itself pushed.
  final VoidCallback? onExit;

  const OrderHistoryPlaneFlow({
    super.key,
    required this.detailBuilder,
    required this.backIcon,
    this.onExit,
  });

  @override
  State<OrderHistoryPlaneFlow> createState() => OrderHistoryPlaneFlowState();
}

class OrderHistoryPlaneFlowState extends State<OrderHistoryPlaneFlow> {
  HistoryDetail? _open;

  /// The order whose detail holds the last plane, if any.
  HistoryDetail? get open => _open;

  void openDetail(OrderData order, BoardStatus status) =>
      setState(() => _open = (order: order, status: status));

  void closeDetail() {
    if (_open == null) return;
    setState(() => _open = null);
  }

  @override
  Widget build(BuildContext context) {
    final HistoryDetail? open = _open;
    final Widget flow = ListPlaneFlow(
      backIcon: widget.backIcon,
      onCloseDetail: closeDetail,
      listBuilder: (context) => OrderHistoryList(
        selectedOrderId: open?.order.id,
        onOpenDetail: openDetail,
      ),
      detailName: open == null ? null : (open.order.id ?? ''),
      detailBuilder: open == null
          ? null
          : (context) => OrderHistoryDetailPane(
              order: open.order,
              onClosed: closeDetail,
              detailBuilder: widget.detailBuilder,
            ),
    );
    final VoidCallback? onExit = widget.onExit;
    // One back per screen: while a detail holds a plane the PlaneHost
    // draws its own pill (popping the pane), so the root pill yields.
    if (onExit == null || open != null) return flow;
    return Stack(
      children: [
        Positioned.fill(child: flow),
        // Parked exactly where PlaneHost parks its pill — bottom-END, 16
        // logical in from both edges, inside the SafeArea — so the two
        // states read as one control.
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: SafeArea(
            child: FloatingBackPill(
              back: FloatingNavBack(
                icon: widget.backIcon,
                label: AppHelpers.getTranslation(TrKeys.back),
                onTap: onExit,
              ),
            ),
          ),
        ),
      ],
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
