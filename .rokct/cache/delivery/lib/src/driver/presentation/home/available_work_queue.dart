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

// CHIPS 933 and 934 of design strip section 49 — the available-order
// queue that replaces the three hard-coded stock photographs.
//
// THE DATA WAS ALREADY ON THE WIRE. `getAvailableOrders` is implemented
// in CourierOrdersRepository and was simply not consumed by the home
// screen. Nothing new is fetched to draw this.
//
// CHIP 933'S HEADER IS NOT DECORATION. "first to claim" is a statement
// about the mechanism: `attach_order_to_me` succeeds only while the
// order's `deliveryman` is still empty, so two drivers tapping Claim is
// a race one of them loses. The header says so BEFORE the tap rather
// than surfacing it as an error afterwards.
//
// TWO FIELDS ON CHIP 934 ARE FLAGGED ON THE FRAME AND HONOURED HERE:
//   * distance is CLIENT-DERIVED from the row's location against the
//     driver's own position. The caller does that derivation and passes
//     the result; there is no distance endpoint and this widget invents
//     none. Passing null simply omits the line.
//   * the customer's NAME IS NOT IN THE PAYLOAD AT ALL —
//     `serialize_deliveryman_order` emits shop, totals, location and
//     address but no user block. Which is exactly why this card names a
//     SUBURB and never a person. Do not add a name field here without
//     the serializer growing one first.
//
// The cash tag IS real: `_order_payment_tag` resolves the transaction's
// gateway controller to "cash".

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One row of the queue, already flattened by the caller out of
/// `OrderDetailData` so this widget stays free of the SDK's models and
/// testable on plain values.
class AvailableJob {
  const AvailableJob({
    required this.id,
    required this.shopName,
    this.pickupSuburb,
    this.dropOffSuburb,
    this.fee,
    this.distanceKm,
    this.isCash = false,
    this.cashAmount,
  });

  final String id;
  final String shopName;

  /// Suburbs, never a person — see the file header.
  final String? pickupSuburb;
  final String? dropOffSuburb;

  final num? fee;

  /// Client-derived. Null when the driver's position is unknown.
  final double? distanceKm;

  /// From `transaction.payment_system.tag == "cash"`.
  final bool isCash;

  /// The gross the driver will be carrying if he takes this one.
  final num? cashAmount;

  /// The two-letter mark drawn on the frame, from the shop's own name.
  String get initials {
    final parts = shopName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final word = parts.first;
      return (word.length == 1 ? word : word.substring(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }
}

/// CHIPS 933 + 934 — the queue header and its offer cards.
class AvailableWorkQueue extends StatelessWidget {
  const AvailableWorkQueue({
    super.key,
    required this.jobs,
    required this.onClaim,
    this.compact = false,
  });

  final List<AvailableJob> jobs;
  final void Function(AvailableJob job) onClaim;

  /// Frame 49e's fold: the distance drops the word "away".
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        10.verticalSpace,
        for (final job in jobs) ...[
          _AvailableJobCard(
            job: job,
            compact: compact,
            onClaim: () => onClaim(job),
          ),
          8.verticalSpace,
        ],
      ],
    );
  }

  /// CHIP 933 — count pill plus "first to claim".
  Widget _header() {
    return Row(
      children: [
        // Flexible, not fixed: "Available now" is a translated string and
        // some locales are considerably longer than the English it was
        // drawn in. The count pill beside it must never be what gets
        // pushed off the edge.
        Flexible(
          child: Text(
            AppHelpers.getTranslation(TrKeys.availableNow),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interSemi(size: 15, color: AppStyle.textPrimary),
          ),
        ),
        8.horizontalSpace,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppStyle.primary,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '${jobs.length}',
            style: AppStyle.interSemi(size: 12, color: AppStyle.blackColor),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            AppHelpers.getTranslation(TrKeys.firstToClaim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkFaint,
            ),
          ),
        ),
      ],
    );
  }
}

/// CHIP 934 — one offer.
class _AvailableJobCard extends StatelessWidget {
  const _AvailableJobCard({
    required this.job,
    required this.onClaim,
    required this.compact,
  });

  final AvailableJob job;
  final VoidCallback onClaim;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppStyle.cardDarkAlt,
              border: Border.all(color: AppStyle.strokeDarkSubtle),
            ),
            child: Text(
              job.initials,
              style: AppStyle.interSemi(size: 12, color: AppStyle.textPrimary),
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  job.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.textPrimary,
                  ),
                ),
                if (_leg != null) ...[
                  2.verticalSpace,
                  Text(
                    _leg!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ],
                6.verticalSpace,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (job.fee != null)
                      Text(
                        AppHelpers.numberFormat(number: job.fee),
                        style: AppStyle.interSemi(
                          size: 14,
                          color: AppStyle.textPrimary,
                        ),
                      ),
                    if (job.distanceKm != null)
                      Text(
                        _distanceLine!,
                        style: AppStyle.interNormal(
                          size: 12,
                          color: AppStyle.textDarkSecondary,
                        ),
                      ),
                    _paymentTag(),
                  ],
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          // Kept at full tap size at every width — frame 49e is explicit
          // that Claim and the payment tag do not degrade at the fold.
          TextButton(
            onPressed: onClaim,
            style: TextButton.styleFrom(
              backgroundColor: AppStyle.primary,
              foregroundColor: AppStyle.blackColor,
              minimumSize: Size(72.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              AppHelpers.getTranslation(TrKeys.claim),
              style: AppStyle.interSemi(size: 13, color: AppStyle.blackColor),
            ),
          ),
        ],
      ),
    );
  }

  /// "Sandton City → Morningside". Suburbs only; see the file header.
  String? get _leg {
    final from = job.pickupSuburb;
    final to = job.dropOffSuburb;
    if (from == null || from.isEmpty) return to;
    if (to == null || to.isEmpty) return from;
    return '$from → $to';
  }

  /// "2.4 km away" at 390, "2.4 km" at the fold.
  String? get _distanceLine {
    final km = job.distanceKm;
    if (km == null) return null;
    final value =
        '${km.toStringAsFixed(1)} '
        '${AppHelpers.getTranslation(TrKeys.km)}';
    return compact ? value : '$value ${AppHelpers.getTranslation(TrKeys.away)}';
  }

  Widget _paymentTag() {
    final cash = job.isCash;
    final label = cash
        ? '${AppHelpers.getTranslation(TrKeys.cash).toUpperCase()}'
              '${job.cashAmount != null ? ' ${AppHelpers.numberFormat(number: job.cashAmount)}' : ''}'
        : AppHelpers.getTranslation(TrKeys.paid).toUpperCase();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppStyle.transparent,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: cash ? AppStyle.primary : AppStyle.strokeDark,
        ),
      ),
      child: Text(
        label,
        style: AppStyle.interSemi(
          size: 11,
          color: cash ? AppStyle.primary : AppStyle.textDarkSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
