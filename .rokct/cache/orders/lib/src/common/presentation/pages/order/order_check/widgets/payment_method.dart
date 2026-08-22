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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/payment_methods/payment_provider.dart';
import 'package:base_sdk/src/application/payment_methods/payment_state.dart';
import 'package:base_sdk/src/models/data/payment_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/application/payment_methods/payment_notifier.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/presentation/components/select_item.dart';

class PaymentMethods extends ConsumerStatefulWidget {
  final ValueChanged<PaymentData>? payLater;
  final Function(PaymentData, num)? tips;
  final num? tipPrice;
  final bool shopEnableCod;

  const PaymentMethods({
    this.payLater,
    this.tips,
    this.tipPrice,
    this.shopEnableCod = true,
    super.key,
  });

  @override
  ConsumerState<PaymentMethods> createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends ConsumerState<PaymentMethods> {
  final bool isLtr = LocalStorage.getLangLtr();
  late PaymentNotifier event;
  late PaymentState state;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).fetchPayments(
            context,
            withOutCash: widget.tipPrice != null,
            shopEnableCod: widget.shopEnableCod,
          );
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(paymentProvider.notifier);
    super.didChangeDependencies();
  }

  void _checkIfPayfast(int index) {
    final payment = state.payments[index];
    if (payment.tag?.toLowerCase() == "payfast") {
      // Now we know PayFast was selected, we could start a background process
      // This logic will be completed in the order flow
    }
  }

  @override
  Widget build(BuildContext context) {
    state = ref.watch(paymentProvider);
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bgGrey.withOpacity(0.96),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.r),
            topRight: Radius.circular(12.r),
          ),
        ),
        width: double.infinity,
        child: state.isPaymentsLoading
            ? const Loading()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                                borderRadius: BorderRadius.all(
                                  Radius.circular(40.r),
                                ),
                              ),
                            ),
                          ),
                          14.verticalSpace,
                          TitleAndIcon(
                            title: AppHelpers.getTranslation(
                              TrKeys.paymentMethods,
                            ),
                          ),
                          24.verticalSpace,
                          (state.payments.isNotEmpty)
                              ? ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: state.payments.length,
                                  itemBuilder: (context, index) {
                                    final bool isPayfast = state
                                            .payments[index].tag
                                            ?.toLowerCase() ==
                                        "payfast";
                                    return SelectItem(
                                      onTap: () {
                                        event.change(index);
                                        if (isPayfast) {
                                          _checkIfPayfast(index);
                                        }
                                      },
                                      isActive: state.currentIndex == index,
                                      title: AppHelpers.getTranslation(
                                        state.payments[index].tag ?? "",
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 32.h,
                                      left: 24.w,
                                      right: 24.w,
                                    ),
                                    child: Text(
                                      AppHelpers.getTranslation(
                                        TrKeys.paymentTypeIsNotAdded,
                                      ),
                                      style: AppStyle.interSemi(
                                        size: 16,
                                        color: AppStyle.textGrey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                          if (widget.payLater != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: 32.r),
                              child: CustomButton(
                                title: AppHelpers.getTranslation(TrKeys.pay),
                                onPressed: () {
                                  context.maybePop();
                                  widget.payLater?.call(
                                    PaymentData(
                                      id: state.payments[state.currentIndex].id,
                                      tag: AppHelpers.getTranslation(
                                        state.payments[state.currentIndex].tag,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (widget.tips != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: 32.r),
                              child: CustomButton(
                                title: AppHelpers.getTranslation(TrKeys.pay),
                                onPressed: () {
                                  context.maybePop();
                                  widget.tips?.call(
                                    PaymentData(
                                      id: state.payments[state.currentIndex].id,
                                      tag: AppHelpers.getTranslation(
                                        state.payments[state.currentIndex].tag,
                                      ),
                                    ),
                                    widget.tipPrice ?? 0,
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
