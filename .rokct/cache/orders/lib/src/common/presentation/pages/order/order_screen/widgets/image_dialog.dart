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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ImageDialog extends StatelessWidget {
  final String? img;

  const ImageDialog({super.key, this.img});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                AppHelpers.getTranslation(TrKeys.thisImageWasUploadDriver),
                style: AppStyle.interNormal(),
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
        CustomNetworkImage(url: img, radius: 16),
      ],
    );
  }
}
