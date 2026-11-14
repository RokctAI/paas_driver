// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class FoodStockItem extends StatelessWidget {
  final Stock? product;
  final Function() onDelete;

  const FoodStockItem({
    super.key,
    required this.product,
    required this.onDelete,
  });

  /// The product this row shows. A calculation echo nests it under
  /// `stock.product`; a row straight from the cart (the pane's fallback
  /// when the calculation echoes no stocks - the demo fixture) carries it
  /// on the stock itself. Reading only the nested shape left cart rows with
  /// no name or image, and the stock's INVENTORY quantity in the badge
  /// (tour 1114, 19-order_pos_cart: "40 / R89.00").
  ProductData? get _item => product?.stock?.product ?? product?.product;

  /// How many of this line are ordered: the echo's `quantity`, or the
  /// cart's `cartCount` (a cart stock's `quantity` is what is on the shelf).
  num get _count => product?.stock?.product != null
      ? (product?.quantity ?? 1)
      : (product?.cartCount ?? product?.quantity ?? 1);

  @override
  Widget build(BuildContext context) {
    // Ink resolved from the theme: the row used to be a pinned white card,
    // which in the dark manager shell was a glaring white band.
    final ink = AppStyle.inkFor(Theme.of(context).brightness);
    return Container(
      color: AppStyle.cardFor(Theme.of(context).brightness),
      margin: REdgeInsets.only(bottom: 1),
      padding: REdgeInsets.symmetric(vertical: 12),
      child: Slidable(
        endActionPane: ActionPane(
          extentRatio: 0.12,
          motion: const ScrollMotion(),
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: () {
                      Slidable.of(context)?.close();
                      onDelete();
                    },
                    child: Container(
                      width: 50.r,
                      height: 78.r,
                      decoration: BoxDecoration(
                        color: AppStyle.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          bottomLeft: Radius.circular(16.r),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Remix.close_fill,
                        color: AppStyle.white,
                        size: 24.r,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            if ((product?.quantity ?? 0) > 0)
              // The qty badge sizes to its label ("2 each") and sits inset
              // from the row edge: a fixed 50px badge flush left clipped
              // the number (tour 1114b manager 19-order_pos_cart).
              Container(
                constraints: BoxConstraints(minWidth: 50.r, maxWidth: 96.r),
                height: 78.r,
                margin: REdgeInsetsDirectional.only(start: 12),
                padding: REdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: AppStyle.primary,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_count * (_item?.interval ?? 1)} ${_item?.unit?.translation?.title ?? ""}'
                        .trim(),
                    maxLines: 1,
                    style: AppStyle.interSemi(size: 15.sp),
                  ),
                ),
              ),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item?.translation?.title ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 14.sp,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  8.verticalSpace,
                  Text(
                    _item?.translation?.description ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 12.sp,
                      color: AppStyle.textGrey,
                      letterSpacing: -0.3,
                    ),
                  ),
                  ...?product?.stock?.extras?.map(
                    (e) => Padding(
                      padding: REdgeInsets.only(right: 4, top: 4),
                      child: Row(
                        children: [
                          Text(
                            "${e.group?.translation?.title ?? ''}: ",
                            style: AppStyle.interNormal(
                              size: 12.sp,
                              color: AppStyle.textGrey,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            AppHelpers.getTranslation(e.value ?? ''),
                            style: AppStyle.interNormal(
                              size: 12.sp,
                              color: ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...?product?.addons?.map(
                    (e) => Padding(
                      padding: REdgeInsets.only(right: 4, top: 4),
                      child: Row(
                        children: [
                          Text(
                            e.product?.translation?.title ?? '',
                            style: AppStyle.interNormal(
                              size: 12.sp,
                              color: AppStyle.textGrey,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            "  ${AppHelpers.numberFormat(number: (e.totalPrice ?? 0) / (e.quantity ?? 1))} x ${e.quantity ?? 1}",
                            style: AppStyle.interNormal(
                              size: 12.sp,
                              color: ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  8.verticalSpace,
                  if (product?.shopBonus ?? false)
                    Text(
                      AppHelpers.getTranslation(TrKeys.shopBonus),
                      style: AppStyle.interSemi(
                        size: 14.sp,
                        color: ink,
                        letterSpacing: -0.3,
                      ),
                    )
                  else if (product?.bonus ?? false)
                    Text(
                      AppHelpers.getTranslation(TrKeys.bonus),
                      style: AppStyle.interSemi(
                        size: 14.sp,
                        color: ink,
                        letterSpacing: -0.3,
                      ),
                    )
                  else
                    Text(
                      AppHelpers.numberFormat(number: product?.totalPrice),
                      style: AppStyle.interSemi(
                        size: 14.sp,
                        color: ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                ],
              ),
            ),
            8.horizontalSpace,
            CommonImage(
              width: 110,
              height: 106,
              url: _item?.img,
              radius: 0,
              errorRadius: 0,
              fit: BoxFit.fitWidth,
            ),
            16.horizontalSpace,
          ],
        ),
      ),
    );
  }
}
