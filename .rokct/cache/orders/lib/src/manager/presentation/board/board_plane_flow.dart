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
import 'package:flutter_remix/flutter_remix.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_nav_mode.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'board_status.dart';

/// The approved click behaviour (frame 33d, Ray 13:53Z): tapping an order
/// card pushes its DETAIL as a page with the DEFAULT plane claim — ONE
/// plane. The detail takes the LAST plane; the board — a full workspace
/// declaring [PlaneSpan.all] — yields and compresses onto the remaining
/// planes; the nav folds to the back-only corner pill ([PlaneHost.back]
/// renders base_sdk's FloatingBackPill at the bottom-end corner while the
/// flow is deeper than its root). NOT a full-page navigation — except on a
/// one-plane (phone) screen, where the plane model collapses to exactly
/// that by construction.
class OrdersBoardPlaneFlow extends StatefulWidget {
  /// Builds the board workspace (the flow's root, claiming ALL planes).
  final Widget Function(BuildContext context, OrdersBoardPlaneFlowState flow)
  boardBuilder;

  /// Builds the pushed order detail (default claim: one plane).
  final Widget Function(
    BuildContext context,
    OrderData order,
    BoardStatus status,
    OrdersBoardPlaneFlowState flow,
  )
  detailBuilder;

  const OrdersBoardPlaneFlow({
    super.key,
    required this.boardBuilder,
    required this.detailBuilder,
  });

  @override
  State<OrdersBoardPlaneFlow> createState() => OrdersBoardPlaneFlowState();
}

class OrdersBoardPlaneFlowState extends State<OrdersBoardPlaneFlow> {
  OrderData? _detailOrder;
  BoardStatus? _detailStatus;

  /// The order whose detail holds the last plane, if any (its board card
  /// keeps the brand border).
  String? get openOrderId => _detailOrder?.id;

  void openDetail(OrderData order, BoardStatus status) {
    setState(() {
      _detailOrder = order;
      _detailStatus = status;
    });
  }

  void closeDetail() {
    if (_detailOrder == null) return;
    setState(() {
      _detailOrder = null;
      _detailStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlaneHost(
      back: FloatingNavBack(
        icon: FlutterRemix.arrow_left_s_line,
        label: AppHelpers.getTranslation(TrKeys.back),
        onTap: closeDetail,
      ),
      stack: [
        PlanePage(
          name: 'orders-board',
          span: PlaneSpan.all,
          builder: (context) => widget.boardBuilder(context, this),
        ),
        if (_detailOrder != null && _detailStatus != null)
          PlanePage(
            name: 'order-detail',
            // Default claim — exactly one plane (the 33d ruling).
            builder: (context) => widget.detailBuilder(
              context,
              _detailOrder!,
              _detailStatus!,
              this,
            ),
          ),
      ],
    );
  }
}
