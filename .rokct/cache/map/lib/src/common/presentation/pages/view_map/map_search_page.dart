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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_sdk/src/common/di/map_di.dart';
import 'package:map_sdk/src/common/infrastructure/services/places/places_service.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/text_fields/search_text_field.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:remixicon/remixicon.dart';

@RoutePage()
class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  List<AutocompletePrediction> searchResult = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  16.verticalSpace,
                  SearchTextField(
                    autofocus: true,
                    isBorder: true,
                    onChanged: (title) async {
                      searchResult = await googlePlaces.getAutocomplete(title);
                      setState(() {});
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchResult.length,
                      padding: EdgeInsets.only(bottom: 22.h),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            context.maybePop(searchResult[index].placeId);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              22.verticalSpace,
                              Text(
                                searchResult[index].mainText,
                                style: AppStyle.interNormal(size: 14),
                              ),
                              Text(
                                searchResult[index].secondaryText,
                                style: AppStyle.interNormal(size: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(color: AppStyle.borderColor),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The floating nav's back-only pill (FloatingNavBack, core#125 — design
          // strip section 12's one-back rule): the shared pill housing carrying
          // only the leading back segment, this screen's ONE back affordance,
          // replacing the standalone PopButton. Back-only (empty tab list)
          // because the host app's root tabs are not reachable from this SDK
          // package's pushed route.
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
        ],
      ),
    );
  }
}
