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

// Design strip frame 49h — the bank deposit: amount, reference and the
// photograph of the slip.
//
// This is the frame for Ray's sentence — "he deposit take photo of slip it
// get to backend for approval". The three inputs are exactly what a human
// approver needs to match a slip against a bank statement and no more: how
// much, which reference, and the picture. Money entry uses the canonical
// MoneyKeypad (chip 390), owned by section 45 and adopted unchanged, as the
// cash step (845) and the withdraw sheet do. A sheet: no plane, no back
// pill.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keypad/money_keypad.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

/// Picks the slip photograph and answers its local path, or null when the
/// driver backed out. Injectable so the sheet's tests run without a camera.
typedef SlipPicker = Future<String?> Function(ImageSource source);

/// The default picker: image_picker, already a dependency of this SDK for
/// the courier's profile and vehicle photos.
Future<String?> pickSlipWithImagePicker(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1600,
  );
  return file?.path;
}

/// The bank deposit capture sheet.
///
/// Hands a validated, strictly-positive amount, the reference and the
/// local slip path back through [onSubmit]; uploading and sending are the
/// caller's job, so this widget stays free of the repository, of DI and of
/// navigation.
class BankDepositSheet extends StatefulWidget {
  const BankDepositSheet({
    super.key,
    required this.destination,
    required this.reference,
    required this.onSubmit,
    this.initialAmount,
    this.submitting = false,
    this.pickSlip = pickSlipWithImagePicker,
  });

  /// Chip 975 — where the money goes.
  final DepositDestination destination;

  /// Chip 977 — the reference, generated FOR the driver (see
  /// `suggestedReference`), shown so he can write it on the slip.
  final String reference;

  /// Commit: hands back amount, reference and the slip's local path.
  final void Function(double amount, String reference, String slipPath)
      onSubmit;

  /// Prefill — what he owes, as a suggestion; he can change it.
  final num? initialAmount;

  /// While true the commit button is inert and reads as busy, so a
  /// double-tap cannot send two requests.
  final bool submitting;

  final SlipPicker pickSlip;

  @override
  State<BankDepositSheet> createState() => _BankDepositSheetState();
}

