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
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The refusal sheet (design strip frame 49i, chip 981's source): a
/// rejection is never silent. The driver reads this reason under his row,
/// so the commit stays inert until there is one.
///
/// A reason is prose, so this is the one place on the deposit route that
/// uses the OS keyboard — chip 390 is for amounts.
class DepositRejectSheet extends StatefulWidget {
  const DepositRejectSheet({
    super.key,
    required this.driverName,
    required this.amountLine,
    required this.onSubmit,
    this.submitting = false,
  });

  final String driverName;

  /// "R 1,240.00 · TM-0831-1642" — already formatted by the caller.
  final String amountLine;

  /// Commit: hands back the trimmed, non-empty reason.
  final void Function(String reason) onSubmit;

  final bool submitting;

  @override
  State<DepositRejectSheet> createState() => _DepositRejectSheetState();
}

class _DepositRejectSheetState extends State<DepositRejectSheet> {
  final _controller = TextEditingController();

  bool get _canSubmit =>
      _controller.text.trim().isNotEmpty && !widget.submitting;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('depositRejectSheet'),
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
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            16.h,
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
            AppHelpers.getTranslation('reject_this_deposit'),
            style: AppStyle.interSemi(size: 16),
          ),
          4.verticalSpace,
          Text(
            '${widget.driverName} · ${widget.amountLine}',
            key: const Key('depositRejectSubject'),
            style: AppStyle.interRegular(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation('tell_the_driver_why').toUpperCase(),
            style: AppStyle.interSemi(
              size: 10.5,
              letterSpacing: 1.2,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          8.verticalSpace,
          TextField(
            key: const Key('depositRejectReason'),
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            maxLength: 140,
            textCapitalization: TextCapitalization.sentences,
            style: AppStyle.interRegular(size: 13, color: AppStyle.textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: AppHelpers.getTranslation(
                'for_example_the_bank_received_a_different_amount',
              ),
              hintStyle: AppStyle.interRegular(
                size: 12,
                color: AppStyle.textDarkFaint,
              ),
              counterStyle: AppStyle.interRegular(
                size: 10,
                color: AppStyle.textDarkFaint,
              ),
              filled: true,
              fillColor: AppStyle.cardDarkAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppStyle.strokeDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppStyle.strokeDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppStyle.primary),
              ),
            ),
          ),
          12.verticalSpace,
          CustomButton(
            key: const Key('depositRejectConfirm'),
            title: AppHelpers.getTranslation('reject_deposit'),
            background: _canSubmit ? AppStyle.red : AppStyle.strokeDark,
            textColor: _canSubmit ? AppStyle.white : AppStyle.textDarkFaint,
            isLoading: widget.submitting,
            onPressed: _canSubmit
                ? () => widget.onSubmit(_controller.text.trim())
                : () {},
          ),
          6.verticalSpace,
          TextButton(
            key: const Key('depositRejectCancel'),
            onPressed: widget.submitting
                ? null
                : () => Navigator.of(context).maybePop(),
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
    );
  }
}
