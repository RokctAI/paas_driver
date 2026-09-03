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

// Design strip frame 49g — card or bank deposit: the method chooser.
//
// Ray's words set this frame: "he might need to top up. maybe by card or
// by bank deposit". Two rows at equal weight because they are equally real
// to the driver. Card is instant — the balance moves straight away — and
// lives in wallet_sdk's /wallet-topup route when that SDK is composed;
// bank deposit is slower and needs a person, and 49h/49i draw it. A sheet
// overlays and takes no plane: no back pill, no nav.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Chip 974 — the method chooser, chipped as ONE component because the
/// honest content of the screen is the comparison.
///
/// Owns no truth and sends nothing: it hands the driver's choice back
/// through [onCard] / [onBankDeposit] and the caller ([DriverDepositFlow])
/// routes it.
class DepositMethodSheet extends StatelessWidget {
  const DepositMethodSheet({
    super.key,
    required this.balance,
    required this.onCard,
    required this.onBankDeposit,
    this.bankDepositsAccepted = true,
    this.cardAvailable = true,
  });

  /// The wallet as it stands (null while unread). May be negative; stated
  /// as a sentence.
  final num? balance;

  final VoidCallback onCard;
  final VoidCallback onBankDeposit;

  /// False when the tenant is not accepting bank deposits (or has no pay-in
  /// account configured): the row states so and goes inert.
  final bool bankDepositsAccepted;

  /// False when this composition has no card top-up route: the row states
  /// so and goes inert rather than opening nothing.
  final bool cardAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('depositMethodSheet'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: MediaQuery.paddingOf(context).bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 100.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppStyle.strokeDark,
                borderRadius: BorderRadius.circular(40.r),
              ),
            ),
          ),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation('top_up_your_wallet'),
            style: AppStyle.interSemi(size: 16),
          ),
          4.verticalSpace,
          Text(
            (balance ?? 0) < 0
                ? AppHelpers.getTranslation('bring_your_balance_back_above_zero')
                : AppHelpers.getTranslation('add_money_to_your_wallet'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          16.verticalSpace,
          _row(
            key: const Key('depositMethodCard'),
            icon: Remix.bank_card_line,
            title: AppHelpers.getTranslation('card'),
            line: cardAvailable
                ? AppHelpers.getTranslation(
                    'instant_the_balance_moves_straight_away')
                : AppHelpers.getTranslation(
                    'card_top_up_is_not_available_in_this_app_yet'),
            enabled: cardAvailable,
            onTap: onCard,
          ),
          10.verticalSpace,
          _row(
            key: const Key('depositMethodBank'),
            icon: Remix.bank_line,
            title: AppHelpers.getTranslation('bank_deposit'),
            line: bankDepositsAccepted
                ? AppHelpers.getTranslation(
                    'pay_in_photograph_the_slip_the_office_approves')
                : AppHelpers.getTranslation(
                    'bank_deposits_are_not_being_accepted_right_now'),
            enabled: bankDepositsAccepted,
            onTap: onBankDeposit,
          ),
          14.verticalSpace,
          TextButton(
            key: const Key('depositMethodCancel'),
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              AppHelpers.getTranslation(TrKeys.cancel),
              style: AppStyle.interSemi(size: 13, color: AppStyle.textDarkSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required Key key,
    required IconData icon,
    required String title,
    required String line,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final Color fg = enabled ? AppStyle.textPrimary : AppStyle.textDarkFaint;
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: enabled ? AppStyle.strokeDark : AppStyle.strokeDarkSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22.r, color: enabled ? AppStyle.primary : fg),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppStyle.interSemi(size: 14, color: fg)),
                  3.verticalSpace,
                  Text(
                    line,
                    style: AppStyle.interRegular(
                      size: 11.5,
                      color: enabled
                          ? AppStyle.textDarkSecondary
                          : AppStyle.textDarkFaint,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Remix.arrow_right_s_line, size: 20.r, color: fg),
          ],
        ),
      ),
    );
  }
}
