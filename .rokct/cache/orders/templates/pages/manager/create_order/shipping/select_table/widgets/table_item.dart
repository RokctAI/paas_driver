import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class TableItem extends StatelessWidget {
  final TableData? table;
  final bool isSelected;
  final Function() onTap;

  const TableItem({
    super.key,
    required this.table,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74.r,
        margin: REdgeInsets.only(bottom: 8),
        padding: REdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppStyle.primary.withOpacity(0.06) : AppStyle.white,
          borderRadius: isSelected ? null : BorderRadius.circular(10.r),
          border: isSelected
              ? Border(
                  left: BorderSide(color: AppStyle.primary, width: 1.r),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                table?.name ?? "",
                style: AppStyle.interSemi(size: 15.sp),
              ),
            ),
            4.verticalSpace,
            Row(
              children: [
                Icon(
                  Icons.chair_alt,
                  size: 21.r,
                ),
                Text(
                  "${table?.chairCount ?? 0}",
                  style: AppStyle.interNormal(size: 12.sp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
