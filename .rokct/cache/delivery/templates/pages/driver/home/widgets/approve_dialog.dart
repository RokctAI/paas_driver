import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';


import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/marker_image_cropper.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/application/home/home_provider.dart';

class ApproveOrderDialog extends StatelessWidget {
  final OrderDetailData? order;
  final ParcelOrder? parcel;

  const ApproveOrderDialog({super.key, this.order, this.parcel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: AppHelpers.getTranslation(TrKeys.thatYouHaveIndeed),
              style: AppStyle.interNormal(size: 16.sp),
            ),
          ),
          32.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.cancel),
                  background: AppStyle.red,
                  textColor: AppStyle.white,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    return CustomButton(
                      title: AppHelpers.getTranslation(TrKeys.approve),
                      background: AppStyle.black,
                      textColor: AppStyle.white,
                      onPressed: () async {
                        if (order == null) {
                          Navigator.pop(context);
                          final ImageCropperForMarker image = ImageCropperForMarker();
                          ref
                              .read(homeProvider.notifier)
                              .goClientParcel(context, int.tryParse(parcel?.id ?? ''));
                          ref.read(homeProvider.notifier).getRoutingAll(
                                // ignore: use_build_context_synchronously
                                context: context,
                                start: LatLng(
                                  LocalStorage.getAddressSelected()?.latitude ??
                                      AppConstants.demoLatitude,
                                  LocalStorage.getAddressSelected()
                                          ?.longitude ??
                                      AppConstants.demoLongitude,
                                ),
                                end: LatLng(
                                  parcel?.addressTo?.latitude ?? 0,
                                  parcel?.addressTo?.longitude ?? 0,
                                ),
                                market: Marker(
                                  markerId: const MarkerId("B"),
                                  position: LatLng(
                                    parcel?.addressTo?.latitude ?? 0,
                                    parcel?.addressTo?.longitude ?? 0,
                                  ),
                                  icon: await image.resizeAndCircle("", 100),
                                ),
                              );
                        } else {
                          Navigator.pop(context);
                          final ImageCropperForMarker image = ImageCropperForMarker();
                          ref
                              .read(homeProvider.notifier)
                              .goClient(context, order?.id);
                          ref.read(homeProvider.notifier).getRoutingAll(
                                // ignore: use_build_context_synchronously
                                context: context,
                                start: LatLng(
                                  LocalStorage.getAddressSelected()?.latitude ??
                                      AppConstants.demoLatitude,
                                  LocalStorage.getAddressSelected()
                                          ?.longitude ??
                                      AppConstants.demoLongitude,
                                ),
                                end: LatLng(
                                  double.parse(
                                      order?.location?.latitude ?? "0"),
                                  double.parse(
                                      order?.location?.longitude ?? "0"),
                                ),
                                market: Marker(
                                  markerId: const MarkerId("User"),
                                  position: LatLng(
                                    double.parse(
                                        order?.location?.latitude ?? "0"),
                                    double.parse(
                                        order?.location?.longitude ?? "0"),
                                  ),
                                  icon: await image.resizeAndCircle(
                                      order?.user?.img ?? "", 100),
                                ),
                              );
                        }
                      },
                    );
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
