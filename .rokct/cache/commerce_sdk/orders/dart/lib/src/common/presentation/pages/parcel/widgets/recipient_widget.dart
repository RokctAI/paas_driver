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

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orders_sdk/src/common/application/parcel/parcel_notifier.dart';
import 'package:orders_sdk/src/common/application/parcel/parcel_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/custom_toggle.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/models/models.dart';
import 'package:orders_sdk/src/common/presentation/pages/parcel/widgets/custom_expanded.dart';

class RecipientWidget extends StatelessWidget {
  final ParcelState state;
  final ParcelNotifier event;
  final TextEditingController username;
  final TextEditingController phone;
  final TextEditingController house;
  final TextEditingController flour;
  final TextEditingController description;
  final TextEditingController addInstruction;
  final TextEditingController value;
  final TextEditingController codAmount;

  const RecipientWidget({
    super.key,
    required this.state,
    required this.event,
    required this.username,
    required this.phone,
    required this.house,
    required this.flour,
    required this.description,
    required this.addInstruction,
    required this.value,
    required this.codAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.expand)
          Padding(
            padding: EdgeInsets.only(bottom: 16.r),
            child: Text(
              AppHelpers.getTranslation(TrKeys.recipient),
              style: AppStyle.interNoSemi(size: 16),
            ),
          ),
        InkWell(
          onTap: () async {
            final data = await AppRoutes.I.pushViewMapRoute(context, isShopLocation: true, isParcel: true);
            if (data.runtimeType == AddressNewModel) {
              if (context.mounted) {
                event.setToAddress(
                  title: (data as AddressNewModel).address?.address,
                  location: LocationModel(
                    latitude: data.location?.first,
                    longitude: data.location?.last,
                  ),
                  context: context,
                );
              }
            }
          },
          child: AnimationButtonEffect(
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.bgGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 16.r),
              child: Row(
                children: [
                  const Icon(FlutterRemix.map_pin_range_line),
                  12.horizontalSpace,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.addressTo != null)
                        Text(
                          AppHelpers.getTranslation(TrKeys.deliveryTo),
                          style: AppStyle.interRegular(size: 12),
                        ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 2 - 20.r,
                        child: Text(
                          state.addressTo ??
                              AppHelpers.getTranslation(TrKeys.deliveryTo),
                          style: AppStyle.interSemi(size: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(FlutterRemix.arrow_right_s_line),
                ],
              ),
            ),
          ),
        ),
        ExpandedSection(
          expand: state.expand,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              24.verticalSpace,
              OutlinedBorderTextField(
                inputType: TextInputType.phone,
                label: AppHelpers.getTranslation(TrKeys.phoneNumber),
                textController: phone,
                validation: (s) {
                  if (s?.isNotEmpty ?? false) {
                    return null;
                  }
                  return AppHelpers.getTranslation(TrKeys.canNotBeEmpty);
                },
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.fullName),
                textController: username,
                validation: (s) {
                  if (s?.isNotEmpty ?? false) {
                    return null;
                  }
                  return AppHelpers.getTranslation(TrKeys.canNotBeEmpty);
                },
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.house),
                textController: house,
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.floor),
                textController: flour,
              ),
              16.verticalSpace,
              OutlinedBorderTextField(
                label: AppHelpers.getTranslation(TrKeys.addInstruction),
                textController: addInstruction,
              ),
              24.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.itemDescription),
                style: AppStyle.interNoSemi(size: 16),
              ),
              16.verticalSpace,
              TextFormField(
                autocorrect: true,
                controller: description,
                decoration: InputDecoration(
                  fillColor: AppStyle.bgGrey,
                  filled: true,
                  hintText: AppHelpers.getTranslation(TrKeys.whatAreYouSending),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                ),
              ),
              16.verticalSpace,
              if (state.types.isNotEmpty)
                if ((state.types[state.selectType]?.options?.isNotEmpty ??
                    false))
                  SizedBox(
                    height: 36.r,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          state.types[state.selectType]?.options?.length ?? 0,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            if (description.text.contains(
                              (state.types[state.selectType]?.options?[index]
                                      .translation?.title ??
                                  ""),
                            )) {
                              return;
                            }
                            if (description.text.isNotEmpty) {
                              description.text = "${description.text}, ";
                            }
                            description.text = description.text +
                                (state.types[state.selectType]?.options?[index]
                                        .translation?.title ??
                                    "");
                          },
                          child: AnimationButtonEffect(
                            child: Container(
                              margin: EdgeInsets.only(right: 8.r),
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.r,
                                vertical: 10.r,
                              ),
                              decoration: BoxDecoration(
                                color: AppStyle.bgGrey,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                state.types[state.selectType]?.options?[index]
                                        .translation?.title ??
                                    "",
                                style: AppStyle.interNormal(size: 14),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              16.verticalSpace,
              TextFormField(
                autocorrect: true,
                controller: value,
                decoration: InputDecoration(
                  fillColor: AppStyle.bgGrey,
                  filled: true,
                  hintText: AppHelpers.getTranslation(TrKeys.itemValue),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.merge(
                      const BorderSide(color: AppStyle.transparent),
                      const BorderSide(color: AppStyle.transparent),
                    ),
                  ),
                ),
              ),
              16.verticalSpace,
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppHelpers.getTranslation(
                          'driver_collects_cash_from_recipient',
                        ),
                        style: AppStyle.interSemi(size: 16),
                      ),
                      Text(
                        AppHelpers.getTranslation(
                          'cash_to_collect_from_recipient',
                        ),
                        style: AppStyle.interRegular(size: 14),
                      ),
                    ],
                  ),
                  Expanded(
                    child: CustomToggle(
                      controller: ValueNotifier<bool>(state.codEnabled),
                      title: "",
                      isChecked: state.codEnabled,
                      onChange: () => event.changeCodEnabled(),
                    ),
                  ),
                ],
              ),
              if (state.codEnabled) ...[
                16.verticalSpace,
                OutlinedBorderTextField(
                  inputType:
                      const TextInputType.numberWithOptions(decimal: true),
                  label: AppHelpers.getTranslation(
                    'cash_to_collect_from_recipient',
                  ),
                  textController: codAmount,
                  validation: (s) {
                    if (!state.codEnabled) {
                      return null;
                    }
                    if ((num.tryParse(s ?? "") ?? 0) > 0) {
                      return null;
                    }
                    return AppHelpers.getTranslation(
                      'enter_cash_amount_greater_than_zero',
                    );
                  },
                ),
              ],
              16.verticalSpace,
            ],
          ),
        ),
      ],
    );
  }
}
