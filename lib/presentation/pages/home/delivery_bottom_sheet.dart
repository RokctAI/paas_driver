import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';

import 'package:driver/application/providers.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/styles/style.dart';
import 'widgets/approve_dialog.dart';
import 'widgets/foods_page.dart';
import 'widgets/rate_customer.dart';

class DeliverBottomSheetScreen extends StatefulWidget {
  final OrderDetailData order;

  const DeliverBottomSheetScreen({super.key, required this.order});

  @override
  State<DeliverBottomSheetScreen> createState() =>
      _DeliverBottomSheetScreenState();
}

class _DeliverBottomSheetScreenState extends State<DeliverBottomSheetScreen> {
  TextEditingController noteCon = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    noteCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Consumer(
        builder: (context, ref, child) {
          return SizedBox(
            height: ref.watch(homeProvider).isGoUser
                ? MediaQuery.sizeOf(context).height * 1.8 / 3
                : MediaQuery.sizeOf(context).height * 2 / 3,
            width: double.infinity,
            child: DraggableScrollableSheet(
              initialChildSize: 0.2,
              maxChildSize: 1,
              minChildSize: 0.16,
              snap: true,
              builder: (context, scrollController) => Container(
                width: MediaQuery.sizeOf(context).width,
                decoration: BoxDecoration(
                  color: Style.greyColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    topLeft: Radius.circular(12.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Style.black.withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: 8.h,
                    bottom: MediaQuery.paddingOf(context).bottom + 16.h,
                    left: 16.w,
                    right: 16.w,
                  ),
                  children: [
                    Container(
                      height: 4.h,
                      margin: EdgeInsets.symmetric(
                        horizontal:
                            (MediaQuery.sizeOf(context).width - 100.w) / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Style.bottomSheetIconColor,
                        borderRadius: BorderRadius.circular(40.r),
                      ),
                    ),
                    24.verticalSpace,
                    OrderItem(
                      order: widget.order,
                      isDeliveryShop: ref.watch(homeProvider).isGoRestaurant,
                      isDeliveryClient: ref.watch(homeProvider).isGoUser,
                    ),
                    24.verticalSpace,
                    ref.watch(homeProvider).isGoRestaurant
                        ? Column(
                            children: [
                              CustomButton(
                                title: AppHelpers.getTranslation(
                                  TrKeys.orderInformation,
                                ),
                                onPressed: () {
                                  AppHelpers.showCustomModalBottomSheet(
                                    context: context,
                                    modal: FoodsPage(order: widget.order),
                                    isDarkMode: false,
                                  );
                                },
                                background: Style.transparent,
                                borderColor: Style.black,
                              ),
                              10.verticalSpace,
                            ],
                          )
                        : const SizedBox.shrink(),
                    CustomButton(
                      title: AppHelpers.getTranslation(
                        ref.watch(homeProvider).isGoRestaurant
                            ? TrKeys.completeCheckout
                            : TrKeys.iDeliveredTheOrder,
                      ),
                      onPressed: () {
                        if (ref.watch(homeProvider).isGoRestaurant) {
                          AppHelpers.showAlertDialog(
                            context: context,
                            child: ApproveOrderDialog(order: widget.order),
                          );
                        } else {
                          AppHelpers.openDialogImagePicker(
                            context: context,
                            onSuccess: (path) async {
                              if (context.mounted) {
                                if (path.isNotEmpty) {
                                  ref
                                      .read(homeProvider.notifier)
                                      .uploadImage(
                                        context: context,
                                        orderId: widget.order.id,
                                        path: path,
                                      );
                                }
                                ref
                                    .read(homeProvider.notifier)
                                    .deliveredFinish(
                                      context: context,
                                      orderId: widget.order.id,
                                    );
                                Navigator.pop(context);
                                AppHelpers.showCustomModalBottomSheet(
                                  context: context,
                                  modal: RateCustomer(order: widget.order),
                                  isDarkMode: false,
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      title: AppHelpers.getTranslation(TrKeys.cancel),
                      textColor: Colors.white,
                      background: Style.redColor,
                      onPressed: () {
                        AppHelpers.showAlertDialog(
                          context: context,
                          child: StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Style.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 30.h,
                                  horizontal: 24.w,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        text: AppHelpers.getTranslation(
                                          TrKeys.areYouSure,
                                        ),
                                        style: Style.interNormal(size: 16.sp),
                                      ),
                                    ),
                                    Form(
                                      key: formKey,
                                      child: UnderlinedBorderTextField(
                                        textController: noteCon,
                                        label: 'Note',
                                        validator: (p0) {
                                          if (p0?.isEmpty ?? true) {
                                            return AppHelpers.getTranslation(
                                              TrKeys.cannotBeEmpty,
                                            );
                                          }
                                          return null;
                                        },
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    32.verticalSpace,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            title: AppHelpers.getTranslation(
                                              TrKeys.cancel,
                                            ),
                                            background: Style.redColor,
                                            textColor: Style.white,
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                        10.horizontalSpace,
                                        Expanded(
                                          child: Consumer(
                                            builder: (context, ref, child) {
                                              return CustomButton(
                                                title:
                                                    AppHelpers.getTranslation(
                                                      TrKeys.confirmation,
                                                    ),
                                                background: Style.black,
                                                textColor: Style.white,
                                                borderColor: Colors.transparent,
                                                onPressed: () {
                                                  if ((formKey.currentState
                                                              ?.validate() ??
                                                          false) &&
                                                      widget.order.id != null) {
                                                    ref
                                                        .read(
                                                          homeProvider.notifier,
                                                        )
                                                        .cancelOrder(
                                                          context: context,
                                                          orderId:
                                                              widget.order.id ??
                                                              0,
                                                          note: noteCon.text,
                                                        );
                                                    Navigator.pop(context);
                                                  }

                                                  /// TODO CANCEL ORDER AND SEND NOTE
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
