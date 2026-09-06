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
import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'widgets/delivery_type_item.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/components/text_fields/underlined_text_field.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/address/order/order_address_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/delivery/delivery_type_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/section/section_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/table/table_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/user/order_user_provider.dart';

// SHIPPING — /shipping-address, chip 686 (frame 37b): the shipped page's
// three blocks — the delivery-type cards (687, glyphs per canonical 375),
// Customer information (688) and the Shipping-address fieldset (689) —
// with Next (685) carrying the flow to /delivery-time. Hosted in the
// walk-in plane flow it declares the DEFAULT one plane and takes the
// LAST one; [onNext] and [onSelectAddress] then push INTO THE PLANES
// (the map claims ALL, 37c) instead of onto the route stack, and the
// host draws the one corner Back pill — so this page draws none. On the
// pushed phone route (null callbacks, 37d's push chain) Next sits at the
// START and the corner Back pill (347) at the END. The dine-in branch's
// section + table pickers and the customer picker stay pushed routes
// (list-picker family, group J — not framed here).
@RoutePage(name: 'ManagerShippingAddressRoute')
class ShippingAddressPage extends StatefulWidget {
  /// Hosted in planes: what Next does. Null pushes ManagerDeliveryTimeRoute.
  final VoidCallback? onNext;

  /// Hosted in planes: what the map-pin button (689) does. Null pushes
  /// ManagerSelectAddressRoute.
  final VoidCallback? onSelectAddress;

  const ShippingAddressPage({super.key, this.onNext, this.onSelectAddress});

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  late TextEditingController _userTextController;

  @override
  void initState() {
    super.initState();
    _userTextController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _userTextController.dispose();
  }

  /// Next is offered once the chosen type has what it needs — the
  /// shipped rule, unchanged.
  bool _canProceed(WidgetRef ref) =>
      (ref.watch(deliveryTypeProvider).type == TrKeys.delivery &&
          ref.watch(orderUserProvider).selectedUser?.phone != null) ||
      ref.watch(deliveryTypeProvider).type == TrKeys.pickup ||
      (ref.watch(deliveryTypeProvider).type == TrKeys.dineIn &&
          ref.watch(tableProvider).selectTable != null);

