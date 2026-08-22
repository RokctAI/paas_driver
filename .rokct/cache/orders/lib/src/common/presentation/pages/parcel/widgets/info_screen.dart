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

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

@RoutePage()
class InfoPage extends StatelessWidget {
  final int index;

  const InfoPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConstants.infoImage[index]),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppHelpers.getTranslation(AppConstants.infoTitle[index]),
                    style: AppStyle.interNoSemi(
                      size: 40,
                      color: AppStyle.white,
                    ),
                  ),
                  40.verticalSpace,
                  CustomButton(
                    title: index == 3
                        ? AppHelpers.getTranslation(TrKeys.back)
                        : AppHelpers.getTranslation(TrKeys.next),
                    onPressed: () {
                      if (index == 3) {
                        context.maybePop();
                        return;
                      }
                      AppRoutes.I.replaceInfoRoute(context, index: index + 1);
                    },
                  ),
                  32.verticalSpace,
                ],
              ),
            ),
          ),
          Positioned(
            top: 32.r,
            right: 8.r,
            child: IconButton(
              onPressed: () {
                context.maybePop();
              },
              icon: Icon(
                FlutterRemix.close_line,
                color: AppStyle.white,
                size: 32.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
