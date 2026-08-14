import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';

class MainGroupItem extends StatelessWidget {
  final SellerExtrasGroup group;
  final Function() onTap;

  const MainGroupItem({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: AppStyle.white,
          ),
          padding: REdgeInsets.all(18),
          margin: REdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${group.translation?.title}',
                style: AppStyle.interNormal(),
              ),
              Icon(
                Remix.arrow_right_s_line,
                size: 22.r,
                color: AppStyle.blackColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
