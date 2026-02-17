import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver/application/home/home_provider.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';
import 'package:driver/presentation/component/buttons/custom_button.dart';
import 'package:driver/presentation/component/maps_list.dart';
import 'package:driver/presentation/styles/style.dart';
import 'package:intl/intl.dart' as intl;
import '../../../infrastructure/services/services.dart';
import 'widgets/approve_dialog.dart';
import 'widgets/rate_customer.dart';

class ParcelBottomSheetScreen extends StatelessWidget {
  final ParcelOrder? parcel;

  const ParcelBottomSheetScreen({super.key, required this.parcel});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(homeProvider);
          return SizedBox(
            height: state.isGoUser
                ? MediaQuery.sizeOf(context).height * 1.8 / 3
                : MediaQuery.sizeOf(context).height * 2 / 3,
            width: double.infinity,
            child: DraggableScrollableSheet(
              initialChildSize: 0.2,
              maxChildSize: 0.65,
              minChildSize: 0.16,
              snap: true,
              builder: (context, scrollController) => Container(
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
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: 8.h,
                    bottom: MediaQuery.paddingOf(context).bottom + 16.h,
                    left: 16.w,
                    right: 16.w,
                  ),
                  children: [
                    Container(
                      height: 4.h,
                      margin: EdgeInsets.symmetric(
                        horizontal:
                            (MediaQuery.sizeOf(context).width - 100.w) / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Style.bottomSheetIconColor,
                        borderRadius: BorderRadius.circular(40.r),
                      ),
                    ),
                    24.verticalSpace,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            16.horizontalSpace,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.sizeOf(context).width - 180.w,
                                  child: Text(
                                    parcel?.addressFrom?.address ?? "",
                                    style: Style.interSemi(
                                      size: 14.sp,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                2.verticalSpace,
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Text(
                                        "№ ${parcel?.id}",
                                        style: Style.interNormal(
                                          size: 14.sp,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const VerticalDivider(),

                                      Text(
                                        intl.DateFormat("HH:mm").format(
                                          parcel?.updatedAt ?? DateTime.now(),
                                        ),
                                        style: Style.interNormal(
                                          size: 14.sp,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      16.horizontalSpace,
                                      Icon(
                                        FlutterRemix.building_fill,
                                        size: 18.r,
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                        ),
                                        onPressed: () async {
                                          AppHelpers.showCustomModalBottomSheet(
                                            context: context,
                                            modal: MapsList(
                                              location: Coords(
                                                parcel?.addressFrom?.latitude ??
                                                    0,
                                                parcel
                                                        ?.addressFrom
                                                        ?.longitude ??
                                                    0,
                                              ),
                                              title: "A",
                                            ),
                                            isDarkMode: false,
                                          );
                                        },
                                        icon: Icon(
                                          FlutterRemix.map_2_fill,
                                          size: 18.r,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: parcel?.phoneFrom ?? "",
                                    );
                                    await launchUrl(launchUri);
                                  },
                                  child: Container(
                                    height: 38.r,
                                    width: 38.r,
                                    decoration: const BoxDecoration(
                                      color: Style.black,
                                      shape: BoxShape.circle,
                                    ),
                                    margin: EdgeInsets.all(4.r),
                                    child: Icon(
                                      FlutterRemix.phone_fill,
                                      color: Style.white,
                                      size: 20.r,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'sms',
                                      path: parcel?.phoneFrom ?? "",
                                    );
                                    await launchUrl(launchUri);
                                  },
                                  child: Container(
                                    height: 38.r,
                                    width: 38.r,
                                    decoration: const BoxDecoration(
                                      color: Style.black,
                                      shape: BoxShape.circle,
                                    ),
                                    margin: EdgeInsets.all(4.r),
                                    child: Icon(
                                      FlutterRemix.chat_1_fill,
                                      color: Style.white,
                                      size: 20.r,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        24.verticalSpace,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            16.horizontalSpace,
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width - 180.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.sizeOf(context).width -
                                        190.w,
                                    child: Text(
                                      parcel?.addressTo?.address ?? "",
                                      style: Style.interSemi(
                                        size: 14.sp,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                  2.verticalSpace,
                                  IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            parcel?.usernameTo ?? "",
                                            style: Style.interNormal(
                                              size: 12.sp,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ),
                                        const VerticalDivider(),
                                        Text(
                                          parcel?.phoneTo ?? "",
                                          style: Style.interNormal(
                                            size: 12.sp,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                          ),
                                          onPressed: () {
                                            AppHelpers.showCustomModalBottomSheet(
                                              context: context,
                                              modal: MapsList(
                                                location: Coords(
                                                  parcel?.addressTo?.latitude ??
                                                      0,
                                                  parcel
                                                          ?.addressTo
                                                          ?.longitude ??
                                                      0,
                                                ),
                                                title: "B",
                                              ),
                                              isDarkMode: false,
                                            );
                                          },
                                          icon: Icon(
                                            FlutterRemix.map_2_fill,
                                            size: 18.r,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'tel',
                                      path: parcel?.phoneTo ?? "",
                                    );
                                    await launchUrl(launchUri);
                                  },
                                  child: Container(
                                    height: 38.r,
                                    width: 38.r,
                                    decoration: const BoxDecoration(
                                      color: Style.black,
                                      shape: BoxShape.circle,
                                    ),
                                    margin: EdgeInsets.all(4.r),
                                    child: Icon(
                                      FlutterRemix.phone_fill,
                                      color: Style.white,
                                      size: 20.r,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final Uri launchUri = Uri(
                                      scheme: 'sms',
                                      path: parcel?.phoneTo ?? "",
                                    );
                                    await launchUrl(launchUri);
                                  },
                                  child: Container(
                                    height: 38.r,
                                    width: 38.r,
                                    decoration: const BoxDecoration(
                                      color: Style.black,
                                      shape: BoxShape.circle,
                                    ),
                                    margin: EdgeInsets.all(4.r),
                                    child: Icon(
                                      FlutterRemix.chat_1_fill,
                                      color: Style.white,
                                      size: 20.r,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    24.verticalSpace,
                    CustomButton(
                      title: AppHelpers.getTranslation(
                        state.isGoRestaurant
                            ? TrKeys.completeCheckout
                            : TrKeys.iDeliveredTheOrder,
                      ),
                      onPressed: () {
                        if (state.isGoRestaurant) {
                          AppHelpers.showAlertDialog(
                            context: context,
                            child: ApproveOrderDialog(parcel: parcel),
                          );
                        } else {
                          ref
                              .read(homeProvider.notifier)
                              .deliveredFinishParcel(
                                context: context,
                                parcelId: parcel?.id,
                              );
                          AppHelpers.showCustomModalBottomSheet(
                            context: context,
                            modal: RateCustomer(parcel: parcel),
                            isDarkMode: false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
