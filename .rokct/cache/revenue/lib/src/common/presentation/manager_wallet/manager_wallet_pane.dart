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

// Design strip frame 49l — the manager withdraws: the same request as the
// driver's 49j, on a card that was approved with no actions at all.
//
// The manager hub renders base_sdk's `BaseWalletCard`
// (`core/base/dart/lib/src/presentation/pages/profile/widgets/base_wallet_card.dart`)
// from the merchants restaurant page with `actions: []` — section 7's
// approved composition on Ray's words "wallet element but without send and
// topup". Withdraw is neither of the two he excluded, and frame 49l, which
// he approved on 2026-08-31 ("49d, 49f-l approved"), draws exactly one
// action on that strip (chip 989) beside the same debit-at-request notice
// the driver's sheet carries (chip 986).
//
// This file is the revenue half of that frame. It does NOT touch the hub:
// the merchants page keeps its card and passes this pane (or just the
// action) where it passed `actions: []`. The request sheet, the no-account
// sheet, the sent sheet and the payout trail are 49j/49k/49n/49r reused as
// they are — same endpoint, same doctype, same debit timing, same credit
// back — because the flow is identical for both actors.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_wallet_card.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_provider.dart';
import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_scope.dart';
import 'package:revenue_sdk/src/common/presentation/bank/bank_account_form_page.dart';
import 'package:revenue_sdk/src/common/presentation/bank/no_bank_account_sheet.dart';
import 'package:revenue_sdk/src/common/presentation/bank/payout_sent_sheet.dart';
import 'package:revenue_sdk/src/common/presentation/deposit_approvals/deposit_approvals_page.dart';
import 'package:revenue_sdk/src/common/presentation/payouts/driver_payouts_page.dart';
import 'package:revenue_sdk/src/common/presentation/withdraw/withdraw_sheet.dart';

/// The wallet region of the manager hub with frame 49l's Withdraw on it.
///
/// Drop-in for the hub's bare `BaseWalletCard(actions: [], onHistory: null)`:
/// the same card, now carrying [ManagerWithdrawAction] on its strip (chip
/// 989), the history arrow into the payout trail (frame 49k), and the
/// debit-at-request notice under it (chip 986). Balance sourcing is the
/// card's own — an explicit [wallet] snapshot wins, otherwise the live
/// profile wallet with the offline fallback — until a payout is accepted
/// on this pane, after which the server's post-hold balance is drawn.
class ManagerWalletPane extends ConsumerWidget {
  const ManagerWalletPane({
    super.key,
    required this.scope,
    this.wallet,
    this.symbol,
    this.showHistory = true,
    this.showDepositApprovals = true,
  });

  /// Which shop this pane stands on. See [ManagerWalletScope] for what it
  /// is — and is not — used for.
  final ManagerWalletScope scope;

  /// Snapshot seam, passed through to [BaseWalletCard.wallet]. Null lets
  /// the card self-source from the profile fetch, as the hub does today.
  final Wallet? wallet;

  /// Passed through to [BaseWalletCard.symbol].
  final String? symbol;

  /// Whether the card's history arrow opens the payout trail (frame 49k).
  final bool showHistory;

