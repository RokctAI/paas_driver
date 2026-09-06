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

// THE WALK-IN ORDER FLOW ON PLANES — approved design strip section 37
// (frames 37a–37e, Ray 2026-08-30 12:23Z "build authorized"): the shipped
// create-order chain (commerce#79) re-laid in the plane language, lifted
// out of the installed `create_order_page.dart` so the plane behaviour is
// package code with a widget test at every width, the installed page
// being the host shell that supplies the `${package}` step widgets.
//
// The cascade, as the frames draw it:
//
//   * the ORDERS BOARD is the origin — it declares ALL and yields: on 37a
//     it compresses onto plane 1 as a one-plane rail of mini cards (675);
//     on 37b it pops off stage entirely — strict newest-wins;
//   * the WALK-IN page claims TWO while active (products | cart — the
//     settled Add-Items precedent, "adding items would be important at
//     that moment") and keeps spreading over two when yielded; granted a
//     single plane while yielded (the two-plane fold with shipping on
//     stage) it compresses to its products column — the cart is one Back
//     away, exactly as the till yields to its scan plane on 11n;
//   * tapping a product row takes the SHEET FORK (12:02Z): the shipped
//     FoodDetailsModal is a sheet on the phone and a PANE at plane widths
//     — pushed with the default one-plane claim into the LAST plane;
//   * /shipping-address (37b) and /delivery-time (37e) declare the DEFAULT
//     one plane and take the LAST plane — the cascade; the phone-only
//     /order push DISSOLVES at plane widths (decision (a), locked): the
//     cart pane is already on stage, so Next goes products | cart →
//     shipping directly;
//   * /select-address (37c) declares ALL and REFUSES neighbours — the map
//     full-bleed across the whole stage, no seams (the settled 19b/20b
//     ruling); Confirm writes the pick back and pops it;
//   * sheets (SelectDateModal) overlay, never take planes;
//   * every state here is a pushed page, so the nav is the corner Back
//     pill (347) throughout — PlaneHost's own, bottom-END, popping the
//     NEWEST step; at the root it pops the whole walk-in route and the
//     board re-expands.
//
// On a one-plane (phone) screen the host never builds this flow — the
// cascade becomes the shipped push chain (37d/37e), route by route.

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_nav_mode.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

/// The linear steps of the cascade, root first. The map (37c) and the
/// product-details pane are overlays on a step, not steps of their own.
enum WalkInStep { products, shipping, deliveryTime }

/// A step widget builder that gets the flow, so the step can advance it.
typedef WalkInStepBuilder =
    Widget Function(BuildContext context, WalkInPlaneFlowState flow);

/// Section 37 on planes: the board rail as the yielded origin, the walk-in
/// page claiming two, and the shipping / map / delivery-time steps pushed
/// into the planes instead of onto the route stack.
class WalkInPlaneFlow extends StatefulWidget {
  /// 675 — the yielded orders board, compressed to a one-plane rail.
  final WidgetBuilder boardRailBuilder;

  /// The products column (318 search, 349 chips, 678/679/680 rows).
  final WalkInStepBuilder productsBuilder;

  /// 681 — the cart pane (the shipped OrderPane, embedded live).
  final WalkInStepBuilder cartBuilder;

  /// The sheet fork: the shipped FoodDetailsModal as a pane.
  final Widget Function(
    BuildContext context,
    ProductData product,
    WalkInPlaneFlowState flow,
  )
  foodDetailsBuilder;

  /// 686 — /shipping-address as a one-plane step.
  final WalkInStepBuilder shippingBuilder;

  /// 691 — /select-address, the map's ALL claim.
  final WalkInStepBuilder addressBuilder;

  /// 696–699 — /delivery-time, the finish step.
  final WalkInStepBuilder deliveryTimeBuilder;

  /// Back at the flow's root: pops the whole walk-in route so the board
  /// re-expands (37a's 347).
  final VoidCallback onExit;

  /// Back-pill glyph; the host passes its icon pack's arrow.
  final IconData backIcon;

  const WalkInPlaneFlow({
    super.key,
    required this.boardRailBuilder,
    required this.productsBuilder,
    required this.cartBuilder,
    required this.foodDetailsBuilder,
    required this.shippingBuilder,
    required this.addressBuilder,
    required this.deliveryTimeBuilder,
    required this.onExit,
    required this.backIcon,
  });

  @override
  State<WalkInPlaneFlow> createState() => WalkInPlaneFlowState();
}

