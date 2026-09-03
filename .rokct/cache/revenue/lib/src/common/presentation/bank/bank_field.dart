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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/presentation/bank/bank_grammar.dart';

/// One field of the bank-details form (design strip frames 49o and 49p).
///
/// Carries the three things the frames draw around an input and the shipped
/// text-field components do not: the required/optional tag on the label's
/// face, the inline refusal UNDER the field naming the field rather than the
/// rule (chip 1008), and the 140-character ceiling as a LIVE COUNT rather
/// than a refusal after the fact (chip 1009).
///
/// The count is drawn amber, not red, and it is a deliberate distinction:
/// `MAX_FIELD_LENGTH` is candid in its own source about being an anti-bloat
/// guard rather than a banking rule (`payout.py:57-59`), so a driver at the
/// limit is at the limit, not in error — and what he has typed will save.
class BankFormField extends StatelessWidget {
  const BankFormField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.isRequired,
    this.problemKey,
    this.helperKey,
    this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final bool isRequired;

  /// Translation key of the inline refusal, or null when the field is fine.
  final String? problemKey;

  /// Translation key of a standing note under the field — the honesty line
  /// under the account number is the only one that uses it.
  final String? helperKey;

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final problem = problemKey;
    final atLimit = controller.text.trim().length >= kMaxBankFieldLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        6.verticalSpace,
        TextField(
          key: fieldKey,
          controller: controller,
          onChanged: onChanged,
          // HARD STOP at the ceiling, which is frame 49p's drawn
          // recommendation: letting him type past 140 and refusing
          // afterwards spends his effort to teach him a bloat guard.
          //
          // NOTE what is deliberately NOT here: no digits-only filter and no
          // length floor on the account number. Nothing server-side checks
          // the shape of that value, and a formatter here would be a check
          // the backend has not written.
          maxLength: kMaxBankFieldLength,
          inputFormatters: [
            LengthLimitingTextInputFormatter(kMaxBankFieldLength),
          ],
          buildCounter: (
            _, {
            required int currentLength,
            required bool isFocused,
            required int? maxLength,
          }) =>
              null,
          style: AppStyle.interNoSemi(size: 15, color: AppStyle.textPrimary),
          cursorColor: AppStyle.primary,
          cursorWidth: 1,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: problem != null ? AppStyle.red : AppStyle.strokeDark,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: problem != null ? AppStyle.red : AppStyle.primary,
              ),
            ),
          ),
        ),
        if (problem != null) ...[
          6.verticalSpace,
          Text(
            AppHelpers.getTranslation(problem),
            key: Key('${fieldKey.toString()}_problem'),
            style: AppStyle.interRegular(size: 11.5, color: AppStyle.red),
          ),
        ],
        if (atLimit) ...[
          6.verticalSpace,
          Text(
            '$kMaxBankFieldLength / $kMaxBankFieldLength — '
            '${AppHelpers.getTranslation('thats_as_much_as_we_can_keep')}',
            key: Key('${fieldKey.toString()}_count'),
            style: AppStyle.interRegular(size: 11, color: AppStyle.primary),
          ),
        ],
        if (helperKey != null) ...[
          6.verticalSpace,
          Text(
            AppHelpers.getTranslation(helperKey!),
            key: Key('${fieldKey.toString()}_helper'),
            style: AppStyle.interRegular(
              size: 11,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
