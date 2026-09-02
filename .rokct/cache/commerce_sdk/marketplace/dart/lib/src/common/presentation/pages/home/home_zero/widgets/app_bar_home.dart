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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:base_sdk/src/application/home/home_notifier.dart';
import 'package:base_sdk/src/application/home/home_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/sellect_address_screen.dart';

class AppBarHome extends StatelessWidget {
  final HomeState state;
  final HomeNotifier event;

  const AppBarHome({super.key, required this.state, required this.event});

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      child: InkWell(
        onTap: () {
          if (LocalStorage.getToken().isEmpty) {
            context.router.pushNamed('/map');
            return;
          }
          AppHelpers.showCustomModalBottomSheet(
            context: context,
            modal: SelectAddressScreen(
              addAddress: () async {
                await context.router.pushNamed('/map');
              },
            ),
            isDarkMode: false,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyle.bgGrey,
              ),
              padding: EdgeInsets.all(12.r),
              child: SvgPicture.asset("assets/svgs/adress.svg"),
            ),
            10.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.deliveryAddress),
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.textGrey,
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width - 120.w,
                      child: Text(
                        (LocalStorage.getAddressSelected()?.title?.isEmpty ??
                                true)
                            ? LocalStorage.getAddressSelected()?.address ?? ''
                            : LocalStorage.getAddressSelected()?.title ?? "",
                        style: AppStyle.interBold(
                          size: 14,
                          color: AppStyle.black,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_sharp),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
