import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class CheckStatusDialog extends StatelessWidget {
  final VoidCallback cancel;
  final VoidCallback onTap;

  const CheckStatusDialog({
    super.key,
    required this.cancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 60.w),
      decoration: BoxDecoration(
        color: AppStyle.cardDark.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: AppStyle.cardDark.withOpacity(0.65),
            spreadRadius: 0,
            blurRadius: 60,
            offset: const Offset(0, 20), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          15.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.groupOrderProgress),
            style: AppStyle.interNormal(size: 14, color: AppStyle.textPrimary),
            textAlign: TextAlign.center,
          ),
          36.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.cancel),
                  onPressed: cancel,
                  background: AppStyle.transparent,
                  textColor: AppStyle.textPrimary,
                  borderColor: AppStyle.borderColor,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.continueText),
                  onPressed: onTap,
                  background: AppStyle.red,
                  textColor: AppStyle.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
