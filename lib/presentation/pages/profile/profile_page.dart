import 'package:auto_route/auto_route.dart';
import 'package:driver/presentation/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver/presentation/pages/profile/widgets/edit_profile_modal.dart';
import 'package:driver/application/providers.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/routes/app_router.gr.dart';
import 'package:driver/presentation/styles/style.dart';
import '../auth/login/widgets/languages_modal.dart';
import 'widgets/logout_modal.dart';
import 'widgets/sections_item.dart';

@RoutePage()
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final bool isLtr = LocalStorage.getLangLtr();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSettingsProvider);
    ref.watch(appProvider);
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Style.greyColor,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            CustomAppBar(
              bottomPadding: 4.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Hero(
                    tag: AppConstants.heroTagProfileAvatar,
                    child: Consumer(
                      builder: (context, ref, child) {
                        ref.watch(profileImageProvider);
                        return DriverAvatar(
                          imageUrl: LocalStorage.getUser()?.img,
                          rate: LocalStorage.getUser()?.rate,
                        );
                      },
                    ),
                  ),
                  10.horizontalSpace,
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${LocalStorage.getUser()?.firstname ?? ''} ${LocalStorage.getUser()?.lastname ?? ''}',
                          style: Style.interSemi(size: 16.sp),
                        ),
                        Text(
                          LocalStorage.getUser()?.phone ?? '',
                          style: Style.interRegular(size: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: ButtonsBouncingEffect(
                      child: GestureDetector(
                        onTap: () {
                          AppHelpers.showCustomModalBottomSheet(
                            context: context,
                            modal: const LogoutModal(),
                            isDarkMode: LocalStorage.getAppThemeMode(),
                          );
                        },
                        child: Icon(
                          FlutterRemix.logout_circle_r_line,
                          size: 24.r,
                          color: Style.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Style.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.all(12.r),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          SvgPicture.asset(Assets.svgBalance),
                          10.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppHelpers.getTranslation(TrKeys.balance),
                                  style: Style.interNormal(
                                    size: 12.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  AppHelpers.numberFormat(
                                    number:
                                        LocalStorage.getUser()?.wallet?.price,
                                    maxLength: 8,
                                  ),
                                  style: Style.interSemi(
                                    size: 14.sp,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(color: Style.borderColor),
                          10.horizontalSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppHelpers.getTranslation(TrKeys.lastProfit),
                                  style: Style.interNormal(
                                    size: 12.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  AppHelpers.numberFormat(
                                    number:
                                        ref
                                            .watch(profileSettingsProvider)
                                            .statistics
                                            ?.data
                                            ?.totalPrice ??
                                        0,
                                  ),
                                  style: Style.interSemi(
                                    size: 14.sp,
                                    letterSpacing: -0.3,
                                    color: Style.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          32.horizontalSpace,
                        ],
                      ),
                    ),
                  ),
                  10.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: Style.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      children: [
                        Icon(FlutterRemix.checkbox_circle_fill, size: 30.r),
                        10.horizontalSpace,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppHelpers.getTranslation(TrKeys.deliveredOrder),
                              style: Style.interNormal(
                                size: 12.sp,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              (state.statistics?.data?.deliveredOrdersCount ??
                                      0)
                                  .toString(),
                              style: Style.interSemi(
                                size: 14.sp,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        10.horizontalSpace,
                        // if( state.requestData?.status ==
                        //     TrKeys.canceled)
                        // ButtonsBouncingEffect(
                        //   child: InkWell(
                        //     onTap: () {
                        //       AppHelpers.showAlertDialog(
                        //         context: context,
                        //         child:  CancelDialog(note: state.requestData?.statusNote ?? "",),
                        //       );
                        //     },
                        //     child: Row(
                        //       children: [
                        //         Icon(
                        //           FlutterRemix.close_circle_line,
                        //           size: 30.r,
                        //           color: Style.redColor,
                        //         ),
                        //         10.horizontalSpace,
                        //         Column(
                        //           crossAxisAlignment: CrossAxisAlignment.start,
                        //           children: [
                        //             Text(
                        //               AppHelpers.getTranslation(
                        //                   TrKeys.youStatus),
                        //               style: Style.interNormal(
                        //                 size: 12.sp,
                        //                 letterSpacing: -0.3,
                        //               ),
                        //             ),
                        //             Text(
                        //               state.requestData?.status ?? '',
                        //               style: Style.interSemi(
                        //                 size: 13.sp,
                        //                 letterSpacing: -0.3,
                        //                 color: state.requestData?.status ==
                        //                         TrKeys.canceled
                        //                     ? Style.redColor
                        //                     : Style.primaryColor,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        24.horizontalSpace,
                      ],
                    ),
                  ),
                  // _notifications(context),
                  20.verticalSpace,
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.profileSettings),
                    icon: FlutterRemix.user_settings_line,
                    onTap: () {
                      AppHelpers.showCustomModalBottomSheet(
                        paddingTop: MediaQuery.paddingOf(context).top + 32.h,
                        context: context,
                        modal: const EditProfileModal(),
                        isDarkMode: false,
                        isExpanded: true,
                      );
                    },
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.deliveryZone),
                    icon: FlutterRemix.navigation_fill,
                    onTap: () async {
                      await context.pushRoute(const DeliveryZoneRoute());
                      ref
                          .read(homeProvider.notifier)
                          .fetchDeliveryZone(isFetch: true);
                    },
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.orders),
                    icon: FlutterRemix.order_play_line,
                    onTap: () {
                      context.pushRoute(const OrdersRoute());
                    },
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.parcels),
                    icon: FlutterRemix.archive_line,
                    onTap: () {
                      context.pushRoute(const ParcelsRoute());
                    },
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.notifications),
                    icon: FlutterRemix.notification_2_line,
                    onTap: () =>
                        context.pushRoute(const NotificationListRoute()),
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.orderHistory),
                    icon: FlutterRemix.history_line,
                    onTap: () {
                      context.pushRoute(const OrderHistoryRoute());
                    },
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.parcelHistory),
                    icon: FlutterRemix.folder_history_fill,
                    onTap: () {
                      context.pushRoute(const ParcelHistoryRoute());
                    },
                  ),
                  SectionsItem(
                    title: AppHelpers.getTranslation(TrKeys.income),
                    icon: FlutterRemix.line_chart_line,
                    onTap: () {
                      context.pushRoute(const IncomeRoute());
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      return SectionsItem(
                        title: AppHelpers.getTranslation(TrKeys.language),
                        icon: FlutterRemix.global_line,
                        onTap: () {
                          AppHelpers.showCustomModalBottomSheet(
                            isDismissible: true,
                            isDrag: false,
                            context: context,
                            modal: LanguageScreen(
                              afterUpdate: (lang) {
                                ref
                                    .read(appProvider.notifier)
                                    .changeLanguage(lang);
                              },
                            ),
                            isDarkMode: false,
                          );
                        },
                      );
                    },
                  ),
                  if (!AppConstants.isDemo)
                    SectionsItem(
                      title: AppHelpers.getTranslation(TrKeys.deleteAccount),
                      icon: FlutterRemix.logout_box_r_line,
                      onTap: () {
                        AppHelpers.showCustomModalBottomSheet(
                          context: context,
                          modal: const LogoutModal(isDeleteAccount: true),
                          isDarkMode: false,
                        );
                      },
                    ),
                  100.verticalSpace,
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterFloat,
        floatingActionButton: Padding(
          padding: REdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const PopButton(),
              10.horizontalSpace,
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.onlineHelper),
                  onPressed: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: AppHelpers.getAppPhone(),
                    );
                    await launchUrl(launchUri);
                  },
                  icon: Icon(
                    FlutterRemix.chat_smile_2_fill,
                    color: Style.buttonFontColor,
                    size: 20.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _notifications(BuildContext context) {
  //   return Column(
  //     children: [
  //       24.verticalSpace,
  //       Row(
  //         children: [
  //           Container(
  //             decoration: const BoxDecoration(
  //               color: Style.primaryColor,
  //               shape: BoxShape.circle,
  //             ),
  //             height: 30.h,
  //             width: 30.w,
  //             child: Center(
  //               child: Text(
  //                 "4",
  //                 style: Style.interSemi(size: 14.sp, color: Style.blackColor),
  //               ),
  //             ),
  //           ),
  //           12.horizontalSpace,
  //           Text(
  //             AppHelpers.getTranslation(TrKeys.notifications),
  //             style: Style.interSemi(size: 18.sp, color: Style.blackColor),
  //           ),
  //           const Spacer(),
  //           GestureDetector(
  //             onTap: () {
  //               context.pushRoute(const ListNotificationRoute());
  //             },
  //             child: Padding(
  //               padding: const EdgeInsets.all(4.0),
  //               child: Text(
  //                 AppHelpers.getTranslation(TrKeys.seeAll),
  //                 style: Style.interNormal(size: 14.sp, color: Style.blueColor),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       16.verticalSpace,
  //       SizedBox(
  //         height: 136.h,
  //         child: ListView.builder(
  //           scrollDirection: Axis.horizontal,
  //           itemCount: 4,
  //           physics: const BouncingScrollPhysics(),
  //           itemBuilder: (context, index) {
  //             return const NotificationItem(
  //               date: "June 24",
  //               text: "Check your settings you have notifications turned off",
  //             );
  //           },
  //         ),
  //       ),
  //       40.verticalSpace,
  //     ],
  //   );
  // }
}
