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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
//import '../../../../infrastructure/services/app_helpers.dart';
//import '../../../../infrastructure/services/tr_keys.dart';
import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:delivery_sdk/src/common/application/delivery/delivery_provider.dart';

class DeliveryPage extends ConsumerStatefulWidget {
  const DeliveryPage({super.key});

  @override
  ConsumerState<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends ConsumerState<DeliveryPage> {
  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
      backgroundColor: AppStyle.bgGrey,
      body: deliveryState.isLoading
          ? const Loading()
          : deliveryState.value == null
              ? Column(
                  children: [
                    CommonAppBar(
                      child: Row(
                        children: [
                          Image.asset(AppAssets.pngLogo, width: 40, height: 40),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "Looking for delivery driver jobs?",
                                style:
                                    AppStyle.interSemi(color: AppStyle.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      CommonAppBar(
                        child: Row(
                          children: [
                            Image.asset(AppAssets.pngLogo,
                                width: 40, height: 40),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  "Looking for delivery driver jobs?",
                                  style: AppStyle.interSemi(
                                    color: AppStyle.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (deliveryState.hasValue)
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(16.r),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppStyle.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Html(
                                  data:
                                      deliveryState.value?['description'] ?? '',
                                  style: {
                                    'body': Style(
                                      fontSize: FontSize(16.sp),
                                      color: AppStyle.textGrey,
                                    ),
                                    'strong':
                                        Style(fontWeight: FontWeight.bold),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Visibility(
        visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: PopButton(),
        ),
      ),
    );
  }
}
