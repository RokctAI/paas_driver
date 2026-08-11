import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'stocks/edit_food_stocks_body.dart';
import 'details/edit_food_details_body.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:${package}/presentation/component/helper/modal_drag.dart';
import 'package:${package}/presentation/component/helper/modal_wrap.dart';

class EditProductModal extends StatefulWidget {
  final SellerProductData product;
  final ScrollController controller;

  const EditProductModal(
      {super.key, required this.product, required this.controller});

  @override
  State<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrap(
      body: Column(
        children: [
          const ModalDrag(),
          Container(
            padding: REdgeInsets.all(6),
            height: 48.h,
            decoration: BoxDecoration(
              color: AppStyle.transparent,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppStyle.tabBarBorderColor),
            ),
            margin: REdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.blackColor,
              ),
              labelColor: AppStyle.white,
              unselectedLabelColor: AppStyle.textGrey,
              unselectedLabelStyle: AppStyle.interRegular(size: 14.sp),
              labelStyle: AppStyle.interSemi(size: 14.sp),
              tabs: [
                Tab(child: Text(AppHelpers.getTranslation(TrKeys.editProduct))),
                Tab(child: Text(AppHelpers.getTranslation(TrKeys.stocks))),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EditFoodDetailsBody(
                  controller: widget.controller,
                  onSave: () => _tabController.animateTo(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  ),
                ),
                EditFoodStocksBody(product: widget.product),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
