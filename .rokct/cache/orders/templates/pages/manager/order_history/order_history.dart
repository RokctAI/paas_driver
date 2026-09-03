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
// The list body and the plane flow live in the SDK
// (`orders_sdk/src/manager/presentation/history/order_history_list.dart`,
// `.../order_history_plane_flow.dart`) so both are widget-tested at 393 /
// 800 / 1280 logical; this installed file is the host shell, supplying the
// shipped OrderDetailsModal to the pane and the bottom sheet to the phone.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/adaptive/adaptive_shell.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:${package}/presentation/pages/orders/details/order_details_modal.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/history/order_history_list.dart';
import 'package:orders_sdk/src/manager/presentation/history/order_history_plane_flow.dart';

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
/// into the LAST plane (the bare third plane trailing at tablet width),
/// and back pops the pane. The flow itself is `OrderHistoryPlaneFlow`.
Widget _buildExpanded(BuildContext context) {
  return Scaffold(
    backgroundColor: AppStyle.surfaceDark,
    body: SafeArea(
      child: OrderHistoryPlaneFlow(
        backIcon: Remix.arrow_left_wide_fill,
        detailBuilder: (context, order) =>
            OrderDetailsModal(isHistoryOrder: true, order: order),
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
