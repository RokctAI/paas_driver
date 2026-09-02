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
//import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
//import '../../../../infrastructure/services/app_helpers.dart';
//import '../../../../infrastructure/services/tr_keys.dart';
import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:remixicon/remixicon.dart';
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
      body: Stack(children: [
        deliveryState.isLoading
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
        // The floating nav's back-only pill (FloatingNavBack, core#125 —
        // design strip section 12's one-back rule): the shared pill
        // housing carrying only the leading back segment, this screen's
        // ONE back affordance, replacing the standalone PopButton.
        // Back-only (empty tab list) because the host app's root tabs
        // are not reachable from this SDK package's pushed route.
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingBottomNav(
              mode: FloatingNavTabsMode(
                tabs: const [],
                currentIndex: 0,
                onSelect: (_) {},
                back: FloatingNavBack(
                  icon: Remix.arrow_left_wide_fill,
                  label: AppHelpers.getTranslation(TrKeys.back),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
