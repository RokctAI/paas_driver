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

/// CashSend/eWallet-style send flow. There is deliberately NO user search
/// here (anti-enumeration): the sender either types the friend's full
/// registered phone number, or enters a 6-digit code the receiver handed
/// them out-of-band.
enum _SendMode { phone, code }

class WalletSendScreen extends ConsumerStatefulWidget {
  const WalletSendScreen({super.key});

  @override
  ConsumerState<WalletSendScreen> createState() => _WalletSendScreenState();
}

class _WalletSendScreenState extends ConsumerState<WalletSendScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();

  _SendMode _mode = _SendMode.phone;
  bool _isLoading = false;

  /// Set once the backend has confirmed who the phone number belongs to.
  String? _confirmedRecipientName;

  /// Set after a successful send-by-code; holds recipient name + amount.
  String? _codeSentRecipientName;
  double? _codeSentAmount;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  bool _isPlausiblePhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?\d{9,15}$').hasMatch(normalized);
  }

  String _normalizedPhone() =>
      _phoneController.text.replaceAll(RegExp(r'[\s\-()]'), '');

  Future<void> _confirmRecipient() async {
    final phone = _normalizedPhone();
    if (!_isPlausiblePhone(phone)) {
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        AppHelpers.getTranslation(TrKeys.phoneNumberIsNotValid),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await walletRepository.confirmRecipient(phone: phone);

      setState(() {
        _isLoading = false;
      });

      result.when(
        success: (data) {
          if (!mounted) return;
          final name = data.fullName ??
              '${data.firstName ?? ''} ${data.lastName ?? ''}'.trim();
          setState(() {
            _confirmedRecipientName = name;
          });
        },
        failure: (error, statusCode) {
          if (!mounted) return;
          // Backend supplies the friendly not-found / rate-limit message.
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
        'Failed to confirm recipient',
      );
    }
  }

  Future<void> _sendToPhone() async {
    if (_confirmedRecipientName == null) return;

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
      final result = await walletRepository.sendWalletToPhone(
        phone: _normalizedPhone(),
        amount: amount,
      );

      setState(() {
        _isLoading = false;
      });

      result.when(
        success: (data) {
          if (!mounted) return;
          AppHelpers.showCheckTopSnackBarDone(
            context,
            AppHelpers.getTranslation(TrKeys.moneySentSuccessfully),
          );
          _navigateBack();
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
      AppHelpers.showCheckTopSnackBarInfo(context, 'Failed to send money');
    }
  }

  Future<void> _sendByCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        AppHelpers.getTranslation('enter_valid_six_digit_code'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // The amount is fixed by the receiver's claim; only the code is sent.
      final result = await walletRepository.sendWalletByCode(code: code);

      setState(() {
        _isLoading = false;
      });

      result.when(
        success: (data) {
          if (!mounted) return;
          setState(() {
            _codeSentRecipientName = data.recipientName ?? '';
            _codeSentAmount = data.amount;
          });
        },
        failure: (error, statusCode) {
          if (!mounted) return;
          // Backend supplies the invalid / expired / already-used message.
          AppHelpers.showCheckTopSnackBarInfo(context, error);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppHelpers.showCheckTopSnackBarInfo(context, 'Failed to send money');
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
          height: MediaQuery.of(context).size.height * 0.7,
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
                    title: AppHelpers.getTranslation(TrKeys.sendMoney),
                    paddingHorizontalSize: 0,
                    titleSize: 18,
                  ),
                  24.verticalSpace,
                  if (_codeSentRecipientName == null) ...[
                    _buildModeToggle(),
                    24.verticalSpace,
                  ],
                  if (_codeSentRecipientName != null)
                    _buildCodeSendSuccess()
                  else if (_mode == _SendMode.phone)
                    _buildPhoneFlow()
                  else
                    _buildCodeFlow(),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppStyle.borderColor),
      ),
      child: Row(
        children: [
          _buildModeButton(
            title: AppHelpers.getTranslation(TrKeys.phoneNumber),
            mode: _SendMode.phone,
          ),
          _buildModeButton(
            title: AppHelpers.getTranslation('code_from_friend'),
            mode: _SendMode.code,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({required String title, required _SendMode mode}) {
    final bool selected = _mode == mode;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: _isLoading
            ? null
            : () {
                setState(() {
                  _mode = mode;
                });
              },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? AppStyle.primary : AppStyle.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              title,
              style: AppStyle.interSemi(
                size: 14.sp,
                color: selected ? AppStyle.white : AppStyle.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppHelpers.getTranslation('enter_friend_phone_number'),
          style: AppStyle.interSemi(size: 16.sp),
        ),
        16.verticalSpace,
        TextField(
          controller: _phoneController,
          enabled: _confirmedRecipientName == null,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: AppHelpers.getTranslation(TrKeys.phoneNumber),
            prefixIcon: const Icon(Icons.phone, color: AppStyle.textGrey),
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
        if (_confirmedRecipientName == null) ...[
          36.verticalSpace,
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmRecipient,
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
                    AppHelpers.getTranslation(TrKeys.continueText),
                    style: AppStyle.interSemi(
                      size: 16.sp,
                      color: AppStyle.white,
                    ),
                  ),
          ),
        ] else ...[
          16.verticalSpace,
          _buildConfirmedRecipient(),
          24.verticalSpace,
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
              prefixIconConstraints: BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
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
          36.verticalSpace,
          ElevatedButton(
            onPressed: _isLoading ? null : _sendToPhone,
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
                    AppHelpers.getTranslation(TrKeys.sendNow),
                    style: AppStyle.interSemi(
                      size: 16.sp,
                      color: AppStyle.white,
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmedRecipient() {
    final name = _confirmedRecipientName ?? '';
    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppStyle.primary.withOpacity(0.1),
            radius: 20.r,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '',
              style: AppStyle.interBold(color: AppStyle.primary),
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppHelpers.getTranslation('send_to')} $name?',
                  style: AppStyle.interSemi(size: 16.sp),
                ),
                4.verticalSpace,
                Text(
                  _phoneController.text,
                  style: AppStyle.interNormal(
                    size: 14.sp,
                    color: AppStyle.textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppStyle.red),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _confirmedRecipientName = null;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCodeFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppHelpers.getTranslation('enter_code_from_friend'),
          style: AppStyle.interSemi(size: 16.sp),
        ),
        8.verticalSpace,
        Text(
          AppHelpers.getTranslation('amount_is_set_by_the_code'),
          style: AppStyle.interNormal(size: 13.sp, color: AppStyle.textGrey),
        ),
        16.verticalSpace,
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: AppStyle.interBold(size: 24.sp, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
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
        36.verticalSpace,
        ElevatedButton(
          onPressed: _isLoading ? null : _sendByCode,
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
                  AppHelpers.getTranslation(TrKeys.sendNow),
                  style: AppStyle.interSemi(
                    size: 16.sp,
                    color: AppStyle.white,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCodeSendSuccess() {
    final amountText = _codeSentAmount != null
        ? 'R ${_codeSentAmount!.toStringAsFixed(2)}'
        : '';
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
              Icon(
                Icons.check_circle,
                color: AppStyle.primary,
                size: 48.r,
              ),
              16.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.moneySentSuccessfully),
                style: AppStyle.interSemi(size: 16.sp),
                textAlign: TextAlign.center,
              ),
              8.verticalSpace,
              Text(
                '$amountText — ${_codeSentRecipientName ?? ''}',
                style: AppStyle.interBold(size: 18.sp),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        36.verticalSpace,
        ElevatedButton(
          onPressed: _navigateBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyle.primary,
            minimumSize: Size(double.infinity, 50.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            AppHelpers.getTranslation(TrKeys.done),
            style: AppStyle.interSemi(size: 16.sp, color: AppStyle.white),
          ),
        ),
      ],
    );
  }
}
