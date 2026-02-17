import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';

import '../../../styles/style.dart';

class CancelDialog extends StatelessWidget {
  final String? note;

  const CancelDialog({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width / 2,
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Style.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.statusNote),
            style: Style.interNormal(),
          ),
          16.verticalSpace,
          Text(note ?? '', style: Style.interRegular()),
          16.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.telAdmin),
            textColor: Style.white,
            onPressed: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: AppHelpers.getAppPhone(),
              );
              await launchUrl(launchUri);
            },
            icon: Icon(FlutterRemix.phone_line, color: Style.white, size: 20.r),
          ),
        ],
      ),
    );
  }
}
