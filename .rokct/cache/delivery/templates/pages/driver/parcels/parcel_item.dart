import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';

import 'package:intl/intl.dart' as intl;
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:${package}/presentation/pages/parcel/parcel_order.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ParcelItem extends StatelessWidget {
  final ParcelOrder? parcel;
  final bool isOrder;
  final bool isSet;

  const ParcelItem({
    super.key,
    this.parcel,
    required this.isOrder,
    required this.isSet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: ParcelOrderPage(
            parcel: parcel,
            isOrder: isOrder,
            isSet: isSet,
          ),
          isDarkMode: false,
          paddingTop: MediaQuery.paddingOf(context).top,
          radius: 12,
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.all(Radius.circular(10.r))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "#${AppHelpers.getTranslation(TrKeys.id)}${parcel?.id}",
              style: AppStyle.interSemi(
                size: 16,
              ),
            ),
            16.verticalSpace,
            Text(
              parcel?.addressFrom?.address ?? "",
              style: AppStyle.interSemi(
                size: 16,
              ),
            ),
            16.verticalSpace,
            Text(
              parcel?.addressTo?.address ?? "",
              style: AppStyle.interSemi(
                size: 16,
              ),
            ),
            16.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.numberFormat(
                          isOrder: parcel?.currency?.symbol != null,
                          symbol: parcel?.currency?.symbol,
                          number: (parcel?.totalPrice?.isNegative ?? true)
                              ? 0
                              : (parcel?.totalPrice ?? 0)),
                      style: AppStyle.interNormal(
                        size: 16,
                      ),
                    ),
                    6.verticalSpace,
                    Text(
                      intl.DateFormat("MMM dd, HH:mm")
                          .format(parcel?.createdAt ?? DateTime.now()),
                      style: AppStyle.interRegular(
                        size: 12,
                      ),
                    )
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
