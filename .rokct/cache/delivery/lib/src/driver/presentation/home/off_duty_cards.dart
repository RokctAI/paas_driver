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

// CHIPS 945 and 970 of design strip section 49, frame 49d — off duty,
// drawn as a state.
//
// OFF DUTY IS REAL, PERSISTED AND CONSEQUENTIAL, AND THE SHIPPED SCREEN
// NEVER ACKNOWLEDGED IT. `CourierStorage.getOnline()` gates whether the
// 10-minute `fetchBackground` location task is registered at all, and
// whether the 10-second routing poll runs. Today the screen looks
// IDENTICAL either way — same map, same balance tile, same three stock
// photographs, with nothing but a switch position distinguishing a
// driver who is working from one who is not. These two cards, plus the
// map veil in the host page, close that gap.
//
// THE FRAME WAS REJECTED ONCE, AND THIS FILE IS THE REDRAW. The first
// version told the driver he "still owes a deposit" at the end of a
// shift. That obligation DOES NOT EXIST — no deposit doctype, no due
// date, no banking step, nothing that reads one — and Ray rejected the
// frame for it. What replaces the invention is the genuinely useful
// content: his wallet position, and the way out.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// CHIP 945 — the off-duty rest state: what replaces the stock-photo
/// carousel when the driver is not working.
///
/// The line about location sharing is a GENUINE PRIVACY STATEMENT backed
/// by the code above, not reassurance copy: with `getOnline()` false the
/// periodic background task is cancelled and the routing poll never
/// starts, so his position really has stopped being shared.
class OffDutyRestCard extends StatelessWidget {
  const OffDutyRestCard({
    super.key,
    required this.openJobsInZone,
    required this.onGoOnDuty,
  });

  /// The one hook back to work, and it is honest: `get_available_orders`
  /// returns a `meta.total` from a real `frappe.db.count`, so the number
  /// can be shown WITHOUT accepting anything.
  final int openJobsInZone;

  final VoidCallback onGoOnDuty;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.youAreOffDuty),
                  style: AppStyle.interSemi(
                    size: 15,
                    color: AppStyle.textPrimary,
                  ),
                ),
                4.verticalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.noJobsOfferedLocationOff),
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
                if (openJobsInZone > 0) ...[
                  8.verticalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppStyle.strokeDark),
                    ),
                    child: Text(
                      '$openJobsInZone '
                      '${AppHelpers.getTranslation(TrKeys.jobsOpenInYourZone)}',
                      style: AppStyle.interNormal(
                        size: 11,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          10.horizontalSpace,
          TextButton(
            onPressed: onGoOnDuty,
            style: TextButton.styleFrom(
              backgroundColor: AppStyle.primary,
              foregroundColor: AppStyle.blackColor,
              minimumSize: Size(96.w, 38.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              AppHelpers.getTranslation(TrKeys.goOnDuty),
              style: AppStyle.interSemi(size: 13, color: AppStyle.blackColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// CHIP 970 — the wallet position, and the reason frame 49d was redrawn.
///
/// The balance is the Wallet doctype's, and it is negative BY DESIGN,
/// documented in the code three separate times (settlement.py,
/// driver_parcel.py, driver_order.py), all saying the same thing: he
/// holds the physical cash, so his ledger may go negative.
///
/// THREE DELIBERATE DECISIONS IN ONE SMALL CARD, all three load-bearing:
///
///   1. It is A SENTENCE, NOT A SIGNED NUMBER — "You owe R 1,240.00"
///      rather than "−1,240" — because a signed number is something a
///      tired man argues with and a sentence is something he acts on.
///      That is why [owing] is an unsigned magnitude and the server
///      hands it over that way.
///   2. It NAMES THE CAUSE IN THE DRIVER'S OWN TERMS — cash he
///      collected, docked at Delivered — rather than leaving him to
///      infer why a day of earning left him further behind.
///   3. It CARRIES THE EXIT: Top up.
///
/// WHAT IT DELIBERATELY DOES NOT SAY: that anything is owed by a
/// deadline, that a deposit is due, or that a shift cannot end until it
/// is settled. None of those exist. Do not add them here.
class WalletPositionCard extends StatelessWidget {
  const WalletPositionCard({
    super.key,
    required this.owing,
    required this.onTopUp,
    required this.onOpenWallet,
  });

  /// UNSIGNED magnitude the driver is behind. Zero or less means he is
  /// in credit and the card states that instead.
  final num owing;

  final VoidCallback onTopUp;
  final VoidCallback onOpenWallet;

  bool get _behind => owing > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.yourWallet).toUpperCase(),
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.textDarkFaint,
              letterSpacing: 0.8,
            ),
          ),
          8.verticalSpace,
          Text(
            _behind
                ? '${AppHelpers.getTranslation(TrKeys.youOwe)} '
                      '${AppHelpers.numberFormat(number: owing)}'
                : AppHelpers.getTranslation(TrKeys.yourWalletIsClear),
            style: AppStyle.interSemi(size: 20, color: AppStyle.textPrimary),
          ),
          if (_behind) ...[
            6.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.cashIsDockedAtDelivered),
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onTopUp,
                  style: TextButton.styleFrom(
                    backgroundColor: AppStyle.primary,
                    foregroundColor: AppStyle.blackColor,
                    minimumSize: Size(0, 40.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.topUp),
                    style: AppStyle.interSemi(
                      size: 13,
                      color: AppStyle.blackColor,
                    ),
                  ),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: TextButton(
                  onPressed: onOpenWallet,
                  style: TextButton.styleFrom(
                    backgroundColor: AppStyle.transparent,
                    minimumSize: Size(0, 40.h),
                    side: BorderSide(color: AppStyle.strokeDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.openWallet),
                    style: AppStyle.interSemi(
                      size: 13,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
