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

// GATE 3 of design strip section 45 — the deliveryman's cash step
// (frame 45d; chips 844, 845, 846, canonical 390).
//
// THE FLAG THIS CLOSES, stamped on the frame as flag (d): what shipped
// here was a WHITE dialog with the OS KEYBOARD — `AppStyle.white`,
// `AppStyle.black` buttons and an `UnderlinedBorderTextField` on
// `TextInputType.numberWithOptions(decimal: true)`. It was the LAST
// money-entry surface in the fleet not on chip 390, and it is the one
// screen where a driver is one-handed in the sun. Ray's standing rule
// is that the keypad is the money-entry surface wherever amounts are
// typed. Adopting 390 here is the real win of the gate; the calc step
// rides along.
//
// The real flow is unchanged around it: I delivered the order ->
// proof-of-delivery photo -> fetchCanConvertCodToCredit() -> THIS ->
// _finishDelivery. Both actions are the shipped ones, and the amount
// still goes to the server exactly as it did:
// `confirmCodCollection` -> confirm_cod_collection {order_id,
// amount_received}, and, only while the driver's
// `can_convert_cod_to_credit` capability is on, `convertCodToCredit` ->
// convert_cod_to_credit.
//
// The sheet OWNS NO TRUTH. The server stays the authority on the
// expected amount (the shipped comment on the dialog says so); the
// delta line (chip 846) is DERIVED, in the widget, from the
// `order.totalPrice` already on the sheet minus what has been typed. It
// names the difference before the driver commits it — it does not
// decide anything.

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keypad/money_keypad.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// CHIP 844 — the cash-collection sheet, redrawn.
///
/// A dark bottom sheet in the fleet language: drag handle, order header,
/// the shipped Cash-to-collect card, the amount question, then
/// [MoneyKeypad] (chip 390, adopted UNCHANGED — that adoption is the
/// point of the frame) in place of the OS-keyboard text field, and
/// finally the two shipped actions.
class CashCollectionSheet extends StatefulWidget {
  const CashCollectionSheet({
    super.key,
    required this.orderId,
    required this.expected,
    required this.canConvertToCredit,
    required this.onConfirm,
    required this.onRecordAsCredit,
    this.customerName,
  });

  /// Shown in the header — the order being handed over.
  final String? orderId;

  /// The order total the SERVER expects. Read-only here.
  final num expected;

  /// The driver's `can_convert_cod_to_credit` capability, already
  /// resolved by the caller.
  final bool canConvertToCredit;

  /// Confirm: hands back the amount actually received.
  final void Function(double amountReceived) onConfirm;

  /// Record as credit: goods left, customer owes the shop.
  final VoidCallback onRecordAsCredit;

  final String? customerName;

  /// The route a caller opens for the "Count it" step (chip 845).
  ///
  /// Navigation is BY ROUTE PATH, so this SDK never imports calc_sdk
  /// (ADR-005). `pick=true` asks the calculator for its number back; a
  /// composition running a calc_sdk older than 1.1.0 simply pops null
  /// and the driver keeps typing on the pad.
  static const String calcPickRoute = '/calc?pick=true';

  @override
  State<CashCollectionSheet> createState() => _CashCollectionSheetState();
}

class _CashCollectionSheetState extends State<CashCollectionSheet> {
  /// The keypad entry. Seeded with the expected total, exactly as the
  /// shipped dialog prefilled its text field.
  late String _entry = widget.expected.toString();

  double get _received => double.tryParse(_entry) ?? 0;

  /// Chip 846's number: what is typed, minus what the server expects.
  /// Negative is short.
  double get _delta => _received - widget.expected.toDouble();

  bool get _valid => double.tryParse(_entry) != null && _received >= 0;

  void _digit(String d) => setState(() {
        _entry = MoneyEntry.appendDigit(_entry, d);
      });

  void _backspace() => setState(() {
        _entry = MoneyEntry.backspace(_entry);
      });

  void _decimal() => setState(() {
        _entry = MoneyEntry.decimal(_entry);
      });

