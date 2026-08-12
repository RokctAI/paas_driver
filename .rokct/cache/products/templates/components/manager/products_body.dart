import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:base_sdk/src/presentation/components/loading/loading_list.dart';
import 'package:${package}/presentation/components/foods/food_item.dart';

/// The foods-tab product list, typed on `SellerProductData`. The legacy
/// ProductsBody served both this tab and the POS browse with an
/// `isOrderFoods` flag; the POS half now lives in orders_sdk's
/// `components/orders/products_body.dart`, so this variant renders `FoodItem`
/// only and the flag is gone.
class ProductsBody extends StatelessWidget {
  final RefreshController refreshController;
  final int bottomPadding;
  final bool isLoading;
  final int itemSpacing;
  final List<SellerProductData> products;
  final Function(int) onProductTap;
  final Function() onLoading;
  final Function() onRefreshing;
  final int loadingHeight;
  final ScrollPhysics scrollPhysics;

  const ProductsBody({
    super.key,
    required this.refreshController,
    required this.isLoading,
    required this.products,
    required this.onProductTap,
    required this.onLoading,
    required this.onRefreshing,
    this.itemSpacing = 1,
    this.bottomPadding = 72,
    this.loadingHeight = 188,
    this.scrollPhysics = const BouncingScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? LoadingList(
            verticalPadding: 16,
            itemBorderRadius: 0,
            itemPadding: itemSpacing,
            itemHeight: loadingHeight,
          )
        : SmartRefresher(
            controller: refreshController,
            physics: scrollPhysics,
            enablePullDown: true,
            enablePullUp: true,
            onLoading: onLoading,
            onRefresh: onRefreshing,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: REdgeInsets.only(top: 16, bottom: bottomPadding.r),
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) => FoodItem(
                product: products[index],
                spacing: itemSpacing,
                onTap: () => onProductTap(index),
              ),
            ),
          );
  }
}
