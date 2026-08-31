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

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/driver/application/bank/bank_accounts_provider.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_field.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_grammar.dart';

/// Frames 49o and 49p — adding the account, and the form refusing.
///
/// SIX FIELDS, BECAUSE THE ENDPOINT TAKES SIX. `add_bank_account` takes
/// exactly `account_holder_name`, `bank_name`, `account_number`,
/// `branch_code`, `account_type` and `is_default`
/// (`pay/wallet/frappe/src/tenant/api/payout.py:177-184`), and the order
/// below is that signature order. The doctype's seventh field, `user`, is
/// required and deliberately absent: the endpoint writes it from
/// `frappe.session.user` (`:186, 222`), so a field for it would be a field
/// the driver could get wrong.
///
/// THE THREE RULES, AND NOT A FOURTH. The backend has exactly three
/// constraints on this form — non-empty on the required three, 140
/// characters on every text field, and an account type from the doctype's
/// Select — and this screen enforces those three and stops. There is NO
/// digits-only mask on the account number, no length rule and no branch-code
/// lookup, because none of those exist server-side and the controller is a
/// bare `pass` (`payout_bank_account.py:28-29`). A mask that is not enforced
/// is worse than none: a driver who trusts it will send his money to a typo.
/// The honesty line under the number field says so instead.
///
/// PLANE DISCIPLINE: plane 2 of the income hub — the canonical back pill
/// (chip 347) at the bottom-end corner, no floating nav, pushed on the root
/// navigator so the host's nav folds away while it is open.
class BankAccountFormPage extends ConsumerStatefulWidget {
  const BankAccountFormPage({super.key});

  /// Pushes the form and answers the account that was saved, or null when
  /// the driver backed out without writing one.
  static Future<BankAccountRecord?> push(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<BankAccountRecord>(
      MaterialPageRoute(builder: (_) => const BankAccountFormPage()),
    );
  }

  @override
  ConsumerState<BankAccountFormPage> createState() =>
      _BankAccountFormPageState();
}

class _BankAccountFormPageState extends ConsumerState<BankAccountFormPage> {
  final _holder = TextEditingController();
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _branch = TextEditingController();

  /// Null is a real, storable choice — the doctype's Select carries a
  /// leading blank option (`payout_bank_account.json:62`), so "None" is
  /// drawn as a choice rather than omitted.
  String? _accountType;

  bool _payHereByDefault = false;

  /// Refusals appear only after he has asked to save. Marking a field red
  /// while he is still on his way to it would be scolding him for not having
  /// finished typing.
  bool _submitted = false;

  @override
  void dispose() {
    _holder.dispose();
    _bank.dispose();
    _number.dispose();
    _branch.dispose();
    super.dispose();
  }

  /// This is the driver's FIRST account when he has none saved, in which
  /// case the backend makes it his default whatever the switch says
  /// (`payout.py:205-207`). Drawn and spoken rather than left implicit: a
  /// switch that cannot change the outcome and does not say so is a lie the
  /// driver finds later.
  bool get _isFirstAccount => ref.read(bankAccountsProvider).accounts.isEmpty;

  bool get _canSave => canSaveBankAccount(
        accountHolderName: _holder.text,
        bankName: _bank.text,
        accountNumber: _number.text,
        branchCode: _branch.text,
        accountType: _accountType,
      );

