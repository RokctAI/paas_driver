import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/time_service.dart';
import 'package:jiffy/jiffy.dart';
import 'package:orders_sdk/src/common/application/auto_order/auto_order_notifier.dart';
import 'package:orders_sdk/src/common/application/auto_order/auto_order_provider.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/application/save_card/saved_cards_provider.dart';
import 'package:base_sdk/src/models/data/repeat_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';

class AutoOrderModal extends ConsumerStatefulWidget {
  final String orderId;
  final String time;
  final RepeatData? repeatData;

  const AutoOrderModal({
    super.key,
    required this.repeatData,
    required this.orderId,
    required this.time,
  });

  @override
  ConsumerState<AutoOrderModal> createState() => _AutoOrderModalState();
}

class _AutoOrderModalState extends ConsumerState<AutoOrderModal> {
  Timer? timer;

  @override
  void initState() {
    timer = Timer(const Duration(milliseconds: 100), init);
    super.initState();
  }

  init() async {
    final orderState = ref.read(orderProvider);
    final grandTotal = (orderState.calculateData?.totalPrice ?? 0).toDouble();
    ref
        .read(autoOrderProvider.notifier)
        .init(widget.repeatData ?? RepeatData(), grandTotal);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(autoOrderProvider);
    final event = ref.read(autoOrderProvider.notifier);
    final savedCardsState = ref.watch(savedCardsProvider);

    return Container(
      margin: MediaQuery.of(context).viewInsets,
      decoration: BoxDecoration(
        color: AppStyle.bgGrey.withOpacity(0.96),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      width: double.infinity,
      child: SingleChildScrollView(
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
                        borderRadius: BorderRadius.all(Radius.circular(40.r)),
                      ),
                    ),
                  ),
                  14.verticalSpace,
                  TitleAndIcon(
                    title: AppHelpers.getTranslation(TrKeys.autoOrder),
                    paddingHorizontalSize: 0,
                    rightTitle: (widget.repeatData?.updatedAt?.isNotEmpty ??
                            false)
                        ? "${AppHelpers.getTranslation(TrKeys.started)} ${Jiffy.parseFromDateTime(DateTime.parse(widget.repeatData?.updatedAt ?? '')).from(Jiffy.now())}"
                        : "",
                  ),
                  10.verticalSpace,
                  // Period Selection
                  Text(
                    AppHelpers.getTranslation(TrKeys.period),
                    style: AppStyle.interNormal(
                      size: 14,
                      color: AppStyle.black,
                    ),
                  ),
                  8.verticalSpace,
                  Row(
                    children: [
                      _buildChip(
                        0,
                        "Daily",
                        state.cronPattern == '0 0 * * *',
                        event,
                      ),
                      8.horizontalSpace,
                      _buildChip(
                        1,
                        "Weekly",
                        state.cronPattern == '0 0 * * 1',
                        event,
                      ),
                      8.horizontalSpace,
                      _buildChip(
                        2,
                        "Bi-Weekly",
                        state.cronPattern == '0 0 1,15 * *',
                        event,
                      ),
                      8.horizontalSpace,
                      _buildChip(
                        3,
                        "Monthly",
                        state.cronPattern == '0 0 1 * *',
                        event,
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Wrap(
                      runSpacing: 15,
                      spacing: 20,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppHelpers.getTranslation(TrKeys.from),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                _showDatePicker(
                                  context,
                                  state.from,
                                  event.pickFrom,
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    TimeService.dateFormatYMD(state.from),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    CupertinoIcons.chevron_up_chevron_down,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (state.cronPattern ==
                            '0 0 * * *') // Only show "To" for Daily
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppHelpers.getTranslation(TrKeys.to),
                                style: const TextStyle(fontSize: 18),
                              ),
                              10.horizontalSpace,
                              GestureDetector(
                                onTap: () {
                                  if (state.to != null) {
                                    _showDatePicker(
                                      context,
                                      state.to!,
                                      event.pickTo,
                                    );
                                  } else {
                                    _showDatePicker(
                                      context,
                                      DateTime.now().add(
                                        const Duration(days: 7),
                                      ),
                                      event.pickTo,
                                    );
                                  }
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      state.to != null
                                          ? TimeService.dateFormatYMD(state.to!)
                                          : AppHelpers.getTranslation(
                                              TrKeys.select,
                                            ),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(
                                      CupertinoIcons.chevron_up_chevron_down,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Payment Method Section
                  16.verticalSpace,
                  Text(
                    AppHelpers.getTranslation(TrKeys.paymentMethod),
                    style: AppStyle.interNormal(
                      size: 14,
                      color: AppStyle.black,
                    ),
                  ),
                  8.verticalSpace,
                  Row(
                    children: [
                      _buildPaymentChip(
                        "Wallet",
                        state.paymentMethod == "Wallet",
                        event,
                      ),
                      8.horizontalSpace,
                      _buildPaymentChip(
                        "Saved Card",
                        state.paymentMethod == "Saved Card",
                        event,
                      ),
                    ],
                  ),
                  if (state.paymentMethod == "Saved Card")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        8.verticalSpace,
                        DropdownButton<String>(
                          value: state.savedCardId,
                          hint: Text(
                            AppHelpers.getTranslation(TrKeys.selectCard),
                          ),
                          isExpanded: true,
                          items: savedCardsState.cards.map((card) {
                            return DropdownMenuItem<String>(
                              value: card.id.toString(),
                              child: Text(
                                "${card.cardType} **** ${card.lastFour}",
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            event.setPaymentMethod("Saved Card", cardId: val);
                          },
                        ),
                      ],
                    ),

                  if (state.paymentMethod == "Wallet")
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Balance: ${AppHelpers.numberFormat(number: state.availableBalance)}",
                                style: AppStyle.interNormal(
                                  size: 14,
                                  color: AppStyle.black,
                                ),
                              ),
                              Text(
                                "Total: ${AppHelpers.numberFormat(number: state.totalBalance)}",
                                style: AppStyle.interNormal(
                                  size: 12,
                                  color: AppStyle.textGrey,
                                ),
                              ),
                            ],
                          ),
                          4.verticalSpace,
                          Text(
                            "Reserved Amount (Entire Period): ${AppHelpers.numberFormat(number: state.orderTotal)}",
                            style: AppStyle.interSemi(
                              size: 14,
                              color: AppStyle.black,
                            ),
                          ),
                          if (state.availableBalance < state.orderTotal)
                            Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                "* ${AppHelpers.getTranslation(TrKeys.insufficientBalance)}",
                                style: AppStyle.interNormal(
                                  size: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (state.isError)
                    Text(
                      "*${AppHelpers.getTranslation(TrKeys.notValidDate)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      "*${AppHelpers.getTranslation(TrKeys.autoOrderInfo)}",
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 4.h,
                    ),
                    child: Column(
                      children: [
                        if (widget.repeatData != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  title: (widget.repeatData?.to != null &&
                                          DateTime.parse(
                                            widget.repeatData!.to!,
                                          ).isBefore(DateTime.now()))
                                      ? AppHelpers.getTranslation(TrKeys.ended)
                                      : (widget.repeatData?.isActive == 1
                                          ? AppHelpers.getTranslation(
                                              TrKeys.pause,
                                            )
                                          : AppHelpers.getTranslation(
                                              TrKeys.resume,
                                            )),
                                  onPressed: (widget.repeatData?.to != null &&
                                          DateTime.parse(
                                            widget.repeatData!.to!,
                                          ).isBefore(DateTime.now()))
                                      ? null
                                      : () {
                                          if (widget.repeatData?.isActive ==
                                              1) {
                                            event.pauseAutoOrder(
                                              widget.repeatData!.id!,
                                              context,
                                            );
                                          } else {
                                            event.resumeAutoOrder(
                                              widget.repeatData!.id!,
                                              context,
                                            );
                                          }
                                        },
                                ),
                              ),
                            ],
                          ),
                          10.verticalSpace,
                        ],
                        if (event.isTimeChanged(widget.repeatData))
                          CustomButton(
                            isLoading: ref.watch(orderProvider).isButtonLoading,
                            title: AppHelpers.getTranslation(TrKeys.save),
                            onPressed: () {
                              if (event.isValidDates()) {
                                event.startAutoOrder(
                                  onSuccess: () {
                                    ref.read(orderProvider.notifier).showOrder(
                                          context,
                                          widget.orderId,
                                          true,
                                        );
                                  },
                                  orderId: widget.orderId,
                                  context: context,
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 10),
                        if (widget.repeatData != null)
                          CustomButton(
                            isLoading: ref.watch(orderProvider).isButtonLoading,
                            textColor: Colors.white,
                            background: Colors.red,
                            title: AppHelpers.getTranslation(
                              TrKeys.removeAutoOrder,
                            ),
                            onPressed: () {
                              ref
                                  .read(orderProvider.notifier)
                                  .showOrder(context, widget.orderId, true);
                              event.deleteAutoOrder(
                                orderId: widget.repeatData?.id ?? "",
                                context: context,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    int index,
    String title,
    bool isSelected,
    AutoOrderNotifier event,
  ) {
    return ActionChip(
      label: Text(title),
      backgroundColor: isSelected ? AppStyle.primary : AppStyle.white,
      labelStyle: TextStyle(
        color: isSelected ? AppStyle.white : AppStyle.black,
      ),
      onPressed: () => event.setPeriod(index),
    );
  }

  Widget _buildPaymentChip(
    String title,
    bool isSelected,
    AutoOrderNotifier event,
  ) {
    return ActionChip(
      label: Text(title),
      backgroundColor: isSelected ? AppStyle.primary : AppStyle.white,
      labelStyle: TextStyle(
        color: isSelected ? AppStyle.white : AppStyle.black,
      ),
      onPressed: () => event.setPaymentMethod(title),
    );
  }

  void _showDatePicker(
    BuildContext context,
    DateTime initial,
    Function(DateTime) onChanged,
  ) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: Container(
        height: 250.h,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initial,
            mode: CupertinoDatePickerMode.date,
            use24hFormat: AppConstants.use24Format,
            onDateTimeChanged: (DateTime newDate) {
              onChanged(newDate);
            },
          ),
        ),
      ),
      isDarkMode: false,
    );
  }
}
