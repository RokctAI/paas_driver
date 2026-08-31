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
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_nav_mode.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// The approved catalog plane behaviour (frame 35a, Ray 2026-08-29 15:41Z):
/// **THE CATALOG DECLARES ALL** — the same call the kitchen made (13:06Z
/// "shouldnt it take all until another come?"): products are stuff you need
/// to see, so the flow's root claims [PlaneSpan.all]; the selected product's
/// READ-ONLY detail is pushed with the DEFAULT one-plane claim into the LAST
/// plane, so
///
///  * at three planes the grid spreads over planes 1–2 with the detail on
///    plane 3 — approved 35a, no bare stage (auto-select keeps it filled);
///  * at two planes it is catalog | detail;
///  * on a phone the flow hosts the catalog alone — approved 35c keeps the
///    shipped tap-straight-to-edit (a REAL pushed route, 35d), the
///    deliberate approved asymmetry against the tablet's read stop.
///
/// The quick-adjust surface (approved 35e) can take the detail's place as a
/// pushed plane pane on wide widths — a pushed page holding a plane, so the
/// corner back pill appears (the 12:36Z fold; on phones the same surface is
/// a bottom sheet per the 12:02Z sheet fork and this flow never sees it).
///
/// Identical machinery to kitchen_sdk's KitchenPlaneFlow (34a) with the one
/// extra step.
class CatalogPlaneFlow extends StatelessWidget {
  /// The selected product, if any — resolved by id from the live list, so
  /// refreshes keep an open detail current.
  final SellerProductData? selectedProduct;

  /// The 35e counts-only surface open as a plane pane (wide only).
  final bool quickAdjustOpen;

  /// Builds the catalog workspace (the flow's root, claiming ALL planes).
  final WidgetBuilder catalogBuilder;

  /// Builds the pushed read-only detail (default claim: one plane).
  final Widget Function(BuildContext context, SellerProductData product)
      detailBuilder;

  /// Builds the pushed quick-adjust pane (default claim: one plane).
  final WidgetBuilder quickAdjustBuilder;

  /// Pops the newest step (the corner back pill / phone back).
  final VoidCallback onPop;

  const CatalogPlaneFlow({
    super.key,
    required this.selectedProduct,
    required this.quickAdjustOpen,
    required this.catalogBuilder,
    required this.detailBuilder,
    required this.quickAdjustBuilder,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final product = selectedProduct;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The read detail is a PERMANENT pane of the spread — approved 35a
        // shows the full centered nav with the detail open, no fold. Only
        // the pushed quick-adjust pane folds the nav to the corner pill
        // (12:36Z: a pushed page holds a plane).
        return PlaneHost(
          back: quickAdjustOpen
              ? FloatingNavBack(
                  icon: Remix.arrow_left_s_line,
                  label: AppHelpers.getTranslation(TrKeys.back),
                  onTap: onPop,
                )
              : null,
          stack: [
            PlanePage(
              name: 'product-catalog',
              span: PlaneSpan.all,
              builder: catalogBuilder,
            ),
            if (quickAdjustOpen)
              PlanePage(
                name: 'stock-quick-adjust',
                builder: quickAdjustBuilder,
              )
            else if (product != null)
              PlanePage(
                name: 'product-read-detail',
                // Default claim — exactly one plane (the 33d/34a ruling).
                builder: (context) => KeyedSubtree(
                  key: ValueKey('product-detail-${product.id}'),
                  child: detailBuilder(context, product),
                ),
              ),
          ],
        );
      },
    );
  }
}
