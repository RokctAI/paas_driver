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

// ORDER HISTORY — the standard list language (approved design strip
// frames 38a + 38d, Ray 2026-08-30 12:23Z: "33 list language = STANDARD
// for all lists").
//
// * WIDE windows (38a) — the list DECLARES 2 planes and its cards flow in
//   two plane-aligned columns; tapping an order pushes its details into
//   the LAST plane as a PANE (the 12:02Z SHEET FORK: at plane widths the
//   shipped OrderDetailsModal bottom sheet becomes a pane), and the nav
//   folds to the corner back pill at the bottom-END (chip 347).
// * PHONES (38d) — the exact same shape on one plane, and the tap opens
//   the shipped OrderDetailsModal as a bottom sheet, unchanged. The
//   shipped page's TWO floating buttons dissolve: the date filter moved
//   into the header (chip 358) and back is the one corner pill.
//
// The list body itself lives in the SDK
// (`orders_sdk/src/manager/presentation/history/order_history_list.dart`)
// so it is unit-testable; this installed file is the host shell.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/adaptive/adaptive_shell.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:${package}/presentation/pages/orders/details/order_details_modal.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/history/order_history_list.dart';

/// What the pushed pane needs to draw one finished order.
typedef HistoryDetail = ({OrderData order, BoardStatus status});

@RoutePage(name: 'ManagerOrderHistoryRoute')
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      // The fold (38c's width) is already a two-plane screen, so it takes
      // the plane layout too; only a one-plane window falls back to 38d.
      child: const AdaptiveShell(
        compact: _buildCompact,
        medium: _buildExpanded,
        expanded: _buildExpanded,
      ),
    );
  }
}

/// 38d — one plane: the list is the whole screen, the tap opens the
/// shipped bottom sheet, and the ONE back affordance is the corner pill.
Widget _buildCompact(BuildContext context) {
  return Scaffold(
    backgroundColor: AppStyle.surfaceDark,
    body: SafeArea(
      child: Stack(
        children: [
          OrderHistoryList(
            compact: true,
            onOpenDetail: (order, status) => _openHistorySheet(context, order),
          ),
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: FloatingBackPill(
              back: FloatingNavBack(
                icon: Remix.arrow_left_wide_fill,
                label: AppHelpers.getTranslation(TrKeys.back),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 38a — planes: the list declares TWO, a tapped order's details push
/// into the LAST plane, and back pops the pane.
Widget _buildExpanded(BuildContext context) {
  return Scaffold(
    backgroundColor: AppStyle.surfaceDark,
    body: SafeArea(
      child: ListDetailFlow<HistoryDetail>(
        backIcon: Remix.arrow_left_wide_fill,
        detailNameOf: (open) => open.order.id ?? '',
        listBuilder: (context, flow) => OrderHistoryList(
          selectedOrderId: flow.open?.order.id,
          onOpenDetail: (order, status) =>
              flow.openDetail((order: order, status: status)),
        ),
        detailBuilder: (context, open, flow) => _OrderHistoryDetailPane(
          order: open.order,
          onClosed: flow.closeDetail,
        ),
      ),
    ),
  );
}

/// The shipped sheet, unchanged — phone behaviour (38d).
void _openHistorySheet(BuildContext context, OrderData order) {
  AppHelpers.showCustomModalBottomSheet(
    paddingTop: MediaQuery.paddingOf(context).top + 60,
    context: context,
    radius: 12,
    modal: OrderDetailsModal(isHistoryOrder: true, order: order),
    isDarkMode: true,
  );
}

/// The ORDER-DETAILS PANE holding the LAST plane (chips 701/702/703): the
/// same [OrderDetailsModal] the phone sheet shows, hosted in a pane-local
/// navigator so any `Navigator.pop` inside it closes the PLANE — never
/// the history route beneath it. A finished order carries no
/// status-change buttons, so the pane is the modal's read-only face plus
/// Ray's 12:23Z amendment, the receipt reprint action.
class _OrderHistoryDetailPane extends StatelessWidget {
  final OrderData order;
  final VoidCallback onClosed;

  const _OrderHistoryDetailPane({required this.order, required this.onClosed});

  static const String _sentinelName = '_history-detail-sentinel';

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
                  child: OrderDetailsModal(isHistoryOrder: true, order: order),
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
    if (previousRoute?.settings.name ==
        _OrderHistoryDetailPane._sentinelName) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onPoppedToSentinel());
    }
  }
}