  /// CHIP 845 — the "Count it" calc step.
  ///
  /// Opened from the moment the driver is physically counting notes:
  /// 440 = 200 + 100 + 100 + 20 + 20 is exactly what a tape is for. The
  /// calculator hands its display back and it lands in the entry —
  /// nothing else on the sheet moves, and nothing is sent.
  Future<void> _countIt() async {
    final picked = await context.router.pushNamed(
      CashCollectionSheet.calcPickRoute,
    );
    if (!mounted) return;
    if (picked is String && double.tryParse(picked) != null) {
      setState(() => _entry = picked);
    }
  }

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
            _header(),
            14.verticalSpace,
            _cashToCollectCard(),
            18.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.howMuchCashReceived),
              style: AppStyle.interSemi(size: 16),
            ),
            10.verticalSpace,
            _amountRow(),
            8.verticalSpace,
            _deltaLine(),
            16.verticalSpace,
            // CHIP 390 — the fleet keypad, adopted unchanged. No OK key:
            // the sheet's own Confirm is the commit, so the pad stays a
            // pure input surface (its published contract).
            MoneyKeypad(
              onDigit: _digit,
              onBackspace: _backspace,
              onDecimal: _decimal,
            ),
            18.verticalSpace,
            CustomButton(
              title: AppHelpers.getTranslation(TrKeys.confirmation),
              background: AppStyle.primary,
              textColor: AppStyle.blackColor,
              onPressed: _valid ? () => widget.onConfirm(_received) : () {},
            ),
            if (widget.canConvertToCredit) ...[
              10.verticalSpace,
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.recordAsCredit),
                background: AppStyle.transparent,
                borderColor: AppStyle.strokeDark,
                textColor: AppStyle.textPrimary,
                onPressed: widget.onRecordAsCredit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final name = widget.customerName;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Deliberately word-free: the numeral is the order, and
                // base_sdk's only order key is the plural 'orders'.
                '#${widget.orderId ?? ''}',
                style: AppStyle.interSemi(size: 15),
              ),
              if (name != null && name.isNotEmpty) ...[
                2.verticalSpace,
                Text(
                  name,
                  style: AppStyle.interRegular(
                    size: 13,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The shipped Cash-to-collect card, on dark tokens.
  Widget _cashToCollectCard() {
    return Container(
      key: const Key('cashToCollectCard'),
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppStyle.primary),
      ),
      child: Text(
        '${AppHelpers.getTranslation(TrKeys.cashToCollect)}: '
        '${AppHelpers.numberFormat(number: widget.expected)}',
        textAlign: TextAlign.center,
        style: AppStyle.interBold(size: 16, color: AppStyle.primary),
      ),
    );
  }

  Widget _amountRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          // The amount READ-OUT: not a text field, so the OS keyboard
          // can never appear behind our pad (the 11y ruling).
          child: Container(
            key: const Key('cashAmountReadout'),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              _entry.isEmpty ? '0' : _entry,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interSemi(
                size: 30,
                color: _entry.isEmpty
                    ? AppStyle.textDarkFaint
                    : AppStyle.textPrimary,
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        _countItChip(),
      ],
    );
  }

  /// CHIP 845 — small, primary-tinted, sized for one hand, sitting
  /// beside the read-out rather than in a header or a FAB: the same
  /// idiom as the till's calc chip (843).
  Widget _countItChip() {
    return GestureDetector(
      key: const Key('cashCountIt'),
      behavior: HitTestBehavior.opaque,
      onTap: _countIt,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppStyle.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppStyle.primary.withValues(alpha: .45)),
        ),
        child: Text(
          AppHelpers.getTranslation(TrKeys.countIt),
          style: AppStyle.interSemi(size: 13, color: AppStyle.primary),
        ),
      ),
    );
  }

  /// CHIP 846 — the amount delta line.
  ///
  /// Red-washed while the count is SHORT, green once it is exact or
  /// over. Derived only; the server is still the authority on what was
  /// expected.
  Widget _deltaLine() {
    final short = _delta < 0;
    final exact = _delta == 0;
    final Color ink = short ? AppStyle.red : AppStyle.green;
    final String text;
    if (exact) {
      text = AppHelpers.getTranslation(TrKeys.amountMatchesExpected);
    } else {
      final gap = AppHelpers.numberFormat(number: _delta.abs());
      final expected = AppHelpers.numberFormat(number: widget.expected);
      final word = AppHelpers.getTranslation(
        short ? TrKeys.shortOf : TrKeys.overExpected,
      );
      text = '$gap $word $expected';
    }
    return Container(
      key: const Key('cashDeltaLine'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        text,
        style: AppStyle.interNormal(size: 13, color: ink),
      ),
    );
  }
}
