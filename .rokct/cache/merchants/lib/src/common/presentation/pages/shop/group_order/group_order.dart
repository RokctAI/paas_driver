// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';
import 'package:base_sdk/src/navigation/app_routes.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/services.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:base_sdk/src/application/shop/shop_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:merchants_sdk/src/common/presentation/pages/shop/group_order/widgets/check_status_dialog.dart';
import 'package:merchants_sdk/src/common/presentation/pages/shop/group_order/widgets/group_item.dart';

class GroupOrderScreen extends ConsumerStatefulWidget {
  final ShopData shop;
  final String? cartId;

  const GroupOrderScreen({super.key, required this.shop, this.cartId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GroupOrderPageState();
}

class _GroupOrderPageState extends ConsumerState<GroupOrderScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopOrderProvider.notifier).getCart(
            context,
            () {},
            isShowLoading: false,
            userUuid: ref.watch(shopProvider).userUuid,
            cartId: widget.cartId,
            shopId: (widget.shop.id ?? "").toString(),
          );
      ref.read(shopOrderProvider.notifier).generateShareLink(
            widget.shop.translation?.title ?? "",
            widget.shop.logoImg ?? "",
            widget.shop.type,
          );
    });

    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
      ref.read(shopOrderProvider.notifier).getCart(
            context,
            () {},
            isShowLoading: false,
            cartId: widget.cartId,
            shopId: (widget.shop.id ?? "").toString(),
            userUuid: ref.watch(shopProvider).userUuid,
          );
    });
  }

  @override
  void deactivate() {
    timer?.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    final state = ref.watch(shopOrderProvider);
    final event = ref.read(shopOrderProvider.notifier);
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bgGrey.withOpacity(0.96),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                8.verticalSpace,
                Center(
                  child: Container(
                    height: 4.h,
                    width: 48.w,
                    decoration: BoxDecoration(
                      color: AppStyle.dragElement,
                      borderRadius: BorderRadius.all(Radius.circular(40.r)),
                    ),
                  ),
                ),
                14.verticalSpace,
                TitleAndIcon(
                  title: AppHelpers.getTranslation(TrKeys.startGroupOrder),
                  paddingHorizontalSize: 0,
                ),
                10.verticalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.youFullyManaga),
                  style: AppStyle.interRegular(
                    size: 14,
                    color: AppStyle.textGrey,
                  ),
                ),
                30.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 220.w,
                      height: 46.h,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyle.cardDark,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyle.black.withOpacity(0.04),
                            spreadRadius: 0,
                            blurRadius: 2,
                            offset: const Offset(
                              0,
                              2,
                            ), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Text(
                        state.shareLink,
                        style: AppStyle.interRegular(
                          size: 14,
                          color: AppStyle.textGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        AppHelpers.showCheckTopSnackBarDone(
                          context,
                          AppHelpers.getTranslation(TrKeys.coped),
                        );
                        await Clipboard.setData(
                          ClipboardData(text: state.shareLink),
                        );
                      },
                      child: Container(
                        width: 46.w,
                        height: 46.h,
                        decoration: BoxDecoration(
                          color: AppStyle.cardDark,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppStyle.black.withOpacity(0.04),
                              spreadRadius: 0,
                              blurRadius: 2,
                              offset: const Offset(
                                0,
                                2,
                              ), // changes position of shadow
                            ),
                          ],
                        ),
                        child: const Icon(Remix.file_copy_fill),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Share.share(
                          state.shareLink,
                          subject: AppHelpers.getTranslation(
                            TrKeys.groupOrderProgress,
                          ),
                        );
                      },
                      child: Container(
                        width: 46.w,
                        height: 46.h,
                        decoration: BoxDecoration(
                          color: AppStyle.cardDark,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppStyle.black.withOpacity(0.04),
                              spreadRadius: 0,
                              blurRadius: 2,
                              offset: const Offset(
                                0,
                                2,
                              ), // changes position of shadow
                            ),
                          ],
                        ),
                        child: const Icon(Remix.share_fill),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    20.verticalSpace,
                    TitleAndIcon(
                      title: AppHelpers.getTranslation(TrKeys.groupMember),
                      paddingHorizontalSize: 0,
                      titleSize: 14,
                    ),
                    8.verticalSpace,
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.cart?.userCarts?.length ?? 0,
                      itemBuilder: (context, index) {
                        List<CartDetail?>? list =
                            state.cart?.userCarts?[index].cartDetails;
                        num total = 0;
                        list?.forEach((element) {
                          total += element?.price ?? 0;
                          element?.addons?.forEach((e) {
                            total += e.price ?? 0;
                          });
                        });
                        return GroupItem(
                          name: state.cart?.userCarts?[index].name ?? "",
                          price: total,
                          isChoosing:
                              state.cart?.userCarts?[index].status ?? false,
                          onDelete: () {
                            ref
                                .read(shopOrderProvider.notifier)
                                .deleteUser(context, index);
                          },
                          isDeleteButton:
                              LocalStorage.getUser()?.id == state.cart?.ownerId
                                  ? index != 0
                                  : false,
                        );
                      },
                    ),
                  ],
                ),
                24.verticalSpace,
                LocalStorage.getUser()?.id == state.cart?.ownerId
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: CustomButton(
                          title: (state.cart?.userCarts
                                      ?.where(
                                        (element) =>
                                            element.userId ==
                                            state.cart?.ownerId,
                                      )
                                      .isNotEmpty ??
                                  false)
                              ? (state.cart?.userCarts
                                          ?.where(
                                            (element) =>
                                                element.userId ==
                                                state.cart?.ownerId,
                                          )
                                          .single
                                          .status ??
                                      true)
                                  ? AppHelpers.getTranslation(TrKeys.done)
                                  : AppHelpers.getTranslation(TrKeys.order)
                              : AppHelpers.getTranslation(TrKeys.order),
                          onPressed: () {
                            if ((state.cart?.userCarts
                                        ?.where(
                                          (element) =>
                                              element.userId ==
                                              state.cart?.ownerId,
                                        )
                                        .isNotEmpty ??
                                    false) &&
                                (state.cart?.userCarts
                                        ?.where(
                                          (element) =>
                                              element.userId ==
                                              state.cart?.ownerId,
                                        )
                                        .single
                                        .status ??
                                    true)) {
                              event.changeStatus(
                                context,
                                (state.cart?.userCarts
                                    ?.where(
                                      (element) =>
                                          element.userId == state.cart?.ownerId,
                                    )
                                    .single
                                    .uuid),
                              );
                              setState(() {});
                              return;
                            }
                            bool check = false;
                            bool checkProduct = false;
                            for (UserCart cart in state.cart!.userCarts!) {
                              if (cart.status ?? true) {
                                check = true;
                                break;
                              }
                              if (cart.cartDetails?.isNotEmpty ?? false) {
                                checkProduct = true;
                                break;
                              }
                            }
                            if (check) {
                              AppHelpers.showAlertDialog(
                                context: context,
                                child: CheckStatusDialog(
                                  cancel: () {
                                    Navigator.pop(context);
                                  },
                                  onTap: () {
                                    for (UserCart cart
                                        in state.cart!.userCarts!) {
                                      if (cart.cartDetails?.isNotEmpty ??
                                          false) {
                                        checkProduct = true;
                                        break;
                                      }
                                    }
                                    if (!checkProduct) {
                                      Navigator.pop(context);
                                      AppHelpers.showCheckTopSnackBarInfo(
                                        context,
                                        AppHelpers.getTranslation(
                                          TrKeys.needSelectProduct,
                                        ),
                                      );
                                    } else {
                                      Navigator.pop(context);
                                      AppRoutes.I.pushOrderRoute(context);
                                    }
                                  },
                                ),
                              );
                            } else if (!checkProduct) {
                              AppHelpers.showCheckTopSnackBarInfo(
                                context,
                                AppHelpers.getTranslation(
                                  TrKeys.needSelectProduct,
                                ),
                              );
                            } else {
                              Navigator.pop(context);
                              AppRoutes.I.pushOrderRoute(context);
                            }
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 16.h,
                  ),
                  child: CustomButton(
                    title: AppHelpers.getTranslation(
                      LocalStorage.getUser()?.id == state.cart?.ownerId
                          ? TrKeys.cancel
                          : TrKeys.leaveGroup,
                    ),
                    borderColor: AppStyle.black,
                    background: AppStyle.transparent,
                    onPressed: () {
                      if (LocalStorage.getUser()?.id == state.cart?.ownerId) {
                        event.deleteCart(context);
                      } else {
                        event.deleteUser(
                          context,
                          0,
                          userId: ref.watch(shopProvider).userUuid,
                        );
                        ref.read(shopProvider.notifier).leaveGroup();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
