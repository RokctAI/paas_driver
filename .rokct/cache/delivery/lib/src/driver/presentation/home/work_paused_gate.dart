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

// CHIPS 990 and 991 of design strip section 49, frame 49m — the order
// gate at the wallet floor.
//
// THE BACKEND HALF IS ALREADY SHIPPED; THIS IS THE MISSING SCREEN.
// `resolve_deliveryman_wallet_allowance` and
// `assert_deliveryman_can_take_work` are live and wired into
// `attach_order_to_me` (zones#77), copying the shop precedent
// `_assert_shop_can_front_credit`. So a driver past his allowance is
// ALREADY refused — he just had no way to find out except by tapping
// Claim and reading an error that, by deliberate design, carries no
// financial detail at all. This card is what he sees instead, and it is
// fed by `get_deliveryman_work_status`, which resolves the SAME
// allowance against the SAME balance so the screen can never disagree
// with the guard.
//
// WHAT THE FRAME IS CAREFUL ABOUT, AND WHY THE WORDING IS THIS WORDING:
// a gate that reads as punishment gets worked around. So the card leads
// with THE WAY OUT rather than the accusation, and states in the same
// breath that jobs already in hand are untouched — which is true, and
// is the guard's own documented behaviour: the check sits at accept,
// the only moment where a refusal costs nobody a delivery already in
// progress. A driver mid-delivery is never interrupted.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// CHIPS 990 + 991 — what replaces the offer queue when the driver is
/// past his allowance.
class WorkPausedGate extends StatelessWidget {
  const WorkPausedGate({
    super.key,
    required this.owing,
    required this.allowance,
    required this.onTopUp,
    required this.onSeeWhatYouOwe,
  });

  /// Unsigned magnitude he is behind — `owing` from
  /// `get_deliveryman_work_status`.
  final num owing;

  /// His resolved allowance — per-driver override, else the tenant
  /// default, else the platform default. Called "your operator" in the
  /// copy because from the driver's side that is who set it.
  final num allowance;

  final VoidCallback onTopUp;
  final VoidCallback onSeeWhatYouOwe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.newJobsArePaused).toUpperCase(),
            style: AppStyle.interSemi(
              size: 11,
              color: AppStyle.primary,
              letterSpacing: 0.8,
            ),
          ),
          8.verticalSpace,
          // The position, as a sentence rather than a signed number —
          // the same decision chip 970 makes and for the same reason.
          Text(
            '${AppHelpers.getTranslation(TrKeys.youOwe)} '
            '${AppHelpers.numberFormat(number: owing)}',
            style: AppStyle.interSemi(size: 20, color: AppStyle.textPrimary),
          ),
          6.verticalSpace,
          Text(
            '${AppHelpers.getTranslation(TrKeys.operatorPausesNewJobsAt)} '
            '${AppHelpers.numberFormat(number: allowance)} '
            '${AppHelpers.getTranslation(TrKeys.owing)}.',
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          2.verticalSpace,
          // The exit, stated before the limit is.
          Text(
            AppHelpers.getTranslation(TrKeys.payInAndWorkStartsAgain),
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
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
                  onPressed: onSeeWhatYouOwe,
                  style: TextButton.styleFrom(
                    backgroundColor: AppStyle.transparent,
                    minimumSize: Size(0, 40.h),
                    side: BorderSide(color: AppStyle.strokeDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.seeWhatYouOwe),
                    style: AppStyle.interSemi(
                      size: 13,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          // CHIP 991 — the limit, stated plainly, and the promise that
          // work in hand is untouched. Both are true of the shipped
          // guard, which reads nothing at the collection path at all.
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppStyle.cardDark,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.yourLimit),
                        style: AppStyle.interNormal(
                          size: 12,
                          color: AppStyle.textDarkSecondary,
                        ),
                      ),
                    ),
                    Text(
                      AppHelpers.numberFormat(number: allowance),
                      style: AppStyle.interSemi(
                        size: 13,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                  ],
                ),
                2.verticalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.setByYourOperator),
                  style: AppStyle.interNormal(
                    size: 11,
                    color: AppStyle.textDarkFaint,
                  ),
                ),
                6.verticalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.jobsInHandStillWork),
                  style: AppStyle.interNormal(
                    size: 11,
                    color: AppStyle.textDarkFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