class _BankDepositSheetState extends State<BankDepositSheet> {
  late String _entry;
  String? _slipPath;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    _entry = (initial == null || initial <= 0)
        ? ''
        : initial.toDouble().toStringAsFixed(2);
  }

  double get _amount => double.tryParse(_entry) ?? 0;
  bool get _isNumber => double.tryParse(_entry) != null;
  bool get _validAmount => _isNumber && _amount > 0;
  bool get _hasSlip => (_slipPath ?? '').isNotEmpty;
  bool get _canSubmit => _validAmount && _hasSlip && !widget.submitting;

  void _digit(String d) => setState(() {
        _entry = MoneyEntry.appendDigit(_entry, d);
      });

  void _backspace() => setState(() {
        _entry = MoneyEntry.backspace(_entry);
      });

  void _decimal() => setState(() {
        _entry = MoneyEntry.decimal(_entry);
      });

  Future<void> _pick(ImageSource source) async {
    final path = await widget.pickSlip(source);
    if (!mounted || path == null || path.isEmpty) return;
    setState(() => _slipPath = path);
  }

  /// Copy, because a driver standing at an ATM cannot retype an account
  /// number from memory. The WHOLE number is copied; the screen masks it.
  Future<void> _copy() async {
    final number = widget.destination.accountNumber ?? '';
    if (number.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: number));
    if (!mounted) return;
    AppHelpers.showCheckTopSnackBar(
      context,
      AppHelpers.getTranslation('account_number_copied'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bankDepositSheet'),
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
              AppHelpers.getTranslation('bank_deposit'),
              style: AppStyle.interSemi(size: 16),
            ),
            4.verticalSpace,
            // The one sentence that separates this route from the card.
            Text(
              AppHelpers.getTranslation(
                'nothing_moves_in_your_wallet_until_this_is_approved',
              ),
              key: const Key('bankDepositNothingMovesLine'),
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.textDarkSecondary,
              ),
            ),
            14.verticalSpace,
            _beneficiaryBlock(),
            18.verticalSpace,
            _label(AppHelpers.getTranslation(TrKeys.amount)),
            8.verticalSpace,
            _amountReadout(),
            12.verticalSpace,
            // The fleet keypad, adopted unchanged. No OK key: the sheet's
            // own commit button is the commit.
            MoneyKeypad(
              onDigit: _digit,
              onBackspace: _backspace,
              onDecimal: _decimal,
            ),
            18.verticalSpace,
            _label(AppHelpers.getTranslation('your_reference')),
            8.verticalSpace,
            _referenceBlock(),
            18.verticalSpace,
            _label(AppHelpers.getTranslation('deposit_slip')),
            8.verticalSpace,
            _slipBlock(),
            18.verticalSpace,
            CustomButton(
              key: const Key('bankDepositSubmit'),
              title: AppHelpers.getTranslation('send_for_approval'),
              background: _canSubmit ? AppStyle.primary : AppStyle.strokeDark,
              textColor:
                  _canSubmit ? AppStyle.blackColor : AppStyle.textDarkFaint,
              isLoading: widget.submitting,
              onPressed: _canSubmit
                  ? () => widget.onSubmit(_amount, widget.reference, _slipPath!)
                  : () {},
            ),
            8.verticalSpace,
            // Chip 978's line, doing the real work: the balance does not
            // move. A driver who believes the money landed will not check
            // again.
            Text(
              AppHelpers.getTranslation(
                'your_balance_stays_the_same_until_someone_approves_it',
              ),
              key: const Key('bankDepositBalanceStaysLine'),
              textAlign: TextAlign.center,
              style: AppStyle.interRegular(
                size: 11,
                color: AppStyle.textDarkFaint,
              ),
            ),
            6.verticalSpace,
            TextButton(
              key: const Key('bankDepositCancel'),
              onPressed:
                  widget.submitting ? null : () => Navigator.of(context).maybePop(),
              child: Text(
                AppHelpers.getTranslation(TrKeys.cancel),
                style: AppStyle.interSemi(
                  size: 13,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: AppStyle.interSemi(
          size: 10.5,
          letterSpacing: 1.2,
          color: AppStyle.textDarkSecondary,
        ),
      );

  /// Chip 975 — the beneficiary block, with Copy.
  Widget _beneficiaryBlock() {
    final d = widget.destination;
    return Container(
      key: const Key('bankDepositBeneficiary'),
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(AppHelpers.getTranslation('pay_into')),
                8.verticalSpace,
                Text(
                  d.accountHolderName ?? '',
                  style: AppStyle.interSemi(size: 14),
                ),
                3.verticalSpace,
                Text(
                  '${d.bankLine} · ${d.maskedAccountNumber}',
                  key: const Key('bankDepositMaskedAccount'),
                  style: AppStyle.interNoSemi(size: 12),
                ),
                if ((d.branchCode ?? '').isNotEmpty) ...[
                  3.verticalSpace,
                  Text(
                    '${AppHelpers.getTranslation('branch')} ${d.branchCode}',
                    style: AppStyle.interRegular(
                      size: 11.5,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ],
                if ((d.instructions ?? '').isNotEmpty) ...[
                  6.verticalSpace,
                  Text(
                    d.instructions!,
                    style: AppStyle.interRegular(
                      size: 11,
                      color: AppStyle.textDarkFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          8.horizontalSpace,
          TextButton.icon(
            key: const Key('bankDepositCopyAccount'),
            onPressed: _copy,
            icon: Icon(Remix.file_copy_line, size: 16.r, color: AppStyle.primary),
            label: Text(
              AppHelpers.getTranslation('copy'),
              style: AppStyle.interSemi(size: 12, color: AppStyle.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// The amount READ-OUT: not a text field, so the OS keyboard can never
  /// appear behind the pad (the same ruling as the cash step).
  Widget _amountReadout() {
    return Container(
      key: const Key('bankDepositAmountReadout'),
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

  /// Chip 977 — the reference, generated for him rather than requested.
  Widget _referenceBlock() {
    return Container(
      key: const Key('bankDepositReference'),
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.reference, style: AppStyle.interSemi(size: 16)),
          4.verticalSpace,
          Text(
            AppHelpers.getTranslation(
              'write_this_on_the_slip_the_office_matches_on_it',
            ),
            style: AppStyle.interRegular(
              size: 11,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip 976 — the slip capture. Drawn as an attached and reviewable
  /// state once taken, because the mistake to design against is a driver
  /// who thinks he photographed the slip and did not.
  Widget _slipBlock() {
    final path = _slipPath;
    return Container(
      key: const Key('bankDepositSlip'),
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: path == null ? AppStyle.strokeDark : AppStyle.primary,
        ),
      ),
      child: path == null
          ? Row(
              children: [
                Expanded(
                  child: _slipAction(
                    key: const Key('bankDepositTakePhoto'),
                    icon: Remix.camera_line,
                    label: AppHelpers.getTranslation(TrKeys.takePhoto),
                    onTap: () => _pick(ImageSource.camera),
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: _slipAction(
                    key: const Key('bankDepositChooseFromLibrary'),
                    icon: Remix.image_line,
                    label: AppHelpers.getTranslation(TrKeys.selectPhoto),
                    onTap: () => _pick(ImageSource.gallery),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(Remix.attachment_2, size: 18.r, color: AppStyle.primary),
                10.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.split('/').last,
                        key: const Key('bankDepositSlipName'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.interNoSemi(size: 12),
                      ),
                      2.verticalSpace,
                      Text(
                        AppHelpers.getTranslation('attached'),
                        style: AppStyle.interRegular(
                          size: 11,
                          color: AppStyle.green,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('bankDepositRetake'),
                  onPressed: () => _pick(ImageSource.camera),
                  child: Text(
                    AppHelpers.getTranslation('retake'),
                    style: AppStyle.interSemi(size: 12, color: AppStyle.primary),
                  ),
                ),
                TextButton(
                  key: const Key('bankDepositReplace'),
                  onPressed: () => _pick(ImageSource.gallery),
                  child: Text(
                    AppHelpers.getTranslation('replace'),
                    style: AppStyle.interSemi(size: 12, color: AppStyle.primary),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _slipAction({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppStyle.strokeDark),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20.r, color: AppStyle.primary),
              6.verticalSpace,
              Text(label, style: AppStyle.interNoSemi(size: 11.5)),
            ],
          ),
        ),
      );
}
