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
