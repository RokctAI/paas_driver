import 'package:driver/presentation/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:driver/application/profile/provider/profile_settings_provider.dart';

import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/styles/style.dart';
import 'widgets/stores.dart';

class BottomSheetScreen extends StatefulWidget {
  final bool isScrolling;

  const BottomSheetScreen({super.key, required this.isScrolling});

  @override
  State<BottomSheetScreen> createState() => _BottomSheetScreenState();
}

class _BottomSheetScreenState extends State<BottomSheetScreen> {
  final List<String> image = [
    "https://www.deliveryhero.com/wp-content/uploads/2021/01/TAR_5922.jpg",
    'https://images.ctfassets.net/trvmqu12jq2l/1LFP1rAaPMiEx5y11ZZv2F/5167948e81a58a08e516631e07ee154c/blog-hero-1208x1080-v115.14.01.jpg',
    'https://images.unsplash.com/photo-1566576721346-d4a3b4eaeb55?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8cGFja2FnZSUyMGRlbGl2ZXJ5fGVufDB8fDB8fA%3D%3D&w=1000&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      bottom: widget.isScrolling ? -280.h : 0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        height: 336.h,
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
          color: Style.greyColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12.r),
            topLeft: Radius.circular(12.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Style.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          top: 8.h,
          bottom: MediaQuery.paddingOf(context).bottom + 16.h,
          left: 16.w,
          right: 16.w,
        ),
        child: Column(
          children: [
            Container(
              height: 4.h,
              width: 48.w,
              decoration: BoxDecoration(
                color: Style.bottomSheetIconColor,
                borderRadius: BorderRadius.circular(40.r),
              ),
            ),
            Column(
              children: [
                18.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_balance(context), _benefit(context)],
                ),
                SizedBox(
                  height: 186.h,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 24.h),
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return StoresPage(image: image[index]);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // context.pushRoute(const OrdersRoute());
      },
      child: Container(
        height: 64.h,
        width: (MediaQuery.sizeOf(context).width - 42.w) / 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Style.primary),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Style.black,
              ),
              child: Icon(FlutterRemix.file_list_2_fill, color: Style.primary),
            ),
            14.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                4.verticalSpace,
                SizedBox(
                  width: 60.w,
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.foodymanBenefit),
                    style: Style.interNormal(size: 12.sp, letterSpacing: -0.3),
                    maxLines: 1,
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    return Text(
                      AppHelpers.numberFormat(
                        number:
                            (ref
                                .watch(profileSettingsProvider)
                                .statistics
                                ?.data
                                ?.totalPrice ??
                            0),
                      ),
                      style: Style.interSemi(size: 14.sp, letterSpacing: -0.3),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balance(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // AppHelpers.showAlertDialog(
        //   context: context,
        //   child:  PushOrder(),
        // );
      },
      child: Container(
        height: 64.h,
        width: (MediaQuery.sizeOf(context).width - 42.w) / 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Style.white),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            SvgPicture.asset(Assets.svgBalance),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.balance),
                    style: Style.interNormal(size: 12.sp, letterSpacing: -0.3),
                  ),
                  Expanded(
                    child: Text(
                      AppHelpers.numberFormat(
                        number: LocalStorage.getUser()?.wallet?.price,
                        maxLength: 3,
                      ),
                      style: Style.interSemi(size: 14.sp, letterSpacing: -0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
