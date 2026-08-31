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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/infrastructure/wallet_balance_cache.dart';
import 'package:revenue_sdk/src/driver/application/payouts/payout_history_provider.dart';
import 'package:revenue_sdk/src/driver/presentation/payouts/payout_history_list.dart';
import 'package:revenue_sdk/src/driver/presentation/payouts/payout_status_trail.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/wallet_grammar.dart';

/// Frame 49k — the payout trail.
///
/// It exists for one reason: **a balance that has already dropped, against a
/// payment that has not yet arrived, is the exact gap in which a driver
/// decides the app has stolen from him.** `request_payout` debits at request
/// time (`payout.py:345`), so between tapping Withdraw and the money landing
/// in his bank there is a window where his wallet is empty and nothing has
/// been paid. This screen is what fills that window.
///
/// Nothing here is invented except the layout: every state, every transition
/// and every credit-back is already implemented server-side. It is a READ —
/// resolution is desk-side, and the one self-service transition the backend
/// allows (cancelling a still-`Requested` payout, `payout.py:388-427`) is
/// deliberately not offered, because who may cancel and until when is a
/// policy question the frame flagged rather than settled.
///
/// PLANE DISCIPLINE: plane 2 of the income hub — the canonical back pill
/// (chip 347) at the bottom-end corner, no floating nav, pushed on the root
/// navigator so the host's nav folds away while it is open.
class DriverPayoutsPage extends ConsumerStatefulWidget {
  const DriverPayoutsPage({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const DriverPayoutsPage()),
    );
  }

  @override
  ConsumerState<DriverPayoutsPage> createState() => _DriverPayoutsPageState();
}

class _DriverPayoutsPageState extends ConsumerState<DriverPayoutsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(payoutHistoryProvider.notifier).load(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(payoutHistoryProvider);
    final live = liveRequest(state.requests);
    final outstanding = outstandingPayoutTotal(state.requests);
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 92.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.income),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    20.verticalSpace,
                    _availableCard(outstanding),
                    if (live != null) ...[
                      20.verticalSpace,
                      PayoutStatusTrail(request: live),
                    ],
                    24.verticalSpace,
                    Text(
                      AppHelpers.getTranslation('your_payouts').toUpperCase(),
                      style: AppStyle.interSemi(
                        size: 10.5,
                        letterSpacing: 1.2,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    12.verticalSpace,
                    PayoutHistoryList(
                      requests: state.requests,
                      isLoading: state.isLoading,
                      failed: state.failed,
                      loadedOnce: state.loadedOnce,
                    ),
                    20.verticalSpace,
                    _guaranteeCard(),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: 16,
              child: FloatingBackPill(
                back: FloatingNavBack(
                  icon: Remix.arrow_left_s_line,
                  label: AppHelpers.getTranslation(TrKeys.back),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What is left to draw, and — when something is out — where the rest of
  /// it went. The balance is the cached profile figure, the same number the
  /// income page and the wallet plane are showing; this screen makes no
  /// second claim about it.
  Widget _availableCard(num outstanding) {
    final balance = WalletBalanceCache.cached;
    return Container(
      key: const Key('payoutAvailableCard'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('available_to_withdraw').toUpperCase(),
            style: AppStyle.interSemi(
              size: 10.5,
              letterSpacing: 1.2,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          14.verticalSpace,
          Text(
            AppHelpers.numberFormat(number: balance),
            style: AppStyle.interSemi(
              size: 24,
              color: balance < 0 ? AppStyle.red : AppStyle.textPrimary,
            ),
          ),
          if (outstanding > 0) ...[
            10.verticalSpace,
            Text(
              '${AppHelpers.numberFormat(number: outstanding)} '
              '${AppHelpers.getTranslation('is_out_on_a_payout_request')}',
              key: const Key('payoutOutstandingLine'),
              style: AppStyle.interRegular(
                size: 11,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Not a chip — the plain-language statement of `_release_hold`'s
  /// guarantee and the `hold_released` latch, written for a person rather
  /// than for a reviewer.
  Widget _guaranteeCard() => Container(
        key: const Key('payoutGuaranteeCard'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppHelpers.getTranslation(
                'your_money_is_never_stuck_in_between',
              ),
              style: AppStyle.interNoSemi(size: 11.5),
            ),
            8.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'a_rejected_or_cancelled_request_is_credited_back_'
                'automatically_and_it_can_only_happen_once',
              ),
              style: AppStyle.interRegular(
                size: 10.5,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ),
      );
}
