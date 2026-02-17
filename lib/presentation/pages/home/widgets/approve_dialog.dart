import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';

import '../../../../application/providers.dart';
import '../../../../infrastructure/models/data/order_detail.dart';
import '../../../../infrastructure/services/services.dart';
import '../../../component/components.dart';
import '../../../styles/style.dart';

class ApproveOrderDialog extends StatelessWidget {
  final OrderDetailData? order;
  final ParcelOrder? parcel;

  const ApproveOrderDialog({super.key, this.order, this.parcel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Style.white,
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
              style: Style.interNormal(size: 16.sp),
            ),
          ),
          32.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.cancel),
                  background: Style.redColor,
                  textColor: Style.white,
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
                      background: Style.black,
                      textColor: Style.white,
                      onPressed: () async {
                        if (order == null) {
                          Navigator.pop(context);
                          final ImageCropperMarker image = ImageCropperMarker();
                          ref
                              .read(homeProvider.notifier)
                              .goClientParcel(context, parcel?.id);
                          ref
                              .read(homeProvider.notifier)
                              .getRoutingAll(
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
                          final ImageCropperMarker image = ImageCropperMarker();
                          ref
                              .read(homeProvider.notifier)
                              .goClient(context, order?.id);
                          ref
                              .read(homeProvider.notifier)
                              .getRoutingAll(
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
                                    order?.location?.latitude ?? "0",
                                  ),
                                  double.parse(
                                    order?.location?.longitude ?? "0",
                                  ),
                                ),
                                market: Marker(
                                  markerId: const MarkerId("User"),
                                  position: LatLng(
                                    double.parse(
                                      order?.location?.latitude ?? "0",
                                    ),
                                    double.parse(
                                      order?.location?.longitude ?? "0",
                                    ),
                                  ),
                                  icon: await image.resizeAndCircle(
                                    order?.user?.img ?? "",
                                    100,
                                  ),
                                ),
                              );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
