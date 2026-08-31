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

// FRAME 49b of design strip section 49 — the push offer, redrawn as a
// DECISION rather than a notification.
//
// WHAT SHIPPED, and what is wrong with it. The incoming-offer sheet is
// the only screen in the driver app a courier reads under time
// pressure, and it was still the white upstream card: `AppStyle.white`
// panel, white avatar wells, a ring in a white collar. Everything the
// rest of the fleet has moved to a dark surface for — the cash sheet
// (45d), the wallet, the keypad — this one screen kept in the old
// dress, and it is the one where glare and haste cost the most.
//
// WHAT 49b CHANGES, and only this:
//
//   * the DARK FLEET DRESS — `cardDark` / `cardDarkAlt` / `strokeDark`,
//     the same tokens `CashCollectionSheet` adopted, so the offer and
//     the money step read as one app;
//   * the COUNTDOWN RING straddling the sheet edge, in a collar that is
//     now part of the sheet rather than a white disc floating over it;
//   * the TWO-LEG STRIP said out loud — the shipped layout already drew
//     shop, then two dots, then customer, and never named either end.
//     PICKUP and DROP-OFF are the two things the driver is deciding
//     about, so they are labelled;
//   * ONE HONEST LINE. The ring looks like a hold. It is not one: it is
//     the offer expiring, and any other driver can take the job while
//     it counts. Nothing in the shipped screen said so.
//
// WHAT 49b DOES NOT CHANGE — the frame is explicit, and so is this
// file. There is no behaviour here at all. The timer maths, the
// `ref.listen`-on-`isTimeOut` pop, `goMarket`, the routing call and
// both buttons stay in the page exactly as they shipped; these widgets
// take already-computed values and draw them. Every value drawn is
// already in the `serialize_deliveryman_order` payload the page holds.

import 'package:base_sdk/src/presentation/components/helper/shimmer.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:remixicon/remixicon.dart';

/// The countdown ring, in the fleet's dark dress.
///
/// Straddling the sheet edge is the PAGE's business (the ring is placed
/// by the page's `Stack`/`Positioned`, unchanged); the collar drawn here
/// is what makes the straddle read — it is the sheet's own surface
/// colour, so the ring sits in a notch cut out of the sheet instead of
/// floating on a white disc.
///
/// [percent] and [label] are computed by the page from the shipped
/// push-order timer. This widget owns no clock.
class PushOfferCountdown extends StatelessWidget {
  const PushOfferCountdown({
    super.key,
    required this.percent,
    required this.label,
  });

  /// 0..1, already clamped by the caller if it needs to be.
  final double percent;

  /// What the ring reads in its centre (the shipped `timerText`).
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pushOfferCountdown'),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        shape: BoxShape.circle,
      ),
      child: CircularPercentIndicator(
        radius: 48.r,
        lineWidth: 12.r,
        percent: percent.clamp(0.0, 1.0),
        center: Text(
          label,
          style: AppStyle.interSemi(size: 18),
        ),
        fillColor: AppStyle.transparent,
        backgroundColor: AppStyle.strokeDark,
        progressColor: AppStyle.primary,
        circularStrokeCap: CircularStrokeCap.round,
      ),
    );
  }
}

/// The one honest line 49b adds.
///
/// The ring reads like a reservation. It is not: it is the OFFER
/// expiring. The job is not held, and another driver accepting it while
/// this sheet is open is an ordinary outcome, not a fault. Saying so is
/// the whole of this widget.
class PushOfferTimerNote extends StatelessWidget {
  const PushOfferTimerNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('pushOfferTimerNote'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Remix.information_line,
          size: 14.r,
          color: AppStyle.textDarkFaint,
        ),
        8.horizontalSpace,
        Expanded(
          child: Text(
            AppHelpers.getTranslation(TrKeys.offerCountdownNotAHold),
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.textDarkFaint,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// One end of the job — the shop it is collected from, or the door it
/// goes to.
class PushOfferLeg {
  const PushOfferLeg({
    required this.title,
    this.subtitle,
    this.trailing,
    this.imageUrl,
  });

  /// Shop name, or the delivery address.
  final String title;

  /// The line under it: the order number and time at the pickup, the
  /// recipient's name at the drop-off.
  final String? subtitle;

  /// An optional third value shown after [subtitle] behind a divider
  /// (the recipient's phone number, on the drop-off leg).
  final String? trailing;

  final String? imageUrl;
}

/// The two-leg strip: PICKUP above, DROP-OFF below, joined by the run
/// of dots the shipped screen already drew between them.
///
/// The legs are plain values, not an `OrderDetailData` — the page maps
/// its model onto them. That keeps the drawn shape readable on its own
/// and testable without a payload.
class PushOfferLegs extends StatelessWidget {
  const PushOfferLegs({
    super.key,
    required this.pickup,
    required this.dropOff,
  });

  final PushOfferLeg pickup;
  final PushOfferLeg dropOff;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pushOfferLegs'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _leg(
          key: const Key('pushOfferLegPickup'),
          label: AppHelpers.getTranslation(TrKeys.pickup),
          leg: pickup,
        ),
        Padding(
          padding: EdgeInsets.only(left: 14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dot(topSpace: 6, bottomSpace: 6),
              _dot(topSpace: 0, bottomSpace: 10),
            ],
          ),
        ),
        _leg(
          key: const Key('pushOfferLegDropOff'),
          label: AppHelpers.getTranslation(TrKeys.dropOff),
          leg: dropOff,
        ),
      ],
    );
  }

  Widget _dot({required double topSpace, required double bottomSpace}) =>
      Container(
        width: 4.r,
        height: 4.r,
        margin: EdgeInsets.only(top: topSpace.h, bottom: bottomSpace.h),
        decoration: BoxDecoration(
          color: AppStyle.strokeDark,
          shape: BoxShape.circle,
        ),
      );

  Widget _leg({
    required Key key,
    required String label,
    required PushOfferLeg leg,
  }) {
    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(leg.imageUrl),
        16.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppStyle.interSemi(
                  size: 10,
                  color: AppStyle.textDarkSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              2.verticalSpace,
              Text(
                leg.title,
                style: AppStyle.interSemi(size: 14, letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (leg.subtitle != null || leg.trailing != null) ...[
                2.verticalSpace,
                _subtitleRow(leg),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _subtitleRow(PushOfferLeg leg) {
    final parts = <String>[
      if (leg.subtitle != null && leg.subtitle!.isNotEmpty) leg.subtitle!,
      if (leg.trailing != null && leg.trailing!.isNotEmpty) leg.trailing!,
    ];
    return Text(
      parts.join('  ·  '),
      style: AppStyle.interNormal(
        size: 13,
        color: AppStyle.textDarkSecondary,
        letterSpacing: -0.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _avatar(String? url) {
    return Container(
      height: 32.r,
      width: 32.r,
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: (url == null || url.isEmpty)
            ? _avatarFallback()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, _, __) =>
                    ImageShimmer(isCircle: true, size: 32.r),
                errorWidget: (context, _, __) => _avatarFallback(),
              ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        height: 32.r,
        width: 32.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppStyle.cardDarkAlt,
        ),
        alignment: Alignment.center,
        child: Icon(
          Remix.image_line,
          size: 16.r,
          color: AppStyle.textDarkFaint,
        ),
      );
}
