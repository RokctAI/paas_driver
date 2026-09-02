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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

/// CashSend/eWallet-style receive flow: the receiver picks an amount, the
/// backend mints a single-use 6-digit claim code, and the receiver hands the
/// code to the sender out-of-band (codes are never pushed or SMSed).
class WalletReceiveScreen extends ConsumerStatefulWidget {
  const WalletReceiveScreen({super.key});

  @override
  ConsumerState<WalletReceiveScreen> createState() =>
      _WalletReceiveScreenState();
}

class _WalletReceiveScreenState extends ConsumerState<WalletReceiveScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  /// Active claim, set after a successful generateReceiveClaim call.
  String? _claimCode;
  double? _claimAmount;

  // Predefined amount options for quick selection (mirrors the top-up sheet).
  final List<double> _amountOptions = [50, 100, 200, 500, 1500, 2000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        AppHelpers.getTranslation(TrKeys.pleaseEnterValidAmount),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await walletRepository.generateReceiveClaim(
        amount: amount,
      );

      setState(() {
        _isLoading = false;
      });

      result.when(
        success: (data) {
          if (!mounted) return;
          setState(() {
            _claimCode = data.code ?? '';
            _claimAmount = data.amount ?? amount;
          });
        },
        failure: (error, statusCode) {
          if (!mounted) return;
          AppHelpers.showCheckTopSnackBarInfo(context, error);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        'Failed to generate code',
      );
    }
  }

  Future<void> _cancelCode({bool regenerate = false}) async {
    final code = _claimCode;
    if (code == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await walletRepository.cancelReceiveClaim(code: code);

      setState(() {
        _isLoading = false;
      });

      bool cancelled = false;
      result.when(
        success: (data) {
          cancelled = true;
        },
        failure: (error, statusCode) {
          if (!mounted) return;
          AppHelpers.showCheckTopSnackBarInfo(context, error);
        },
      );

      if (cancelled && mounted) {
        setState(() {
          _claimCode = null;
          _claimAmount = null;
        });
        if (regenerate) {
          await _generateCode();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppHelpers.showCheckTopSnackBarInfo(context, 'Failed to cancel code');
    }
  }

  Future<void> _copyCode() async {
    final code = _claimCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      AppHelpers.showCheckTopSnackBarDone(
        context,
        AppHelpers.getTranslation(TrKeys.copyCode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();

    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Container(
          decoration: BoxDecoration(
            color: AppStyle.bgGrey.withOpacity(0.96),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.verticalSpace,
                  Center(
                    child: Container(
                      height: 4.h,
                      width: 48.w,
                      decoration: BoxDecoration(
                        color: AppStyle.dragElement,
                        borderRadius: BorderRadius.all(Radius.circular(40.r)),
                      ),
                    ),
                  ),
                  24.verticalSpace,
                  TitleAndIcon(
                    title: AppHelpers.getTranslation('receive_from_a_friend'),
                    paddingHorizontalSize: 0,
                    titleSize: 18,
                  ),
                  24.verticalSpace,
                  if (_claimCode == null)
                    _buildAmountForm()
                  else
                    _buildActiveClaim(),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.enterAmount),
          style: AppStyle.interSemi(size: 16.sp),
        ),
        16.verticalSpace,
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text('R', style: AppStyle.interBold(size: 18.sp)),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppStyle.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppStyle.primary),
            ),
          ),
        ),
        24.verticalSpace,
        Text(
          AppHelpers.getTranslation(TrKeys.quickAmount),
          style: AppStyle.interSemi(size: 16.sp),
        ),
        16.verticalSpace,
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _amountOptions.map((amount) {
            return InkWell(
              onTap: () {
                setState(() {
                  _amountController.text = amount.toString();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: AppStyle.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppStyle.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyle.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'R ${amount.toStringAsFixed(2)}',
                  style: AppStyle.interNormal(size: 14.sp),
                ),
              ),
            );
          }).toList(),
        ),
        36.verticalSpace,
        ElevatedButton(
          onPressed: _isLoading ? null : _generateCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.primary,
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _isLoading
              ? CircularProgressIndicator(color: AppStyle.white)
              : Text(
                  AppHelpers.getTranslation('generate_code'),
                  style: AppStyle.interSemi(
                    size: 16.sp,
                    color: AppStyle.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActiveClaim() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: AppStyle.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'R ${(_claimAmount ?? 0).toStringAsFixed(2)}',
                style: AppStyle.interSemi(size: 18.sp),
                textAlign: TextAlign.center,
              ),
              16.verticalSpace,
              SelectableText(
                _claimCode ?? '',
                style: AppStyle.interBold(size: 40.sp, letterSpacing: 8),
                textAlign: TextAlign.center,
              ),
              16.verticalSpace,
              Text(
                AppHelpers.getTranslation('code_valid_for_24_hours'),
                style: AppStyle.interNormal(
                  size: 13.sp,
                  color: AppStyle.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
              Text(
                AppHelpers.getTranslation('hand_this_code_to_the_sender'),
                style: AppStyle.interNormal(
                  size: 13.sp,
                  color: AppStyle.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        24.verticalSpace,
        ElevatedButton(
          onPressed: _isLoading ? null : _copyCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.primary,
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            AppHelpers.getTranslation(TrKeys.copyCode),
            style: AppStyle.interSemi(size: 16.sp, color: AppStyle.white),
          ),
        ),
        16.verticalSpace,
        ElevatedButton(
          onPressed: _isLoading ? null : () => _cancelCode(regenerate: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.transparent,
            foregroundColor: AppStyle.primary,
            minimumSize: Size(double.infinity, 50.h),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
              side: BorderSide(color: AppStyle.primary),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: CircularProgressIndicator(
                    color: AppStyle.primary,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  AppHelpers.getTranslation('generate_new_code'),
                  style: AppStyle.interSemi(
                    size: 16.sp,
                    color: AppStyle.primary,
                  ),
                ),
        ),
        16.verticalSpace,
        TextButton(
          onPressed: _isLoading ? null : () => _cancelCode(),
          child: Text(
            AppHelpers.getTranslation('cancel_code'),
            style: AppStyle.interSemi(size: 16.sp, color: AppStyle.red),
          ),
        ),
      ],
    );
  }
}