class WalkInPlaneFlowState extends State<WalkInPlaneFlow> {
  WalkInStep _step = WalkInStep.products;
  bool _addressOpen = false;
  ProductData? _detailProduct;

  /// The active linear step.
  WalkInStep get step => _step;

  /// True while the map (37c) holds the whole stage.
  bool get addressOpen => _addressOpen;

  /// The product whose details pane holds the last plane, if any.
  ProductData? get detailProduct => _detailProduct;

  /// A product row was tapped at plane widths: the sheet fork — its
  /// details take the LAST plane with the default claim.
  void openFoodDetails(ProductData product) {
    if (_step != WalkInStep.products) return;
    setState(() => _detailProduct = product);
  }

  void closeFoodDetails() {
    if (_detailProduct == null) return;
    setState(() => _detailProduct = null);
  }

  /// 685 — Next on the cart pane: /shipping-address takes the last plane.
  void openShipping() {
    setState(() {
      _detailProduct = null;
      _addressOpen = false;
      _step = WalkInStep.shipping;
    });
  }

  /// 689's map-pin button: the map claims ALL (37c).
  void openAddress() {
    if (_step != WalkInStep.shipping) return;
    setState(() => _addressOpen = true);
  }

  /// 694 Confirm location (after the pick is written back) or Back.
  void closeAddress() {
    if (!_addressOpen) return;
    setState(() => _addressOpen = false);
  }

  /// Next on the shipping pane: /delivery-time takes the last plane.
  void openDeliveryTime() {
    if (_step != WalkInStep.shipping) return;
    setState(() {
      _addressOpen = false;
      _step = WalkInStep.deliveryTime;
    });
  }

  /// 347 — the corner Back pill pops the NEWEST step only.
  void back() {
    if (_addressOpen) {
      closeAddress();
      return;
    }
    switch (_step) {
      case WalkInStep.deliveryTime:
        setState(() => _step = WalkInStep.shipping);
      case WalkInStep.shipping:
        setState(() => _step = WalkInStep.products);
      case WalkInStep.products:
        if (_detailProduct != null) {
          closeFoodDetails();
        } else {
          widget.onExit();
        }
    }
  }

  /// The walk-in page spread by the span the host granted it: two planes
  /// → products | cart (37a/37b); one plane (yielded at the fold) → the
  /// products column alone, the cart one Back away. The products subtree
  /// keeps its slot in the row either way, so its state (search text,
  /// scroll) survives the re-flow.
  Widget _walkIn(BuildContext context) {
    final planes = Planes.of(context);
    final bool spread = planes.span >= 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: widget.productsBuilder(context, this)),
        if (spread) ...[
          SizedBox(width: planes.gap),
          Expanded(child: widget.cartBuilder(context, this)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProductData? detail = _detailProduct;
    return PlaneHost(
      back: FloatingNavBack(
        icon: widget.backIcon,
        label: AppHelpers.getTranslation(TrKeys.back),
        onTap: back,
      ),
      stack: [
        // 675: the origin — the ALL-declaring board, yielded.
        PlanePage(
          name: 'orders-board',
          span: PlaneSpan.all,
          builder: widget.boardRailBuilder,
        ),
        // 37a: the walk-in page claims TWO — products | cart.
        PlanePage(name: 'walk-in', span: PlaneSpan.two, builder: _walkIn),
        // The sheet fork: product details as a pane (default claim).
        if (detail != null && _step == WalkInStep.products)
          PlanePage(
            name: 'food-details',
            builder: (context) => KeyedSubtree(
              key: ValueKey('food-details-${detail.id}'),
              child: widget.foodDetailsBuilder(context, detail, this),
            ),
          ),
        // 37b: /shipping-address — the DEFAULT one plane, the LAST one.
        if (_step != WalkInStep.products)
          PlanePage(
            name: 'shipping-address',
            builder: (context) => widget.shippingBuilder(context, this),
          ),
        // 37c: /select-address — ALL planes, no neighbours, no seams.
        if (_step == WalkInStep.shipping && _addressOpen)
          PlanePage(
            name: 'select-address',
            span: PlaneSpan.all,
            allowNeighbors: false,
            builder: (context) => widget.addressBuilder(context, this),
          ),
        // 37e: /delivery-time — the finish step, default claim, last plane.
        if (_step == WalkInStep.deliveryTime)
          PlanePage(
            name: 'delivery-time',
            builder: (context) => widget.deliveryTimeBuilder(context, this),
          ),
      ],
    );
  }
}
