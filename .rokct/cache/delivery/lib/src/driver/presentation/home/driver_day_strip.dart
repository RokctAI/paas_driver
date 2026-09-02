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

// CHIP 931 of design strip section 49 — the driver's day strip, and
// CHIP 931 of frame 49e — the same strip re-laid-out at the 360 fold.
//
// WHAT THIS REPLACES. The shipped courier home showed a Balance tile
// reading a cached `LocalStorage.getUser()?.wallet?.price` beside a
// "Juvo benefit" promo tile, and three hard-coded stock photographs.
// None of it was the driver's work. This strip is: what he earned, how
// many he delivered, and what the last one paid.
//
// THE FOLD (frame 49e) IS A RE-LAYOUT, NOT A SCALE-DOWN. At 390 the
// strip is three columns divided by two hairlines. At 360 it becomes a
// headline figure with the two supporting numbers on a second row under
// a full-width rule — deliberately NOT three columns shrunk by
// flutter_screenutil's `.w` until they collide, which is exactly what
// scaling the shipped three-across row would have done. Same three
// values, same card, different composition.
//
// THE WIDGET OWNS NO TRUTH. Every figure is passed in, already resolved
// by the caller from `get_deliveryman_order_report` with today's date on
// both bounds (total_price, total_delivered_count, last_delivered_fee).
// Nothing here fetches, derives or caches.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The width at or below which frame 49e's fold composition is used.
///
/// 390 is the canonical phone the strip was drawn on and 360 is the
/// narrow end of the range drivers actually carry; the branch sits
/// between them so both drawn frames render exactly as drawn.
const double kDriverDayStripFoldWidth = 376;

/// CHIP 931 — earned / delivered / last fee for the day.
class DriverDayStrip extends StatelessWidget {
  const DriverDayStrip({
    super.key,
    required this.earned,
    required this.delivered,
    required this.lastFee,
    this.heading,
  });

  /// `total_price` for today — delivery fees of Delivered orders and
  /// parcels, summed by the server.
  final num earned;

  /// `total_delivered_count` for today.
  final int delivered;

  /// `last_delivered_fee` — what the most recent delivery paid.
  final num lastFee;

  /// The strip's own label. Defaults to TODAY.
  ///
  /// FLAG, STAMPED ON FRAME 49d AND HONOURED HERE: the frame drew this
  /// reading "TODAY · SHIFT ENDED 17:04" when the driver goes off duty,
  /// and flagged the time as NOT SOURCED — `setOnline` flips a boolean
  /// on the server and in CourierStorage and stores no timestamp
  /// anywhere (home_notifier.dart). Rather than invent one, the off-duty
  /// caller passes no heading and the strip says TODAY. The money and
  /// the count beside it are real. Wire a real shift-start timestamp and
  /// this parameter is where it lands.
  final String? heading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading ?? AppHelpers.getTranslation(TrKeys.today).toUpperCase(),
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.textDarkFaint,
              letterSpacing: 0.8,
            ),
          ),
          10.verticalSpace,
          // The fold is a property of THE PHONE, not of this card's
          // inner box — frame 49e is "49a at 360 logical wide" — so the
          // branch reads the window rather than the local constraint,
          // which would otherwise fold a 390 phone the moment the card
          // gained padding.
          MediaQuery.sizeOf(context).width <= kDriverDayStripFoldWidth
              ? _folded()
              : _threeUp(),
        ],
      ),
    );
  }

  /// 390 — three columns divided by two hairlines.
  Widget _threeUp() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _cell(_money(earned), TrKeys.earned)),
        _hairline(),
        Expanded(child: _cell('$delivered', TrKeys.delivered)),
        _hairline(),
        Expanded(child: _cell(_money(lastFee), TrKeys.lastFee)),
      ],
    );
  }

  /// 360 — a headline figure, then the two supporting numbers inline
  /// under a full-width rule. Not the three-up row shrunk.
  Widget _folded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _money(earned),
          style: AppStyle.interSemi(size: 26, color: AppStyle.textPrimary),
        ),
        Text(
          AppHelpers.getTranslation(TrKeys.earned),
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.textDarkSecondary,
          ),
        ),
        10.verticalSpace,
        Container(
          height: 1,
          width: double.infinity,
          color: AppStyle.strokeDarkSubtle,
        ),
        10.verticalSpace,
        Row(
          children: [
            Expanded(
              child: Text(
                '$delivered ${AppHelpers.getTranslation(TrKeys.delivered)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interNormal(
                  size: 13,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
            Flexible(
              child: Text(
                '${AppHelpers.getTranslation(TrKeys.lastFee)} ${_money(lastFee)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppStyle.interNormal(
                  size: 13,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hairline() => Container(
    width: 1,
    height: 34.h,
    margin: EdgeInsets.symmetric(horizontal: 8.w),
    color: AppStyle.strokeDarkSubtle,
  );

  Widget _cell(String value, String labelKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppStyle.interSemi(size: 18, color: AppStyle.textPrimary),
          ),
        ),
        2.verticalSpace,
        Text(
          AppHelpers.getTranslation(labelKey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.textDarkSecondary,
          ),
        ),
      ],
    );
  }

  String _money(num value) => AppHelpers.numberFormat(number: value);
}
