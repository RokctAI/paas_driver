// Copyright (c) 2026 RokctAI
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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Just-in-time date-of-birth prompt for 18+ (adults only) checkout.
///
/// Shown by the order sheet's `_createOrder` when `get_calculate` answered
/// `contains_adult_items && requires_birth_date` — mirroring the phone-gate
/// precedent right above it. The picked date is written to the profile via
/// the universal platform gateway (`api.user.update_user_profile`, key
/// `birth_date`, "YYYY-MM-DD"); the backend validates and normalizes it and
/// `create_order` stays the enforcement point (AGE_VERIFICATION_REQUIRED /
/// UNDERAGE_PURCHASE_BLOCKED).
///
/// New translation keys are referenced by wire-key string (not TrKeys
/// constants) because lib/ analyzes against raw base_sdk where
/// composer-injected constants don't exist — the parcel-COD precedent
/// documented in this SDK's manifest `_comment_tr_keys`.
class AgeVerifyModal extends StatefulWidget {
  const AgeVerifyModal({super.key, required this.onVerified});

  /// Called after the birth date is saved server-side (sheet already
  /// popped), so the caller can re-run calculate + order creation.
  final VoidCallback onVerified;

  @override
  State<AgeVerifyModal> createState() => _AgeVerifyModalState();
}

class _AgeVerifyModalState extends State<AgeVerifyModal> {
  static const _gateway = PlatformGateway();
  DateTime? _birthDate;
  bool _isSaving = false;

  String get _formatted {
    final d = _birthDate;
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    final birthDate = _birthDate;
    if (birthDate == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await _gateway.tenant(
        'api.user.update_user_profile',
        {
          'profile_data': {'birth_date': _formatted},
        },
      );
      // Keep the cached profile in step so the local pre-checks see the
      // fresh value without a refetch.
      final user = LocalStorage.getUser();
      if (user != null) {
        await LocalStorage.setUser(user.copyWith(birthday: _formatted));
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onVerified();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.errorHandler(e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: MediaQuery.of(context).viewInsets,
      decoration: BoxDecoration(
        color: AppStyle.bgGrey.withOpacity(0.96),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      width: double.infinity,
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
              14.verticalSpace,
              TitleAndIcon(
                title: AppHelpers.getTranslation('age_verification'),
                paddingHorizontalSize: 0,
              ),
              12.verticalSpace,
              Text(
                AppHelpers.getTranslation(
                  'this_order_includes_an_adults_only_item_please_confirm_your_date_of_birth',
                ),
                style: AppStyle.interNormal(
                  size: 14.sp,
                  letterSpacing: -0.3,
                  color: AppStyle.textGrey,
                ),
              ),
              24.verticalSpace,
              InkWell(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyle.borderColor),
                    borderRadius: BorderRadius.circular(10.r),
                    color: AppStyle.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _birthDate == null
                            ? AppHelpers.getTranslation(TrKeys.dateOfBirth)
                            : _formatted,
                        style: AppStyle.interNormal(
                          size: 14.sp,
                          color: _birthDate == null
                              ? AppStyle.textGrey
                              : AppStyle.black,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18.r,
                        color: AppStyle.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
              24.verticalSpace,
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.confirmation),
                isLoading: _isSaving,
                onPressed: _birthDate == null ? () {} : _save,
              ),
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
