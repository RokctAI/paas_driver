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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/infrastructure/wallet_balance_cache.dart';
import 'package:revenue_sdk/src/driver/application/wallet/wallet_notifier.dart';
import 'package:revenue_sdk/src/driver/application/wallet/wallet_provider.dart';
import 'package:revenue_sdk/src/common/application/withdraw/withdraw_provider.dart';
import 'package:revenue_sdk/src/common/presentation/payouts/driver_payouts_page.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/driver_balance_head.dart';
import 'package:revenue_sdk/src/common/presentation/wallet/wallet_grammar.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/wallet_movement_list.dart';
import 'package:revenue_sdk/src/common/presentation/withdraw/withdraw_sheet.dart';

/// Frame 49f — the driver's wallet plane.
///
/// There is no wallet screen in the driver app today: a read-only number on
/// the profile page, a second read-only number on the income page, and (until
/// revenue_sdk 1.7.0) a Withdraw button wired to `onPressed: () {}`. This is
/// the plane those numbers were missing — his balance including when it is
/// negative, what put it there, and the way out.
///
/// PLANE DISCIPLINE. Profile and income are hubs and hubs cap at two planes,
/// so this is plane 2: it takes the canonical back pill (chip 347) at the
/// bottom-end corner and draws NO floating nav. Everything downstream of it
/// is a sheet and takes no plane at all. It is pushed on the ROOT navigator,
/// exactly as `RevenueDetailPage` is, which is what folds the host's nav
/// away while it is open.
///
/// **The Top up action (chip 973)** is the entry to 49g. It pushes
/// delivery_sdk's `/driver-deposits?choose=1` — the deposit status plane
/// (49i) with the method chooser (49g) opened over it — by PATH, because
/// revenue_sdk imports only base_sdk (ADR-005) and the two SDKs meet on
/// the route, not on a class. A composition without that route (a driver
/// app on an older delivery_sdk) hears one friendly line instead of
/// seeing nothing: a pill that opens nothing is the dead control this
/// plane was drawn to end, so the guard is the pill's price of admission.
class DriverWalletPage extends ConsumerStatefulWidget {
  const DriverWalletPage({super.key});

  /// Pushes the plane over the whole shell (root navigator = the nav fold).
  static Future<void> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const DriverWalletPage()),
    );
  }

  @override
  ConsumerState<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends ConsumerState<DriverWalletPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(driverWalletProvider.notifier).load(context);
    });
  }

  /// The figure on screen: the server's word once it lands, the cached one
  /// until then. Never a zero we made up — see [DriverWalletState.balance].
  num get _balance =>
      ref.watch(driverWalletProvider).balance ?? WalletBalanceCache.cached;

  void _openWithdraw(num balance) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: Consumer(
        builder: (context, ref, _) {
          final withdraw = ref.watch(withdrawProvider);
          // The SAME sheet and the SAME notifier the income page opens —
          // chip 983 is one element on two screens, not two withdraw
          // implementations that can drift apart.
          return WithdrawSheet(
            available: balance,
            submitting: withdraw.isSubmitting,
            onSubmit: (amount) {
              ref.read(withdrawProvider.notifier).requestPayout(
                    context: context,
                    amount: amount,
                    onSuccess: (_) {
                      Navigator.pop(context);
                      // The hold is taken and the money has genuinely
                      // left; re-read so the plane and its statement show
                      // what the server actually did.
                      if (mounted) {
                        ref.read(driverWalletProvider.notifier).load(context);
                      }
                    },
                  );
            },
          );
        },
      ),
    );
  }

  /// delivery_sdk's deposit route. The path is the contract between the
  /// two SDKs (delivery_sdk >= 1.18.0 declares it); an older composition
  /// answers the push with a failure and the driver hears why.
  static const String depositRoutePath = '/driver-deposits?choose=1';

  Future<void> _openTopUp() async {
    await context.router.pushNamed(
      depositRoutePath,
      onFailure: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppHelpers.getTranslation(
                'top_ups_are_not_available_in_this_app_yet',
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverWalletProvider);
    final balance = _balance;
    final blockedKey = withdrawBlockedKey(balance);
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
                      AppHelpers.getTranslation(TrKeys.wallet),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    20.verticalSpace,
                    DriverBalanceHead(
                      balance: balance,
                      feesThisMonth: state.feesThisMonth,
                      failed: state.balanceFailed,
                    ),
                    20.verticalSpace,
                    CustomButton(
                      key: const Key('walletWithdrawAction'),
                      title: AppHelpers.getTranslation(TrKeys.withdrawMoney),
                      background: canWithdraw(balance)
                          ? AppStyle.primary
                          : AppStyle.strokeDark,
                      textColor: canWithdraw(balance)
                          ? AppStyle.blackColor
                          : AppStyle.textDarkFaint,
                      onPressed: canWithdraw(balance)
                          ? () => _openWithdraw(balance)
                          : () {},
                    ),
                    if (blockedKey != null) ...[
                      8.verticalSpace,
                      Text(
                        AppHelpers.getTranslation(blockedKey),
                        key: const Key('walletWithdrawBlockedLine'),
                        textAlign: TextAlign.center,
                        style: AppStyle.interRegular(
                          size: 11,
                          color: AppStyle.textDarkFaint,
                        ),
                      ),
                    ],
                    10.verticalSpace,
                    // Chip 973 — Top up: the entry to the deposit route
                    // (49g -> 49h -> 49i), which lives in delivery_sdk.
                    CustomButton(
                      key: const Key('walletTopUpAction'),
                      title: AppHelpers.getTranslation('top_up'),
                      background: AppStyle.cardDarkAlt,
                      textColor: AppStyle.textPrimary,
                      onPressed: _openTopUp,
                    ),
                    16.verticalSpace,
                    GestureDetector(
                      key: const Key('walletOpenPayouts'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => DriverPayoutsPage.push(context),
                      child: Center(
                        child: Text(
                          AppHelpers.getTranslation('your_payouts'),
                          style: AppStyle.interNoSemi(
                            size: 11.5,
                            color: AppStyle.primary,
                          ),
                        ),
                      ),
                    ),
                    24.verticalSpace,
                    Text(
                      AppHelpers.getTranslation('recent').toUpperCase(),
                      style: AppStyle.interSemi(
                        size: 10.5,
                        letterSpacing: 1.2,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    12.verticalSpace,
                    WalletMovementList(
                      movements: state.movements,
                      foldedRowCount: DriverWalletNotifier.foldedRowCount,
                      showAll: state.showAllMovements,
                      isLoading: state.isLoadingMovements,
                      failed: state.movementsFailed,
                      onShowAll: () => ref
                          .read(driverWalletProvider.notifier)
                          .showAllMovements(),
                    ),
                  ],
                ),
              ),
            ),
            // Chip 347: the canonical back pill, bottom-end corner, no nav
            // — plane 2 of the hub.
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
}
