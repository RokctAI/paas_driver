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

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_nav_mode.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';

/// The approved kitchen plane behaviour (Ray 13:06Z: "34a is not special?
/// shouldnt it take all until another come? stuff need to see, order goes
/// wrong here" — the kitchen declares ALL): the queue is the flow's root
/// claiming [PlaneSpan.all]; the selected order's detail is PUSHED with
/// the DEFAULT one-plane claim into the LAST plane, so
///
///  * at three planes the queue compresses onto planes 1–2 (four cards a
///    row, dish preview per card — "more space means more details not
///    zoom") with the detail on plane 3 — approved 34a, no bare stage;
///  * at two planes it is queue | detail;
///  * on a phone the plane model collapses to queue → pushed detail with
///    the corner back pill by construction — approved 34b/34c and the
///    12:36Z nav fold.
///
/// Identical machinery to orders_sdk's OrdersBoardPlaneFlow (33d), minus
/// the board's modal degradation: the kitchen phone detail is a REAL
/// pushed plane page (34c shows the corner fold, not a sheet).
class KitchenPlaneFlow extends StatelessWidget {
  /// The selected order, if any — plane pushes are driven by selection
  /// state (the notifier), not local widget state, so polling refreshes
  /// keep the open detail current.
  final KitchenOrderData? selectedOrder;

  /// Builds the queue workspace (the flow's root, claiming ALL planes).
  final WidgetBuilder queueBuilder;

  /// Builds the pushed order detail (default claim: one plane).
  final Widget Function(BuildContext context, KitchenOrderData order)
  detailBuilder;

  /// Pops the detail (the corner back pill).
  final VoidCallback onCloseDetail;

  const KitchenPlaneFlow({
    super.key,
    required this.selectedOrder,
    required this.queueBuilder,
    required this.detailBuilder,
    required this.onCloseDetail,
  });

  @override
  Widget build(BuildContext context) {
    final order = selectedOrder;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The corner back pill belongs to the PHONE's nav-fold moment
        // only (34c / the 12:36Z rule): on multi-plane widths the detail
        // is a permanent pane of the spread — approved 34a shows the full
        // centered nav with the detail open, no fold — and the queue's
        // auto-select keeps that pane filled anyway.
        final bool onePlane =
            PlaneHost.planeCountFor(constraints.maxWidth) == 1;
        return PlaneHost(
          back: onePlane
              ? FloatingNavBack(
                  icon: FlutterRemix.arrow_left_s_line,
                  label: AppHelpers.getTranslation(TrKeys.back),
                  onTap: onCloseDetail,
                )
              : null,
          stack: [
            PlanePage(
              name: 'kitchen-queue',
              span: PlaneSpan.all,
              builder: queueBuilder,
            ),
            if (order != null)
              PlanePage(
                name: 'kitchen-order-detail',
                // Default claim — exactly one plane (the 33d/34a ruling).
                builder: (context) => KeyedSubtree(
                  key: ValueKey('kitchen-detail-${order.id}'),
                  child: detailBuilder(context, order),
                ),
              ),
          ],
        );
      },
    );
  }
}
