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

/// Shared vocabulary of the driver's bank-details surface (design strip
/// frames 49n-49s): the rules, the masking and the wording, with no widgets
/// in them so every one is unit-tested.
///
/// THE RULE THAT GOVERNS THIS FILE, and the one a later edit is most likely
/// to break: **the client enforces exactly the rules the backend has, and
/// not one more.** `add_bank_account` has three
/// (`pay/wallet/frappe/src/tenant/api/payout.py:176-239`):
///
///  1. the required three are non-empty after stripping — `_required_text`
///     (`:108-115`);
///  2. no text field exceeds `MAX_FIELD_LENGTH = 140` (`:59`), required and
///     optional alike (`:112-115`, `:119-121`);
///  3. an account type, when given, is one of the doctype's Select options
///     (`:61`, `:195-196`).
///
/// There is NO format validation of the account number anywhere in this
/// path — no digit rule, no length rule, no checksum — and none on the
/// branch code either. The controller is a bare `pass`
/// (`payout_bank_account.py:28-29`). Frame 49o is explicit that a masked or
/// digits-only input would be "a drawing that authorises a check nobody has
/// written", and that a driver who trusts a mask that is not enforced will
/// send his money to a typo. So this file deliberately does NOT add one.
/// If a shape rule is ever wanted, it belongs in `add_bank_account` FIRST
/// and here second — never here alone, because a client-only check is not
/// validation.
library;

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';

/// `MAX_FIELD_LENGTH` (`payout.py:59`), mirrored so the form can show a live
/// count instead of discovering the ceiling on a round trip. The source is
/// candid that it is an anti-bloat guard rather than a banking rule, which
/// is why frame 49p draws it amber — at the limit, not in error.
const int kMaxBankFieldLength = 140;

/// The doctype's `account_type` Select, verbatim and in order
/// (`payout_bank_account.json:62` -> "\nCheque\nSavings\nTransmission"),
/// enforced against the `ACCOUNT_TYPES` tuple at `payout.py:61, 195-196`.
///
/// The LEADING BLANK OPTION IS REAL: the field is optional, so "none" is a
/// legitimate choice and frame 49o draws it as one rather than omitting it.
const List<String> kBankAccountTypes = <String>['Cheque', 'Savings', 'Transmission'];

/// Which of the form's fields a refusal belongs to.
enum BankField { accountHolderName, bankName, accountNumber, branchCode }

/// The one refusal a required field can carry, as a translation key, or null
/// when the value will be accepted.
///
/// Only two outcomes exist because only two rules do: blank after stripping
/// (`_required_text` strips then throws, `payout.py:108-115`) and over the
/// 140-character ceiling. Nothing inspects the shape of the value.
String? requiredFieldProblemKey(BankField field, String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return _blankKeyFor(field);
  if (text.length > kMaxBankFieldLength) return _tooLongKeyFor(field);
  return null;
}

/// The same for an optional field: blank is fine, too long is not.
///
/// `_optional_text` (`payout.py:117-121`) accepts empty and applies the same
/// ceiling, so the branch code carries the length rule and nothing else —
/// no lookup, no format, because none exists.
String? optionalFieldProblemKey(BankField field, String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  if (text.length > kMaxBankFieldLength) return _tooLongKeyFor(field);
  return null;
}

String _blankKeyFor(BankField field) {
  switch (field) {
    case BankField.accountHolderName:
      return 'please_enter_the_account_holder_name';
    case BankField.bankName:
      return 'please_enter_the_bank';
    case BankField.accountNumber:
      return 'please_enter_the_account_number';
    case BankField.branchCode:
      return 'please_enter_the_branch_code';
  }
}

String _tooLongKeyFor(BankField field) => 'thats_longer_than_we_can_keep';

/// True when the account type is one the backend will accept. A blank is
/// accepted — the field is optional — and the chooser makes anything else
/// unreachable by construction, so this exists as a guard rather than as a
/// message the driver will ever see.
bool isAcceptableAccountType(String? value) {
  final text = (value ?? '').trim();
  return text.isEmpty || kBankAccountTypes.contains(text);
}

