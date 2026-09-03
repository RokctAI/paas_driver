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

// The driver's withdraw step.
//
// The "Withdraw Money" button on the driver income page shipped as
// `onPressed: () {}` — a dead control on a money screen. This is what it
// opens.
//
// Money-entry surface: Ray's standing rule is that the fleet KEYPAD is the
// money-entry surface wherever amounts are typed, so this is the same dark
// bottom sheet as delivery_sdk's CashCollectionSheet (design strip section
// 45, chip 390 adopted unchanged) — drag handle, an available-balance card,
// the amount question, a NON-FOCUSABLE read-out so the OS keyboard can
// never appear behind the pad, then MoneyKeypad, then the commit button.
// No new chrome is invented here.
//
// The sheet OWNS NO TRUTH about the money. The server re-reads the balance
// under a Wallet row lock and is the only authority on whether the payout
// is allowed; the client-side checks below exist so the driver is not sent
// on a round trip he cannot win, not to decide anything.

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keypad/money_keypad.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/presentation/bank/bank_grammar.dart';

/// The withdraw amount sheet.
///
/// Hands a validated, strictly-positive amount back through [onSubmit];
/// sending it is the caller's job, so this widget stays free of the
/// repository, of DI and of navigation.
class WithdrawSheet extends StatefulWidget {
  const WithdrawSheet({
    super.key,
    required this.available,
    required this.onSubmit,
    this.submitting = false,
    this.accounts = const [],
    this.selectedAccountId,
    this.onSelectAccount,
  });

  /// The balance the page already has. The server re-checks it anyway.
  final num available;

  /// Commit: hands back the amount to request.
  final void Function(double amount) onSubmit;

  /// While true the commit button is inert and reads as busy, so a
  /// double-tap cannot fire two holds.
  final bool submitting;

  /// The driver's saved bank accounts (chip 985 — the bank block, the fields
  /// the doctype snapshots onto the request row).
  ///
  /// The sheet is only ever opened with at least one: a driver with none
  /// meets frame 49n's explanation instead, so `request_payout` is never
  /// fired blind. Defaulted to empty so the sheet stays constructible in
  /// isolation and the block simply does not draw.
  final List<BankAccountRecord> accounts;

  /// Which account the request will name. Passed EXPLICITLY on
  /// `request_payout` rather than left to the server's default, because
  /// `_default_account` returns nothing when a driver has two unmarked rows
  /// (`payout.py:137-157`) — naming the account makes that refusal
  /// unreachable from this screen.
  final String? selectedAccountId;

  /// Null when there is nothing to choose between.
  final ValueChanged<String>? onSelectAccount;

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  /// The keypad entry. Starts EMPTY on purpose — unlike the cash step
  /// there is no expected figure to prefill, and seeding the whole
  /// balance would invite a mis-tap that empties the wallet.
  String _entry = '';

  double get _amount => double.tryParse(_entry) ?? 0;

  double get _availableAsDouble => widget.available.toDouble();

  /// Nothing to withdraw: a wallet at or below zero. Negative is a normal,
  /// deliberate state for a driver (he keeps the cash he collects and his
  /// ledger carries the debt), so this is stated plainly rather than
  /// treated as an error.
  bool get _nothingToWithdraw => _availableAsDouble <= 0;

  bool get _isNumber => double.tryParse(_entry) != null;

  bool get _overBalance => _isNumber && _amount > _availableAsDouble;

  bool get _valid =>
      !_nothingToWithdraw && _isNumber && _amount > 0 && !_overBalance;

  bool get _canSubmit => _valid && !widget.submitting;

  /// The one line under the read-out. Empty while the entry is fine.
  String get _problem {
    if (_nothingToWithdraw) {
      return AppHelpers.getTranslation(TrKeys.insufficientBalance);
    }
    if (_entry.isEmpty) return '';
    if (!_isNumber || _amount <= 0) {
      return AppHelpers.getTranslation(TrKeys.pleaseEnterValidAmount);
    }
    if (_overBalance) {
      return AppHelpers.getTranslation(TrKeys.insufficientBalance);
    }
    return '';
  }

  void _digit(String d) => setState(() {
        _entry = MoneyEntry.appendDigit(_entry, d);
      });

  void _backspace() => setState(() {
        _entry = MoneyEntry.backspace(_entry);
      });

