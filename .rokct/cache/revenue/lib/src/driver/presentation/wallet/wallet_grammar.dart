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

/// Shared vocabulary of the driver's money planes (design strip frames 49f
/// and 49k): the arithmetic and the wording rules, with no widgets in them
/// so every one of them is unit-tested.
///
/// Two standing rules live here rather than in a build method:
///
///  * **The balance is a sentence, not a signed number** (section 49 ruling
///    11). A driver in debt reads "You owe R 1,240.00" — never "−1,240".
///    Going negative is DELIBERATE and normal: he keeps the physical cash he
///    collects and his ledger carries the debt
///    (`commerce/orders/.../settlement.py:48-52`,
///    `zones/delivery/.../driver_parcel.py:172-175`,
///    `zones/map/.../driver_order.py:745-748` all say so in the same words).
///    It is a fact to state plainly, never an error to dress up.
///  * **A rejected or cancelled payout has already been credited back.**
///    Both run the hold through `_release_hold`
///    (`wallet_payout_request.py:118-150`) latched by `hold_released`, so it
///    happens at most once. That is the fact the driver needs, and the only
///    one this app can state.
library;

import 'dart:ui';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';

/// Which sentence the balance head speaks.
enum BalanceTone {
  /// Below zero — he owes the platform. Stated, not flagged.
  owing,

  /// Exactly zero.
  empty,

  /// Above zero — there is something to withdraw.
  available,
}

BalanceTone toneFor(num balance) {
  if (balance < 0) return BalanceTone.owing;
  if (balance == 0) return BalanceTone.empty;
  return BalanceTone.available;
}

/// The translation key of the line that leads the balance figure. Chosen so
/// that a backend with no row seeded for it still humanizes to the approved
/// English (`AppHelpers.humanizeTrKey`).
String balanceLeadKey(BalanceTone tone) {
  switch (tone) {
    case BalanceTone.owing:
      return 'you_owe';
    case BalanceTone.empty:
      return 'your_balance_is_empty';
    case BalanceTone.available:
      return 'available_to_withdraw';
  }
}

/// Why the Withdraw action is inert, in the driver's words. Null when it is
/// live. The owing line is frame 49f's own wording.
String? withdrawBlockedKey(num balance) {
  switch (toneFor(balance)) {
    case BalanceTone.owing:
      return 'withdraw_is_unavailable_while_you_owe_money';
    case BalanceTone.empty:
      return 'you_have_nothing_to_withdraw_yet';
    case BalanceTone.available:
      return null;
  }
}

/// The Withdraw action is live only on a strictly positive balance — the
/// same rule the income page already applies, so the two screens can never
/// disagree about whether the button works.
bool canWithdraw(num balance) => balance > 0;

/// Last four digits behind bullets: `•••• 8823`.
///
/// The app's manners, not protection — `account_number` is a plain `Data`
/// field with no masking or encryption at rest
/// (`payout_bank_account.json:47-52`). A number too short to mask is shown
/// whole rather than invented around.
String maskAccountNumber(String? number) {
  final digits = (number ?? '').trim();
  if (digits.isEmpty) return '';
  if (digits.length <= 4) return digits;
  return '•••• ${digits.substring(digits.length - 4)}';
}

/// The money that has LEFT the wallet and is waiting on a person.
///
/// `request_payout` debits at request time (`payout.py:345`) before the row
/// is inserted (`:349-368`), so every still-`Requested` row is money already
/// gone from the balance. This sum is what the "…is out on a payout request"
/// line reports, and it is why a driver whose balance reads zero has not
/// been robbed.
num outstandingPayoutTotal(Iterable<PayoutRequestRecord> requests) {
  num total = 0;
  for (final request in requests) {
    if (request.isLive) total += request.amount;
  }
  return total;
}

/// The newest still-live request, or null — the one the status trail draws.
/// The endpoint already answers newest-first, but the first live row is
/// found explicitly rather than assumed to be row zero.
PayoutRequestRecord? liveRequest(Iterable<PayoutRequestRecord> requests) {
  for (final request in requests) {
    if (request.isLive) return request;
  }
  return null;
}

/// A payout status as the row chip renders it: the translation key of its
/// label and the colour it carries.
class PayoutStatusView {
  const PayoutStatusView(this.labelKey, this.color);

  final String labelKey;
  final Color color;

  /// The chip's fill: the status colour laid faintly over the surface, so
  /// it follows the theme instead of pinning a dark-only hex.
  Color get background =>
      Color.lerp(AppStyle.surfaceDark, color, 0.20) ?? color;
}

PayoutStatusView statusView(PayoutStatus status) {
  switch (status) {
    case PayoutStatus.requested:
      return const PayoutStatusView('requested', AppStyle.rate);
    case PayoutStatus.paid:
      return const PayoutStatusView('paid', AppStyle.green);
    case PayoutStatus.rejected:
      return const PayoutStatusView('rejected', AppStyle.red);
    case PayoutStatus.cancelled:
      return PayoutStatusView('cancelled', AppStyle.textDarkSecondary);
    case PayoutStatus.unknown:
      return PayoutStatusView('', AppStyle.textDarkSecondary);
  }
}

/// How a movement row dates itself.
enum MovementDay { today, yesterday, earlier }

MovementDay classifyDay(DateTime at, DateTime now) {
  final day = DateTime(at.year, at.month, at.day);
  final todayStart = DateTime(now.year, now.month, now.day);
  final difference = todayStart.difference(day).inDays;
  if (difference <= 0) return MovementDay.today;
  if (difference == 1) return MovementDay.yesterday;
  return MovementDay.earlier;
}

/// The row's own sentence, when the ledger recorded one.
///
/// Every writer fills `Wallet History.description` in ("Cash collected from
/// customer of Order …", "Delivery fee for Order …") and it is what frame
/// 49f draws. `get_wallet_history` does NOT select that column today
/// (Users `users/frappe/src/tenant/api/user/user.py:1311-1315`), so this is
/// null in production right now and the row falls back to [movementTypeKey].
String? movementDescription(WalletMovement movement) {
  final description = movement.description?.trim();
  return (description == null || description.isEmpty) ? null : description;
}

/// The translation key for a row with no sentence of its own.
///
/// Deliberately COARSE. `Topup` and `Withdraw` each carry two different
/// real-world events — a genuine top-up and a delivery-fee credit share
/// `Topup`; a commission bill and a manual debit share `Withdraw`
/// (`settlement.py:425-478`) — so they are labelled by what the ledger can
/// actually prove, money in and money out, and NOT by a narrative that
/// would be wrong half the time. An unmapped type falls through to its own
/// server wording rather than being guessed at.
String movementTypeKey(WalletMovement movement) {
  switch (movement.type?.trim()) {
    case 'Topup':
      return 'wallet_credit';
    case 'Withdraw':
      return 'wallet_debit';
    case 'Payout':
      return 'payout_to_your_bank';
    case 'COD Collection':
      return 'cash_collected';
    case 'COD Settlement':
      return 'cash_settled';
    case 'Payment':
      return 'payment';
    case 'Refund':
      return 'refund';
    case 'Referral':
      return 'referral';
    case 'Loan Disbursement':
      return 'loan_disbursement';
    case 'Loan Repayment':
      return 'loan_repayment';
    default:
      return movement.type?.trim() ?? '';
  }
}
