import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

class SelectableAddonItem extends StatelessWidget {
  final SellerProductData addon;
  final bool isLast;
  final VoidCallback? onTap;

  const SelectableAddonItem({
    super.key,
    required this.addon,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          18.verticalSpace,
          Row(
            children: [
              Icon(
                (addon.isSelectedAddon ?? false)
                    ? FlutterRemix.checkbox_circle_fill
                    : FlutterRemix.checkbox_blank_circle_line,
                size: 24.r,
                color: (addon.isSelectedAddon ?? false)
                    ? AppStyle.primary
                    : AppStyle.blackColor,
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${addon.translation?.title}',
                      style:
                          AppStyle.interSemi(size: 14.sp, letterSpacing: -0.3),
                    ),
                    4.verticalSpace,
                    Text(
                      '${addon.translation?.description}',
                      style: AppStyle.interRegular(
                          size: 12.sp, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          20.verticalSpace,
          if (!isLast)
            Divider(
              thickness: 1.r,
              height: 1.r,
              color: AppStyle.textGrey.withOpacity(0.15),
            ),
        ],
      ),
    );
  }
}