/// Every unfilled required field, in the order the endpoint's own signature
/// names them (`payout.py:177-184`), so the form marks them all at once.
/// Revealing one error at a time turns a form into a corridor (frame 49p).
List<BankField> missingRequiredFields({
  String? accountHolderName,
  String? bankName,
  String? accountNumber,
}) {
  final missing = <BankField>[];
  if ((accountHolderName ?? '').trim().isEmpty) {
    missing.add(BankField.accountHolderName);
  }
  if ((bankName ?? '').trim().isEmpty) missing.add(BankField.bankName);
  if ((accountNumber ?? '').trim().isEmpty) {
    missing.add(BankField.accountNumber);
  }
  return missing;
}

/// The form can succeed: every required field is filled, nothing is over the
/// ceiling, and the account type is one the backend takes.
///
/// The Save button is held inert until this is true, because an enabled
/// button over an incomplete form is a promise the endpoint will break
/// (frame 49p, chip 1010).
bool canSaveBankAccount({
  String? accountHolderName,
  String? bankName,
  String? accountNumber,
  String? branchCode,
  String? accountType,
}) =>
    requiredFieldProblemKey(
          BankField.accountHolderName,
          accountHolderName,
        ) ==
        null &&
    requiredFieldProblemKey(BankField.bankName, bankName) == null &&
    requiredFieldProblemKey(BankField.accountNumber, accountNumber) == null &&
    optionalFieldProblemKey(BankField.branchCode, branchCode) == null &&
    isAcceptableAccountType(accountType);

/// The duplicate the backend keys on: same user, same account number, same
/// bank (`payout.py:198-203`). Checked here against the list the screen
/// already holds so the driver is refused in our words before a round trip,
/// rather than being handed a translated server sentence.
///
/// Compared on the STRIPPED values, because that is what the endpoint
/// stores; case is folded on the bank name only, since an account number is
/// not a word.
bool isDuplicateAccount(
  List<BankAccountRecord> existing, {
  required String accountNumber,
  required String bankName,
}) {
  final number = accountNumber.trim();
  final bank = bankName.trim().toLowerCase();
  return existing.any(
    (row) =>
        row.accountNumber.trim() == number &&
        row.bankName.trim().toLowerCase() == bank,
  );
}

/// True while a still-`Requested` payout names this account, which is the
/// one and only thing that blocks removal (`payout.py:270-286`).
///
/// Computed from the trail the app has already read rather than by asking:
/// the refusal then appears in the row, in the driver's terms, instead of
/// as a toast carrying the server's wording (frame 49q, chip 1013).
bool isRemovalBlocked(
  String bankAccountId,
  List<PayoutRequestRecord> requests,
) =>
    requests.any(
      (request) => request.isLive && request.bankAccountId == bankAccountId,
    );

/// The account number as the driver is shown it back: the last four digits
/// behind four dots, the form frame 49q draws.
///
/// Never used on the FORM — he is typing it there and must see what he
/// typed. Only on rows he is identifying, where a full number on screen is
/// a number over his shoulder.
String maskAccountNumber(String accountNumber) {
  final text = accountNumber.trim();
  if (text.isEmpty) return '';
  if (text.length <= 4) return text;
  return '•••• ${text.substring(text.length - 4)}';
}

/// The one-line summary of an account: bank, then type when there is one.
/// Type is omitted rather than filled with a placeholder, because blank is
/// a legitimate stored value.
String accountSummary(BankAccountRecord account) {
  final type = (account.accountType ?? '').trim();
  if (type.isEmpty) return account.bankName;
  return '${account.bankName} · $type';
}

/// Which account a payout should name.
///
/// Mirrors `_default_account` (`payout.py:137-157`) EXACTLY, including the
/// part that looks like an oversight and is not: the fallback to an unmarked
/// account applies only when there is exactly one. With two unmarked rows the
/// server returns None and refuses the payout — so this answers null in the
/// same case rather than picking one and being refused for a reason the
/// driver could not see.
BankAccountRecord? defaultAccount(List<BankAccountRecord> accounts) {
  for (final account in accounts) {
    if (account.isDefault) return account;
  }
  if (accounts.length == 1) return accounts.first;
  return null;
}