  void _next(BuildContext context, WidgetRef ref) {
    if (ref.watch(deliveryTypeProvider).type == TrKeys.delivery &&
        ref.watch(orderAddressProvider).location == null) {
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        AppHelpers.getTranslation(TrKeys.selectedAddress),
      );
      return;
    }
    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }
    context.pushRoute(const ManagerDeliveryTimeRoute());
  }

  void _selectAddress(BuildContext context) {
    if (widget.onSelectAddress != null) {
      widget.onSelectAddress!();
      return;
    }
    context.pushRoute(ManagerSelectAddressRoute());
  }

  /// 685 — Next, in the pane's own tokens.
  Widget _nextButton(BuildContext context, WidgetRef ref) => CustomButton(
        title: AppHelpers.getTranslation(TrKeys.next),
        onPressed: () => _next(context, ref),
      );

  @override
  Widget build(BuildContext context) {
    // Hosted in the walk-in planes (37b)? Then the host owns the back
    // pill (bottom-END) and Next docks at the foot of the pane.
    final Planes? planes = Planes.maybeOf(context);
    final bool hosted = planes != null && planes.count > 1;
    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppStyle.surfaceDark,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The 171-pattern bare title: "Shipping".
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.shipping),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interSemi(
                        size: 24,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(child: _body(context, hosted: hosted)),
                  if (hosted)
                    Consumer(
                      builder: (context, ref, child) => _canProceed(ref)
                          ? Padding(
                              padding: EdgeInsets.fromLTRB(
                                16.w,
                                8.h,
                                16.w,
                                16.h,
                              ),
                              child: _nextButton(context, ref),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
              // The phone route: Next at the START, the corner Back pill
              // (347) at the END — the settled two-state rule.
              if (!hosted)
                PositionedDirectional(
                  start: 16,
                  end: 16,
                  bottom: 16,
                  child: Consumer(
                    builder: (context, ref, child) => Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_canProceed(ref))
                          Expanded(child: _nextButton(context, ref))
                        else
                          const Spacer(),
                        8.horizontalSpace,
                        FloatingBackPill(
                          back: FloatingNavBack(
                            icon: Remix.arrow_left_wide_fill,
                            label: AppHelpers.getTranslation(TrKeys.back),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The shipped page's three blocks, scrolling under the title.
  Widget _body(BuildContext context, {required bool hosted}) {
    return Consumer(
          builder: (context, ref, child) {
            final deliveryEvent = ref.read(deliveryTypeProvider.notifier);
            final deliveryState = ref.watch(deliveryTypeProvider);
            return Container(
              padding: MediaQuery.viewInsetsOf(context),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppStyle.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: REdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          24.verticalSpace,
                          TitleAndIcon(
                            title: AppHelpers.getTranslation(
                              TrKeys.deliveryType,
                            ),
                          ),
                          24.verticalSpace,
                          DeliveryTypeItem(
                            iconData: Remix.takeaway_fill,
                            title: AppHelpers.getTranslation(
                              TrKeys.deliveryService,
                            ),
                            desc:
                                '${AppHelpers.getTranslation(TrKeys.estimatedTime)} 25 - 30 min',
                            isActive: deliveryState.type == TrKeys.delivery,
                            onTap: () => deliveryEvent.setType(TrKeys.delivery),
                          ),
                          8.verticalSpace,
                          DeliveryTypeItem(
                            iconData: Remix.walk_fill,
                            title: AppHelpers.getTranslation(TrKeys.takeAway),
                            desc:
                                '${AppHelpers.getTranslation(TrKeys.approximateTime)} 25 - 30 min',
                            isActive: deliveryState.type == TrKeys.pickup,
                            onTap: () => deliveryEvent.setType(TrKeys.pickup),
                          ),
                          8.verticalSpace,
                          DeliveryTypeItem(
                            iconData: Icons.table_restaurant,
                            title: AppHelpers.getTranslation(TrKeys.dineIn),
                            desc:
                                '${AppHelpers.getTranslation(TrKeys.approximateTime)} 25 - 30 min',
                            isActive: deliveryState.type == TrKeys.dineIn,
                            onTap: () => deliveryEvent.setType(TrKeys.dineIn),
                          ),
                        ],
                      ),
                    ),
                    10.verticalSpace,
                    if (deliveryState.type == TrKeys.delivery)
                      Container(
                        margin: REdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppStyle.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: REdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          children: [
                            TitleAndIcon(
                              title: AppHelpers.getTranslation(
                                TrKeys.customerInformation,
                              ),
                            ),
                            24.verticalSpace,
                            Consumer(
                              builder: (context, ref, child) {
                                final userState = ref.watch(orderUserProvider);
                                final userNotifier = ref.read(
                                  orderUserProvider.notifier,
                                );
                                ref.listen(orderUserProvider, (p, n) {
                                  if (p?.selectedUser != n.selectedUser) {
                                    _userTextController.text =
                                        n.selectedUser?.phone ?? '';
                                  }
                                });

                                return Column(
                                  children: [
                                    UnderlinedTextField(
                                      label: userState.selectedUser != null
                                          ? AppHelpers.getTranslation(
                                              TrKeys.selectedUser,
                                            )
                                          : AppHelpers.getTranslation(
                                              TrKeys.pleaseSelectAUser,
                                            ),
                                      readOnly: true,
                                      onTap: () async {
                                        await context.pushRoute(
                                          const ManagerSelectUserRoute(),
                                        );
                                      },
                                      textController:
                                          userState.userTextController,
                                      descriptionText:
                                          userState.selectedUser == null
                                          ? null
                                          : userState.selectedUser?.email ?? '',
                                    ),
                                    16.verticalSpace,
                                    if (AppConstants.isSpecificNumberEnabled &&
                                        userState.selectedUser != null)
                                      IntlPhoneField(
                                        disableLengthCheck: !AppConstants
                                            .isNumberLengthAlwaysSame,
                                        onChanged: (phoneNum) {
                                          userNotifier.setPhone(
                                            phoneNum.completeNumber,
                                          );
                                        },
                                        validator: (s) {
                                          if (AppConstants
                                                  .isNumberLengthAlwaysSame &&
                                              (s?.isValidNumber() ?? true)) {
                                            return AppHelpers.getTranslation(
                                              TrKeys.phoneNumberIsNotValid,
                                            );
                                          }
                                          return null;
                                        },
                                        keyboardType: TextInputType.phone,
                                        initialCountryCode:
                                            AppConstants.countryCodeISO,
                                        invalidNumberMessage:
                                            AppHelpers.getTranslation(
                                              TrKeys.phoneNumberIsNotValid,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        showCountryFlag: AppConstants.showFlag,
                                        showDropdownIcon:
                                            AppConstants.showArrowIcon,
                                        autovalidateMode:
                                            AppConstants
                                                .isNumberLengthAlwaysSame
                                            ? AutovalidateMode.onUserInteraction
                                            : AutovalidateMode.disabled,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: InputDecoration(
                                          counterText: '',
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide.merge(
                                              BorderSide(
                                                color:
                                                    AppStyle.differBorderColor,
                                              ),
                                              BorderSide(
                                                color:
                                                    AppStyle.differBorderColor,
                                              ),
                                            ),
                                          ),
                                          errorBorder: UnderlineInputBorder(
                                            borderSide: BorderSide.merge(
                                              BorderSide(
                                                color:
                                                    AppStyle.differBorderColor,
                                              ),
                                              BorderSide(
                                                color:
                                                    AppStyle.differBorderColor,
                                              ),
                                            ),
                                          ),
                                          border: const UnderlineInputBorder(),
                                          focusedErrorBorder:
                                              const UnderlineInputBorder(),
                                          disabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide.merge(
                                              BorderSide(
                                                color:
                                                    AppStyle.differBorderColor,
                                              ),
                                              BorderSide(
                                                color:
                                                    AppStyle.differBorderColor,
                                              ),
                                            ),
                                          ),
                                          focusedBorder:
                                              const UnderlineInputBorder(),
                                        ),
                                      ),
                                    if (!AppConstants.isSpecificNumberEnabled &&
                                        userState.selectedUser != null)
                                      UnderlinedTextField(
                                        label: TrKeys.phoneNumber,
                                        textController: _userTextController,
                                        onChanged: (value) =>
                                            userNotifier.setPhone(value),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    if (deliveryState.type == TrKeys.delivery)
                      Container(
                        margin: REdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppStyle.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.r),
                            bottomRight: Radius.circular(10.r),
                          ),
                        ),
                        padding: REdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final addressEvent = ref.read(
                              orderAddressProvider.notifier,
                            );
                            final addressState = ref.watch(
                              orderAddressProvider,
                            );
                            return Column(
                              children: [
                                TitleAndIcon(
                                  title: AppHelpers.getTranslation(
                                    TrKeys.shippingAddress,
                                  ),
                                ),
                                24.verticalSpace,
                                Row(
                                  children: [
                                    Expanded(
                                      child: UnderlinedTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.selectedAddress,
                                        ),
                                        textController:
                                            addressState.textController,
                                        readOnly: true,
                                      ),
                                    ),
                                    10.horizontalSpace,
                                    ButtonsBouncingEffect(
                                      child: GestureDetector(
                                        // 689's map-pin: /select-address
                                        // — into the planes when hosted.
                                        onTap: () => _selectAddress(context),
                                        child: Container(
                                          width: 40.r,
                                          height: 40.r,
                                          // Not const: AppStyle.primary is
                                          // a getter (brand-injectable).
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppStyle.primary,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Remix.map_pin_add_fill,
                                            size: 24.r,
                                            color: AppStyle.blackColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                24.verticalSpace,
                                Row(
                                  children: [
                                    Expanded(
                                      child: UnderlinedTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.entrance,
                                        ),
                                        onChanged: addressEvent.setEntrance,
                                      ),
                                    ),
                                    8.horizontalSpace,
                                    Expanded(
                                      child: UnderlinedTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.floor,
                                        ),
                                        onChanged: addressEvent.setFloor,
                                      ),
                                    ),
                                    8.horizontalSpace,
                                    Expanded(
                                      child: UnderlinedTextField(
                                        label: AppHelpers.getTranslation(
                                          TrKeys.house,
                                        ),
                                        onChanged: addressEvent.setHouse,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (deliveryState.type == TrKeys.dineIn)
                      Consumer(
                        builder: (context, ref, child) {
                          final state = ref.watch(sectionProvider);
                          final tableState = ref.watch(tableProvider);
                          return Container(
                            margin: REdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppStyle.white,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            padding: REdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: Column(
                              children: [
                                TitleAndIcon(
                                  title: AppHelpers.getTranslation(
                                    TrKeys.selectTable,
                                  ),
                                ),
                                16.verticalSpace,
                                UnderlinedTextField(
                                  label: state.selectSection != null
                                      ? AppHelpers.getTranslation(
                                          TrKeys.selectedSection,
                                        )
                                      : AppHelpers.getTranslation(
                                          TrKeys.pleaseSelectASection,
                                        ),
                                  readOnly: true,
                                  onTap: () => context.pushRoute(
                                    const ManagerSelectSectionRoute(),
                                  ),
                                  textController: state.textController,
                                  descriptionText: state.selectSection == null
                                      ? null
                                      : state
                                                .selectSection
                                                ?.translation
                                                ?.description ??
                                            '',
                                ),
                                4.verticalSpace,
                                UnderlinedTextField(
                                  label: tableState.selectTable != null
                                      ? AppHelpers.getTranslation(
                                          TrKeys.selectedTable,
                                        )
                                      : AppHelpers.getTranslation(
                                          TrKeys.pleaseSelectATable,
                                        ),
                                  readOnly: true,
                                  onTap: () {
                                    if (state.selectSection == null) return;
                                    context.pushRoute(
                                      ManagerSelectTableRoute(
                                        sectionId: state.selectSection?.id,
                                      ),
                                    );
                                  },
                                  textController: tableState.textController,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    // Room under the last card for the floating row on
                    // the phone route; the hosted pane docks Next below.
                    SizedBox(height: hosted ? 24.h : 120.h),
                  ],
                ),
              ),
            );
          },
        );
  }
}
