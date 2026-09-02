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
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';

import 'package:base_sdk/src/models/data/typed_extra.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ImageExtras extends StatelessWidget {
  final int groupIndex;
  final List<UiExtra> uiExtras;
  final Function(UiExtra) onUpdate;
  final Function(String) updateImage;

  const ImageExtras({
    super.key,
    required this.groupIndex,
    required this.uiExtras,
    required this.onUpdate,
    required this.updateImage,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.r,
      runSpacing: 10.r,
      children: uiExtras
          .map(
            (uiExtra) => Material(
              borderRadius: BorderRadius.circular(21.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(21.r),
                onTap: () {
                  updateImage(uiExtra.value);
                  if (uiExtra.isSelected) {
                    return;
                  }
                  onUpdate(uiExtra);
                },
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21.r),
                  ),
                  child: Stack(
                    children: [
                      CustomNetworkImage(
                        url: uiExtra.value,
                        width: 42.r,
                        height: 42.r,
                        radius: 20.r,
                      ),
                      if (uiExtra.isSelected)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 22.r,
                            height: 22.r,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11.r),
                              color: AppStyle.primary,
                              border: Border.all(
                                color: AppStyle.white,
                                width: 8.r,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