  List<BankField> get _missing => missingRequiredFields(
        accountHolderName: _holder.text,
        bankName: _bank.text,
        accountNumber: _number.text,
      );

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_canSave) return;
    final saved = await ref.read(bankAccountsProvider.notifier).add(
          context: context,
          accountHolderName: _holder.text,
          bankName: _bank.text,
          accountNumber: _number.text,
          branchCode: _branch.text,
          accountType: _accountType,
          isDefault: _payHereByDefault,
        );
    if (saved != null && mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(bankAccountsProvider).isSaving;
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
                      AppHelpers.getTranslation('add_bank_account'),
                      style: AppStyle.interSemi(size: 21),
                    ),
                    6.verticalSpace,
                    Text(
                      AppHelpers.getTranslation(
                        'where_your_withdrawals_will_be_paid',
                      ),
                      style: AppStyle.interRegular(
                        size: 12,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                    22.verticalSpace,
                    BankFormField(
                      fieldKey: const Key('bankHolderField'),
                      label: AppHelpers.getTranslation('account_holder_name'),
                      controller: _holder,
                      isRequired: true,
                      problemKey: _submitted
                          ? requiredFieldProblemKey(
                              BankField.accountHolderName,
                              _holder.text,
                            )
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    18.verticalSpace,
                    BankFormField(
                      fieldKey: const Key('bankNameField'),
                      label: AppHelpers.getTranslation('bank'),
                      controller: _bank,
                      isRequired: true,
                      problemKey: _submitted
                          ? requiredFieldProblemKey(
                              BankField.bankName,
                              _bank.text,
                            )
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    18.verticalSpace,
                    BankFormField(
                      fieldKey: const Key('bankNumberField'),
                      label: AppHelpers.getTranslation('account_number'),
                      controller: _number,
                      isRequired: true,
                      problemKey: _submitted
                          ? requiredFieldProblemKey(
                              BankField.accountNumber,
                              _number.text,
                            )
                          : null,
                      // Chip 1004, and the most load-bearing sentence on the
                      // frame. Nothing anywhere in this path checks the shape
                      // of the number — not the endpoint, not `_required_text`
                      // and not the controller — so the screen says so and
                      // asks him to copy it exactly. Removing this line while
                      // leaving the field unvalidated would make the form
                      // quietly imply a check it does not perform.
                      helperKey: 'nothing_checks_the_shape_of_this_number_'
                          'copy_it_exactly_as_your_bank_shows_it',
                      onChanged: (_) => setState(() {}),
                    ),
                    18.verticalSpace,
                    BankFormField(
                      fieldKey: const Key('bankBranchField'),
                      label: AppHelpers.getTranslation('branch_code'),
                      controller: _branch,
                      isRequired: false,
                      problemKey: _submitted
                          ? optionalFieldProblemKey(
                              BankField.branchCode,
                              _branch.text,
                            )
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    20.verticalSpace,
                    _accountTypeChooser(),
                    22.verticalSpace,
                    _defaultSwitch(),
                    24.verticalSpace,
                    CustomButton(
                      key: const Key('bankSaveButton'),
                      title: AppHelpers.getTranslation('save_account'),
                      background:
                          _canSave ? AppStyle.primary : AppStyle.strokeDark,
                      textColor: _canSave
                          ? AppStyle.blackColor
                          : AppStyle.textDarkFaint,
                      isLoading: saving,
                      onPressed: _canSave && !saving ? _save : () {},
                    ),
                    10.verticalSpace,
                    _underSaveLine(),
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

  /// Chip 1006 — exactly three options, plus none.
  ///
  /// Cheque / Savings / Transmission is the whole Select
  /// (`payout_bank_account.json:62`) and the leading empty option is real,
  /// which is why None is a choice rather than an omission. Anything else is
  /// refused at `payout.py:195-196`, so a free-text field here would be a
  /// field that can only produce a rejection.
  Widget _accountTypeChooser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          AppHelpers.getTranslation('account_type'),
          isRequired: false,
        ),
        10.verticalSpace,
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final type in kBankAccountTypes)
              _typeChip(label: type, value: type),
            _typeChip(
              label: AppHelpers.getTranslation('none'),
              value: null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _typeChip({required String label, required String? value}) {
    final selected = _accountType == value;
    return GestureDetector(
      key: Key('bankType_${value ?? 'none'}'),
      onTap: () => setState(() => _accountType = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? AppStyle.primary : AppStyle.cardDark,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: selected ? AppStyle.primary : AppStyle.strokeDark,
          ),
        ),
        child: Text(
          label,
          style: AppStyle.interNoSemi(
            size: 12,
            color: selected ? AppStyle.blackColor : AppStyle.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Chip 1007 — the default switch, with the rule SPOKEN rather than
  /// implied. `make_default = bool(int(is_default or 0)) or not has_existing`
  /// (`payout.py:205-207`): the first account a driver adds is his default no
  /// matter what the switch says.
  Widget _defaultSwitch() {
    final first = _isFirstAccount;
    return Container(
      key: const Key('bankDefaultSwitch'),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppHelpers.getTranslation('pay_me_here_by_default'),
                  style: AppStyle.interNoSemi(size: 13),
                ),
              ),
              Switch(
                value: first || _payHereByDefault,
                activeThumbColor: AppStyle.primary,
                // Inert on a first account, because the outcome cannot
                // change: the server marks it default either way.
                onChanged: first
                    ? null
                    : (value) => setState(() => _payHereByDefault = value),
              ),
            ],
          ),
          if (first) ...[
            4.verticalSpace,
            Text(
              AppHelpers.getTranslation(
                'this_is_your_first_account_so_it_becomes_your_default_'
                'whether_you_switch_this_on_or_not',
              ),
              key: const Key('bankFirstAccountRule'),
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

  /// Chip 1010's companion: what is still missing, counted, under a button
  /// that is held until the form can succeed. On a complete form it becomes
  /// the privacy line frame 49o draws in its place.
  Widget _underSaveLine() {
    final missing = _missing.length;
    final text = missing > 0
        ? '$missing ${AppHelpers.getTranslation('things_still_to_fill_in')}'
        : AppHelpers.getTranslation('only_you_can_see_or_use_this_account');
    return Text(
      text,
      key: const Key('bankUnderSaveLine'),
      textAlign: TextAlign.center,
      style: AppStyle.interRegular(
        size: 11,
        color: AppStyle.textDarkSecondary,
      ),
    );
  }

  Widget _fieldLabel(String label, {required bool isRequired}) => Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppStyle.interSemi(
              size: 10.5,
              letterSpacing: 1.2,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          8.horizontalSpace,
          Text(
            AppHelpers.getTranslation(isRequired ? 'required' : 'optional'),
            style: AppStyle.interRegular(
              size: 10,
              color: AppStyle.textDarkFaint,
            ),
          ),
        ],
      );
}
