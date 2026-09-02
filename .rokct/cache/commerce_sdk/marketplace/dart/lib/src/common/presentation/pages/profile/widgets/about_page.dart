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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/application/about/about_provider.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  @override
  Widget build(BuildContext context) {
    final aboutState = ref.watch(aboutProvider);

    return Scaffold(
      backgroundColor: AppStyle.bgGrey,
      body: aboutState.isLoading
          ? const Loading()
          : aboutState.value == null
              ? Column(
                  children: [
                    CommonAppBar(
                      child: Row(
                        children: [
                          Image.asset(AppAssets.pngLogo, width: 40, height: 40),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "About us",
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
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  "About us",
                                  style: AppStyle.interSemi(
                                    color: AppStyle.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (aboutState.hasValue)
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (aboutState.value!['img'] != null)
                                CustomNetworkImage(
                                  url: aboutState
                                      .value!['img'], // Pass the 'img' URL
                                  height: 200, // Adjust height as needed
                                  width: MediaQuery.of(
                                    context,
                                  ).size.width, // Use full width of the screen
                                  radius: 10, // Adjust border radius as needed
                                  fit: BoxFit.cover, // Adjust fit as needed
                                  bgColor: Colors
                                      .transparent, // Adjust background color as needed
                                ),
                              if (aboutState.value!['img'] != null)
                                SizedBox(
                                  height: 16.h,
                                ), // Add spacing between image and description
                              Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(16.r),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppStyle.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Html(
                                  data: aboutState.value?['description'] ?? '',
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: const PopButton(),
        ),
      ),
    );
  }
}
