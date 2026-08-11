import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class SearchedUserItem extends StatelessWidget {
  final UserData user;

  const SearchedUserItem({super.key, required this.user}) ;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppStyle.white,
      ),
      padding: REdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      margin: REdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${user.firstname ?? AppHelpers.getTranslation(TrKeys.noName)} ${user.lastname ?? ''}',
            style: AppStyle.interNormal(),
          ),
          6.verticalSpace,
          Text(
            '${user.email}',
            style: AppStyle.interRegular(size: 12.sp),
          ),
        ],
      ),
    );
  }
}
