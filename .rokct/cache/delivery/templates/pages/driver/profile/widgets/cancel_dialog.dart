import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';



import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class CancelDialog extends StatelessWidget {
  final String? note;

  const CancelDialog({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width / 2,
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.statusNote),
            style: AppStyle.interNormal(),
          ),
          16.verticalSpace,
          Text(
            note ?? '',
            style: AppStyle.interRegular(),
          ),
          16.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.telAdmin),
            textColor: AppStyle.white,
            onPressed: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: AppHelpers.getAppPhone(),
              );
              await launchUrl(launchUri);
            },
            icon: Icon(
              FlutterRemix.phone_line,
              color: AppStyle.white,
              size: 20.r,
            ),
          ),
        ],
      ),
    );
  }
}
