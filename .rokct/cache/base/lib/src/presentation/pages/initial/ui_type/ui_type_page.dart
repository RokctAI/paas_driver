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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/main/main_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:remixicon/remixicon.dart';

@RoutePage()
class UiTypePage extends StatelessWidget {
  final bool isBack;

  const UiTypePage({super.key, this.isBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyle.cardDark,
        elevation: 0,
        // One back per screen (design strip section 12): the floating
        // nav's back segment below is the screen's only back affordance,
        // so the AppBar must not imply a leading arrow when pushed.
        automaticallyImplyLeading: false,
        title: Text(
          AppHelpers.getTranslation(TrKeys.uiType),
          style: AppStyle.interNormal(color: AppStyle.textPrimary),
        ),
      ),
      body: Stack(
        children: [
          GridView.builder(
            itemCount: 4,
            padding: REdgeInsets.symmetric(horizontal: 16, vertical: 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: MediaQuery.sizeOf(context).height / 2 - 64.h,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              return AnimationButtonEffect(
                child: Consumer(
                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                    return GestureDetector(
                      onTap: () async {
                        await LocalStorage.setUiType(index);
                        if (context.mounted) {
                          ref.read(mainProvider.notifier).selectIndex(0);
                          AppHelpers.goHome(context);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppHelpers.getType() == index
                                ? AppStyle.primary
                                : AppStyle.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.asset("assets/images/ui$index.png"),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // The floating nav's back-only pill (FloatingNavBack, core#125 — design
          // strip section 12's one-back rule): base_sdk's own FloatingBottomNav in
          // tabs mode with an empty tab list, the screen's ONE back affordance,
          // replacing the standalone PopButton and the AppBar's implied arrow.
          // Only when the page was pushed (isBack) — the initial-flow variant
          // cannot pop and shows no back at all.
          if (isBack)
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