  void _decimal() => setState(() {
        _entry = MoneyEntry.decimal(_entry);
      });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SingleChildScrollView(
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
              AppHelpers.getTranslation(TrKeys.withdrawMoney),
              style: AppStyle.interSemi(size: 16),
            ),
            14.verticalSpace,
            _availableCard(),
            if (widget.accounts.isNotEmpty) ...[
              14.verticalSpace,
              _bankBlock(),
            ],
            18.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.enterAmount),
              style: AppStyle.interSemi(size: 16),
            ),
            10.verticalSpace,
            _amountReadout(),
            8.verticalSpace,
            _problemLine(),
            16.verticalSpace,
            // The fleet keypad, adopted unchanged. No OK key: the sheet's
            // own commit button is the commit, so the pad stays a pure
            // input surface (its published contract).
            MoneyKeypad(
              onDigit: _digit,
              onBackspace: _backspace,
              onDecimal: _decimal,
            ),
            18.verticalSpace,
            CustomButton(
              key: const Key('withdrawSubmit'),
              title: AppHelpers.getTranslation(TrKeys.withdraw),
              background: _canSubmit ? AppStyle.primary : AppStyle.strokeDark,
              textColor:
                  _canSubmit ? AppStyle.blackColor : AppStyle.textDarkFaint,
              isLoading: widget.submitting,
              onPressed: _canSubmit ? () => widget.onSubmit(_amount) : () {},
            ),
          ],
        ),
      ),
    );
  }

  /// What he may ask for. Read-only.
  Widget _availableCard() {
    return Container(
      key: const Key('withdrawAvailableCard'),
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _nothingToWithdraw ? AppStyle.strokeDark : AppStyle.primary,
        ),
      ),
      child: Text(
        '${AppHelpers.getTranslation(TrKeys.balance)}: '
        '${AppHelpers.numberFormat(number: widget.available)}',
        textAlign: TextAlign.center,
        style: AppStyle.interBold(
          size: 16,
          color: _nothingToWithdraw ? AppStyle.textDarkSecondary : AppStyle.primary,
        ),
      ),
    );
  }

  /// Chip 985 — the bank block: where this money is going, and (when there
  /// is more than one account) which one it is going to.
  ///
  /// Shown BEFORE the amount, because the question "where does this go" is
  /// the one a driver answers first and the one the old dead-ended sheet
  /// could not answer at all.
  Widget _bankBlock() {
    final selected = widget.accounts.firstWhere(
      (account) => account.id == widget.selectedAccountId,
      orElse: () =>
          defaultAccount(widget.accounts) ?? widget.accounts.first,
    );
    return Container(
      key: const Key('withdrawBankBlock'),
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('paid_to').toUpperCase(),
            style: AppStyle.interSemi(
              size: 10,
              letterSpacing: 1.2,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          8.verticalSpace,
          Text(
            '${accountSummary(selected)} · '
            '${maskAccountNumber(selected.accountNumber)}',
            style: AppStyle.interNoSemi(size: 12),
          ),
          if (widget.accounts.length > 1 && widget.onSelectAccount != null) ...[
            10.verticalSpace,
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final account in widget.accounts)
                  GestureDetector(
                    key: Key('withdrawAccount_${account.id}'),
                    onTap: () => widget.onSelectAccount!(account.id),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: account.id == selected.id
                            ? AppStyle.primary
                            : AppStyle.cardDark,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: account.id == selected.id
                              ? AppStyle.primary
                              : AppStyle.strokeDark,
                        ),
                      ),
                      child: Text(
                        maskAccountNumber(account.accountNumber),
                        style: AppStyle.interNoSemi(
                          size: 11,
                          color: account.id == selected.id
                              ? AppStyle.blackColor
                              : AppStyle.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          8.verticalSpace,
          // Chip 986 — the debit-at-request notice. `request_payout` writes
          // the balance down at `payout.py:345` BEFORE the request row is
          // inserted at `:349-368`, so the money leaves the moment he taps,
          // not when an admin approves. Saying otherwise here would be the
          // single most expensive sentence on this screen.
          Text(
            AppHelpers.getTranslation(
              'this_comes_off_your_balance_as_soon_as_you_ask_'
              'not_when_its_approved',
            ),
            key: const Key('withdrawDebitNotice'),
            style: AppStyle.interRegular(
              size: 10.5,
              color: AppStyle.textDarkFaint,
            ),
          ),
        ],
      ),
    );
  }

  /// The amount READ-OUT: not a text field, so the OS keyboard can never
  /// appear behind our pad (the same 11y ruling as the cash step).
  Widget _amountReadout() {
    return Container(
      key: const Key('withdrawAmountReadout'),
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Text(
        _entry.isEmpty ? '0' : _entry,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyle.interSemi(
          size: 30,
          color: _entry.isEmpty ? AppStyle.textDarkFaint : AppStyle.textPrimary,
        ),
      ),
    );
  }

  Widget _problemLine() {
    final text = _problem;
    return SizedBox(
      height: 20.h,
      child: text.isEmpty
          ? const SizedBox.shrink()
          : Text(
              text,
              key: const Key('withdrawProblemLine'),
              style: AppStyle.interRegular(size: 13, color: AppStyle.red),
            ),
    );
  }
}
