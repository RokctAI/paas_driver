import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:${package}/presentation/component/helper/common_image.dart';

class UserItem extends StatelessWidget {
  final UserData user;
  final bool isSelected;
  final Function() onTap;

  const UserItem({
    super.key,
    required this.user,
    required this.onTap,
    required this.isSelected,
  }) ;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74.r,
        margin: REdgeInsets.only(bottom: 8),
        padding: REdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppStyle.primary.withOpacity(0.06) : AppStyle.white,
          borderRadius: isSelected ? null : BorderRadius.circular(10.r),
          border: isSelected
              ? Border(
                  left: BorderSide(color: AppStyle.primary, width: 1.r),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.blackColor.withOpacity(0.06),
              ),
              alignment: Alignment.center,
              child: CommonImage(
                url: user.img,
                width: 40,
                height: 40,
                radius: 20,
                errorRadius: 20,
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${user.firstname} ${user.lastname ?? ''}',
                    style: AppStyle.interSemi(size: 15.sp),
                  ),
                  4.verticalSpace,
                  Text(
                    user.email ?? '',
                    style: AppStyle.interNormal(size: 12.sp),
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
