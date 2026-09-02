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

// lib/src/presentation/pages/profile/widgets/base_wallet_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The shared wallet balance card: title row with the wallet icon, the
/// (conditionally shown, conditionally coloured) balance amount, an
/// optional history arrow and an optional caller-supplied action strip.
///
/// Promoted from marketplace_sdk's `MarketplaceWalletCard` — the card
/// chrome and balance line already read only base_sdk symbols (same
/// promotion precedent as [ProfileMetaRow] / `BaseProfileFooter`). What
/// stays SDK-side are the actions themselves: marketplace's Top-up /
/// Send / Loan buttons open marketplace screens, so an SDK passes its
/// own buttons through [actions] instead of base_sdk hardcoding them.
///
/// Balance rendering rule (product ask):
///  * `null` or exactly `0` — the balance amount is NOT rendered at all;
///    the card still shows its title, history arrow and [actions] so the
///    buttons stay useful.
///  * positive — the amount renders in [AppStyle.green].
///  * negative — the amount renders in [AppStyle.red].
///
/// Data source: an explicit [wallet] snapshot wins (the same snapshot
/// seam shape as `AppUsageBadge.period` / an LMS plan row's `snapshot:`);
/// otherwise the live [profileProvider] wallet, falling back to
/// [LocalStorage.getWalletData] for the offline case.
class BaseWalletCard extends ConsumerWidget {
  /// Snapshot seam: when non-null this wallet is rendered as-is and the
  /// live [profileProvider] is never watched. Meant for tests and for
  /// hosts that already hold a fresher wallet than the profile state.
  ///
  /// (Named `wallet`, not `override` — a field named `override` shadows
  /// dart:core's `@override` annotation inside the class body and breaks
  /// compilation.)
  final Wallet? wallet;

  /// Renders the top-right history arrow when non-null; the SDK decides
  /// where "history" navigates (base_sdk imposes no route).
  final VoidCallback? onHistory;

  /// SDK-supplied action buttons laid out in a [Row] inside the card's
  /// bottom strip; wrap each in [Expanded] for the evenly-split
  /// marketplace look. Empty (the default) omits the strip entirely.
  final List<Widget> actions;

  /// Currency symbol passed through to [AppHelpers.numberFormat] (with
  /// `isOrder: true`) for hosts with no stored currency — e.g. lms.
  /// Null keeps the stored-currency default.
  final String? symbol;

  const BaseWalletCard({
    super.key,
    this.wallet,
    this.onHistory,
    this.actions = const [],
    this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `wallet ??` short-circuits: with a snapshot supplied the live
    // provider is never built (keeps the widget testable without DI).
    final Wallet? effectiveWallet = wallet ??
        ref.watch(profileProvider.select((s) => s.userData?.wallet)) ??
        LocalStorage.getWalletData();
    final num? price = effectiveWallet?.price;

    // THE rule: zero/absent balance hides the amount entirely; positive
    // is green, negative is red. AppStyle.green / AppStyle.red are the
    // palette's only green/red tokens (no semantic aliases exist).
    final bool showBalance = price != null && price != 0;
    final Color amountColor =
        (price != null && price < 0) ? AppStyle.red : AppStyle.green;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppStyle.primary.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          if (onHistory != null)
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: onHistory,
                child: Icon(
                  Remix.arrow_right_up_line,
                  color: AppStyle.textPrimary,
                ),
              ),
            ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(Remix.wallet_3_line, color: AppStyle.textPrimary),
                    16.horizontalSpace,
                    Text(
                      showBalance
                          ? "${AppHelpers.getTranslation(TrKeys.wallet)}: "
                          : AppHelpers.getTranslation(TrKeys.wallet),
                      style: AppStyle.interNoSemi(
                        size: 16,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                    if (showBalance)
                      Text(
                        AppHelpers.numberFormat(
                          number: price,
                          symbol: symbol,
                          isOrder: symbol != null,
                        ),
                        style: AppStyle.interNoSemi(
                          size: 16,
                          color: amountColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: AppStyle.red.withOpacity(0.3),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                    ),
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Row(children: actions),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