  /// Whether the "Deposits to approve" entry (design strip frame 49i, the
  /// manager's side of the driver's bank deposit) draws under the card.
  final bool showDepositApprovals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(
      managerWalletProvider(scope).select((s) => s.balanceAfterHold),
    );
    // Once a hold has been taken, the post-hold figure replaces the
    // snapshot: the money has already left and the card must say so.
    final Wallet? effectiveWallet =
        held == null ? wallet : (wallet ?? Wallet()).copyWith(price: held);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BaseWalletCard(
          key: const Key('managerWalletCard'),
          wallet: effectiveWallet,
          symbol: symbol,
          onHistory:
              showHistory ? () => DriverPayoutsPage.push(context) : null,
          actions: [
            Expanded(
              child: ManagerWithdrawAction(scope: scope, wallet: wallet),
            ),
          ],
        ),
        6.verticalSpace,
        // Chip 986 — the debit-at-request notice, reused not re-minted:
        // `request_payout` writes the balance down at `payout.py:345`
        // BEFORE the request row exists at `:349-368`, so the money leaves
        // the moment he taps, not when an admin approves.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            AppHelpers.getTranslation(
              'this_comes_off_your_balance_as_soon_as_you_ask_'
              'not_when_its_approved',
            ),
            key: const Key('managerWalletDebitNotice'),
            style: AppStyle.interRegular(size: 10.5, color: AppStyle.textHint),
          ),
        ),
        if (showDepositApprovals) ...[
          10.verticalSpace,
          // Frame 49i, manager side: the queue of driver bank deposits
          // waiting for a person to match them to the bank statement.
          // A plain row, not a CustomButton — the card's strip keeps its
          // ONE action (chip 989); this is an entry to plane 2, not a
          // second action on the money.
          GestureDetector(
            key: const Key('managerWalletDepositApprovals'),
            behavior: HitTestBehavior.opaque,
            onTap: () => DepositApprovalsPage.push(context),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
              child: Row(
                children: [
                  Icon(Remix.bank_line, size: 16.r, color: AppStyle.primary),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      AppHelpers.getTranslation('deposits_to_approve'),
                      style: AppStyle.interNoSemi(
                        size: 12,
                        color: AppStyle.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Remix.arrow_right_s_line,
                    size: 16.r,
                    color: AppStyle.textDarkSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip 989 — the one action on the card's strip. Usable on its own inside
/// a host's own `BaseWalletCard(actions: [Expanded(child: ...)])` when the
/// host wants to keep its card; [ManagerWalletPane] is that already wired.
class ManagerWithdrawAction extends ConsumerStatefulWidget {
  const ManagerWithdrawAction({super.key, required this.scope, this.wallet});

  final ManagerWalletScope scope;

  /// The snapshot the card is drawing, when the host passed one, so the
  /// sheet can never disagree with what the manager is looking at.
  final Wallet? wallet;

  @override
  ConsumerState<ManagerWithdrawAction> createState() =>
      _ManagerWithdrawActionState();
}

class _ManagerWithdrawActionState extends ConsumerState<ManagerWithdrawAction> {
  ManagerWalletScope get _scope => widget.scope;

  /// The balance the card is showing, in the card's own order: the
  /// post-hold figure once one exists, else the host's snapshot, else the
  /// live profile wallet, else the offline fallback.
  num get _balance {
    final held = ref.read(managerWalletProvider(_scope)).balanceAfterHold;
    if (held != null) return held;
    final snapshot = widget.wallet?.price;
    if (snapshot != null) return snapshot;
    return ref.read(profileProvider).userData?.wallet?.price ??
        LocalStorage.getWalletData()?.price ??
        0;
  }

  /// Nothing to withdraw at or below zero. A shop balance can be negative
  /// (the platform fronts credit), and as on the driver's side that is a
  /// fact to state, not an error to dress up — the control is simply inert.
  bool get _canWithdraw => _balance > 0;

  /// The withdraw path, in the order frame 49n insists on: accounts first,
  /// then either the explanation or the sheet. No request is ever sent on
  /// the no-account path and nothing is held.
  Future<void> _openWithdraw() async {
    final notifier = ref.read(managerWalletProvider(_scope).notifier);
    await notifier.loadAccounts(context: context);
    if (!mounted) return;
    final state = ref.read(managerWalletProvider(_scope));
    if (state.accountsFailed) return;
    if (state.accounts.isEmpty) {
      _openNoBankAccountSheet();
      return;
    }
    _openWithdrawSheet();
  }

  /// Frame 49n. Not an error card: nothing has failed, and the primary
  /// action is Add a bank account rather than Retry or Close.
  void _openNoBankAccountSheet() {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: NoBankAccountSheet(
        available: _balance,
        onDismiss: () => Navigator.pop(context),
        onAddBankAccount: () async {
          Navigator.pop(context);
          final saved = await BankAccountFormPage.push(context);
          if (!mounted || saved == null) return;
          ref.read(managerWalletProvider(_scope).notifier).adoptAccount(saved);
          _openWithdrawSheet();
        },
      ),
    );
  }

  void _openWithdrawSheet() {
    final balanceBefore = _balance;
    final notifier = ref.read(managerWalletProvider(_scope).notifier);
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(managerWalletProvider(_scope));
          return WithdrawSheet(
            available: balanceBefore,
            submitting: state.isSubmitting,
            accounts: state.accounts,
            selectedAccountId: state.selectedAccountId,
            onSelectAccount: notifier.selectAccount,
            onSubmit: (amount) {
              notifier.requestPayout(
                context: context,
                amount: amount,
                onSuccess: (newBalance) {
                  // The hold is taken; close the sheet and state the
                  // subtraction on the sent sheet.
                  Navigator.pop(context);
                  if (!mounted) return;
                  _openPayoutSentSheet(
                    balanceBefore: balanceBefore,
                    amount: amount,
                    newBalance: newBalance ?? balanceBefore - amount,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Frame 49r, reused: what he had, what has left, what is there now.
  void _openPayoutSentSheet({
    required num balanceBefore,
    required num amount,
    required num newBalance,
  }) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: PayoutSentSheet(
        balanceBefore: balanceBefore,
        amount: amount,
        newBalance: newBalance,
        account: ref.read(managerWalletProvider(_scope)).selectedAccount,
        onDone: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the hold changes the balance the button gates on.
    ref.watch(
      managerWalletProvider(_scope).select((s) => s.balanceAfterHold),
    );
    if (widget.wallet == null) {
      ref.watch(profileProvider.select((s) => s.userData?.wallet?.price));
    }
    final can = _canWithdraw;
    return CustomButton(
      key: const Key('managerWithdrawAction'),
      title: AppHelpers.getTranslation(TrKeys.withdraw),
      background: can ? AppStyle.primary : AppStyle.strokeDark,
      textColor: can ? AppStyle.blackColor : AppStyle.textDarkFaint,
      onPressed: can ? () => _openWithdraw() : () {},
    );
  }
}
