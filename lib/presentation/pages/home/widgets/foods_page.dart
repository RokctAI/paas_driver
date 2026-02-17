import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/application/order/all_order/order_provider.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';

import '../../../../infrastructure/services/services.dart';
import '../../../component/components.dart';
import '../../../component/loading.dart';
import '../../../styles/style.dart';

class FoodsPage extends ConsumerStatefulWidget {
  final OrderDetailData order;

  const FoodsPage({super.key, required this.order});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  bool hasData = true;

  @override
  void initState() {
    if (widget.order.details?.isEmpty ?? true) {
      hasData = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(orderProvider.notifier)
            .showOrder(context, widget.order.id ?? 0);
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    return state.isLoading
        ? const Loading()
        : SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.foods)),
                16.verticalSpace,
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: Style.white,
                  ),
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: hasData
                            ? (widget.order.details?.length ?? 0)
                            : (state.order?.details?.length ?? 0),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            child: Column(
                              children: [
                                ProductItem(
                                  product: hasData
                                      ? (widget
                                            .order
                                            .details?[index]
                                            .stock
                                            ?.product)
                                      : (state
                                            .order
                                            ?.details?[index]
                                            .stock
                                            ?.product),
                                  amount: hasData
                                      ? (widget.order.details?[index].quantity)
                                      : (state.order?.details?[index].quantity),
                                  price: AppHelpers.numberFormat(
                                    number: hasData
                                        ? (widget
                                              .order
                                              .details?[index]
                                              .totalPrice)
                                        : state
                                              .order
                                              ?.details?[index]
                                              .totalPrice,
                                  ),
                                ),
                                if (state.order?.details?[index].note != null &&
                                    state.order?.details?[index].note != '')
                                  Text(
                                    "${AppHelpers.getTranslation(TrKeys.note)}: ${state.order?.details?[index].note}",
                                    style: Style.interRegular(
                                      color: Style.blackColor,
                                      size: 14.sp,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      _priceItem(
                        title: TrKeys.subtotal,
                        price: hasData
                            ? widget.order.originPrice
                            : state.order?.originPrice,
                      ),
                      _priceItem(
                        title: TrKeys.tax,
                        price: hasData ? widget.order.tax : state.order?.tax,
                      ),
                      _priceItem(
                        title: TrKeys.serviceFee,
                        price: hasData
                            ? widget.order.serviceFee
                            : state.order?.serviceFee,
                      ),
                      _priceItem(
                        title: TrKeys.deliveryFee,
                        price: hasData
                            ? widget.order.deliveryFee
                            : state.order?.deliveryFee,
                      ),
                      _priceItem(
                        isDiscount: true,
                        title: TrKeys.discount,
                        price: hasData
                            ? widget.order.totalDiscount
                            : state.order?.totalDiscount,
                      ),
                      _priceItem(
                        isDiscount: true,
                        title: TrKeys.coupon,
                        price: state.order?.couponPrice,
                      ),
                      _priceItem(
                        isTotal: true,
                        title: TrKeys.total,
                        price: hasData
                            ? widget.order.totalPrice
                            : state.order?.totalPrice,
                      ),
                    ],
                  ),
                ),
                16.verticalSpace,
              ],
            ),
          );
  }

  RenderObjectWidget _priceItem({
    required String title,
    required num? price,
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return (price ?? 0) == 0
        ? const SizedBox.shrink()
        : Column(
            children: [
              2.verticalSpace,
              Divider(color: Style.black.withValues(alpha: 0.4)),
              2.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.getTranslation(title),
                    style: isTotal
                        ? Style.interSemi(size: 16.sp, letterSpacing: -0.3)
                        : Style.interNormal(
                            size: 14.sp,
                            letterSpacing: -0.3,
                            color: isDiscount ? Style.redColor : Style.black,
                          ),
                  ),
                  Text(
                    (isDiscount ? '-' : '') +
                        AppHelpers.numberFormat(number: price),
                    style: isTotal
                        ? Style.interSemi(size: 16.sp, letterSpacing: -0.3)
                        : Style.interNormal(
                            size: 14.sp,
                            letterSpacing: -0.3,
                            color: isDiscount ? Style.redColor : Style.black,
                          ),
                  ),
                ],
              ),
            ],
          );
  }
}
