import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/styles/style.dart';

import 'common_image.dart';

class ImageDialog extends StatelessWidget {
  final String? img;

  const ImageDialog({super.key, this.img});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: REdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Style.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  AppHelpers.getTranslation(TrKeys.thisImageWasUploadDriver),
                  style: Style.interNormal(),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: REdgeInsets.all(4),
                  child: const Icon(FlutterRemix.close_circle_line),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          CommonImage(imageUrl: img),
        ],
      ),
    );
  }
}
