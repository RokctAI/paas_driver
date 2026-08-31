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

// FRAME 49c of design strip section 49 — the job rail.
//
// WHAT THE FRAME ASKS FOR. The in-progress delivery sheet used to tell
// the driver where he was in the job by exactly one thing: the caption
// on the primary button. "Complete checkout" meant he was still at the
// shop; "I delivered the order" meant he was not. The arc of the job —
// accepted, at the shop, on the way, delivered — had to be inferred
// from a verb. 49c gives it four nodes and draws it.
//
// THE HONEST PART, and the frame states it on its face: the SECOND
// node is NOT a persisted status. The Order doctype carries `new`,
// `accepted`, `ready`, `on_a_way`, `delivered` and `canceled` and
// nothing between `accepted` and `on_a_way` — there is no "at shop"
// value anywhere on the wire, and this widget does not invent one. The
// node is drawn from the `completeCheckout` confirmation the driver
// makes at the shop counter, which is the same local transition that
// already flips the sheet's own button caption (`isGoRestaurant` ->
// `isGoUser` in `HomeState`). So the rail says exactly what the app
// already knows and not one step more.
//
// NO NEW STATE AND NO NEW CALL. Everything the rail reads is already
// on the sheet: the order's server `status` and the two live flags the
// notifier keeps. [DeliveryStatusRail.stageFor] is the whole derivation
// and it is pure, so the reading is testable without a notifier.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The four nodes of a delivery, in order.
///
/// [atShop] is the one with no server status behind it — see the file
/// comment. The others map to real `Order.status` values (`accepted` /
/// `ready`, `on_a_way`, `delivered`).
enum DeliveryStage { accepted, atShop, onTheWay, delivered }

/// FRAME 49c — the four-node rail above the in-progress delivery sheet.
///
/// Nodes before [current] read as done (filled, ticked); [current] reads
/// as in progress (ringed); nodes after it are pending. The rail is a
/// read-out and nothing else: it has no tap targets, because every one
/// of these transitions is made by an action elsewhere on the sheet.
class DeliveryStatusRail extends StatelessWidget {
  const DeliveryStatusRail({super.key, required this.current});

  /// The stage the job is in now. Use [stageFor] to derive it.
  final DeliveryStage current;

  /// The whole derivation, kept pure so it can be read and tested
  /// without a notifier.
  ///
  /// The server `status` is authoritative wherever it has an opinion.
  /// `isGoUser` advances the rail to [DeliveryStage.onTheWay] the moment
  /// the driver confirms the checkout at the counter — before the
  /// `on_a_way` write has come back — which is exactly the moment the
  /// frame says the second node is earned.
  static DeliveryStage stageFor({
    String? status,
    required bool isGoRestaurant,
    required bool isGoUser,
  }) {
    if (status == 'delivered') return DeliveryStage.delivered;
    if (isGoUser || status == 'on_a_way') return DeliveryStage.onTheWay;
    if (isGoRestaurant) return DeliveryStage.atShop;
    return DeliveryStage.accepted;
  }

  static String _labelKey(DeliveryStage stage) {
    switch (stage) {
      case DeliveryStage.accepted:
        return TrKeys.accepted;
      case DeliveryStage.atShop:
        return TrKeys.atShop;
      case DeliveryStage.onTheWay:
        return TrKeys.onAWay;
      case DeliveryStage.delivered:
        return TrKeys.delivered;
    }
  }

  @override
  Widget build(BuildContext context) {
    const stages = DeliveryStage.values;
    return Padding(
      key: const Key('deliveryStatusRail'),
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 9.r),
                  child: Container(
                    height: 2.h,
                    color: i <= current.index
                        ? AppStyle.primary
                        : AppStyle.strokeDark,
                  ),
                ),
              ),
            _node(stages[i]),
          ],
        ],
      ),
    );
  }

  Widget _node(DeliveryStage stage) {
    final done = stage.index < current.index;
    final isCurrent = stage == current;
    final reached = done || isCurrent;
    return SizedBox(
      width: 72.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: Key('deliveryStatusNode_${stage.name}'),
            height: 20.r,
            width: 20.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppStyle.primary : AppStyle.transparent,
              border: Border.all(
                color: reached ? AppStyle.primary : AppStyle.strokeDark,
                width: isCurrent ? 3.r : 2.r,
              ),
            ),
            child: done
                ? Icon(Icons.check, size: 12.r, color: AppStyle.white)
                : null,
          ),
          6.verticalSpace,
          Text(
            AppHelpers.getTranslation(_labelKey(stage)),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: reached
                ? AppStyle.interSemi(size: 11, letterSpacing: -0.2)
                : AppStyle.interNormal(
                    size: 11,
                    color: AppStyle.textDarkFaint,
                    letterSpacing: -0.2,
                  ),
          ),
        ],
      ),
    );
  }
}
