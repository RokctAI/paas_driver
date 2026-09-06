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
import 'package:lottie/lottie.dart' as lottie;
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'searched_location_item.dart';
import 'package:${package}/presentation/component/buttons/custom_icon_button.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/address/order/order_address_provider.dart';
import 'package:orders_sdk/src/manager/application/order/shipping/address/select_address_provider.dart';

// SELECT ADDRESS — /select-address, chip 691 (frame 37c): the map
// declares ALL planes and refuses neighbours — full-bleed across the
// whole stage, no seams (the settled 19b/20b ruling; the delivery-zone
// screen rides the same claim). Everything the shipped page has floats on
// it: the search pill the page reverse-geocodes into as the camera moves
// (692), the centre drop pin (693, the Lottie pin), Confirm location (694)
// which writes the pick back into the shipping pane's address field (689)
// and pops, and find-my-location (695). Hosted in the walk-in plane flow,
// [onClose] is the pop — the host's corner Back pill abandons the pick and
// Confirm calls it after writing back; the page draws no pill of its own.
// On the pushed phone route (null, 37d's push chain) Confirm sits at the
// START and the corner Back pill (347) at the END, and Confirm pops the
// route as shipped.
@RoutePage(name: 'ManagerSelectAddressRoute')
class SelectAddressPage extends StatefulWidget {
  /// Hosted in planes: pops this step. Null on the pushed phone route.
  final VoidCallback? onClose;

  const SelectAddressPage({super.key, this.onClose});

  @override
  State<SelectAddressPage> createState() => _SelectAddressPageState();
}

class _SelectAddressPageState extends State<SelectAddressPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  CameraPosition? _cameraPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
  }

  void _close(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    context.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // 691: hosted in the walk-in planes the host owns the corner pill.
    final Planes? planes = Planes.maybeOf(context);
    final bool hosted = planes != null && planes.count > 1;
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: AppStyle.surfaceDark,
        resizeToAvoidBottomInset: false,
        body: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(selectAddressProvider);
            final event = ref.read(selectAddressProvider.notifier);
            return Stack(
              children: [
                GoogleMap(
                  tiltGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                    bearing: 0,
                    target: LatLng(
                      AppHelpers.getInitialLatitude() ??
                          AppConstants.demoLatitude,
                      AppHelpers.getInitialLongitude() ??
                          AppConstants.demoLongitude,
                    ),
                    tilt: 0,
                    zoom: 17,
                  ),
                  onMapCreated: (controller) {
                    event.setMapController(controller);
                  },
                  onCameraMoveStarted: () {
                    _animationController.repeat(
                      min: AppConstants.pinLoadingMin,
                      max: AppConstants.pinLoadingMax,
                      period:
                          _animationController.duration! *
                          (AppConstants.pinLoadingMax -
                              AppConstants.pinLoadingMin),
                    );
                    event.setChoosing(true);
                  },
                  onCameraIdle: () {
                    event.fetchLocationName(_cameraPosition?.target);
                    _animationController.forward(
                      from: AppConstants.pinLoadingMax,
                    );
                    event.setChoosing(false);
                  },
                  onCameraMove: (cameraPosition) {
                    _cameraPosition = cameraPosition;
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 78.0),
                      child: lottie.Lottie.asset(
                        AppAssets.lottiePin,
                        onLoaded: (composition) {
                          _animationController.duration = composition.duration;
                        },
                        controller: _animationController,
                        width: 250,
                        height: 250,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    54.verticalSpace,
                    Container(
                      height: 50.r,
                      padding: REdgeInsets.symmetric(horizontal: 16),
                      margin: REdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: AppStyle.redBg,
                            offset: Offset(0, 2),
                            blurRadius: 2,
                            spreadRadius: 0,
                          ),
                        ],
                        color: AppStyle.white,
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Remix.search_line,
                            size: 20.r,
                            color: AppStyle.icons,
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: TextFormField(
                              controller: state.textController,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 14.sp,
                                color: AppStyle.icons,
                                letterSpacing: -0.5,
                              ),
                              onChanged: (value) {
                                event.setQuery(context);
                              },
                              cursorWidth: 1.r,
                              cursorColor: AppStyle.blackColor,
                              decoration: InputDecoration.collapsed(
                                hintText: AppHelpers.getTranslation(
                                  TrKeys.searchLocation,
                                ),
                                hintStyle: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14.sp,
                                  color: const Color(
                                    0xFFC4C4C4,
                                  ) /* legacy Style.iconColor */,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: event.clearSearchField,
                            splashRadius: 20.r,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Remix.close_line,
                              size: 20.r,
                              color: AppStyle.icons,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isSearching)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: AppStyle.white,
                        ),
                        margin: REdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: REdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: state.searchedPlaces.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            return SearchedLocationItem(
                              place: state.searchedPlaces[index],
                              isLast: state.searchedPlaces.length - 1 == index,
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                event.goToLocation(
                                  place: state.searchedPlaces[index],
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
                // 694: Confirm location — centred on its own when hosted
                // (the host's pill holds the END corner); on the phone
                // route Confirm at the START, the corner Back pill (347)
                // at the END. Slides away while the camera moves, as
                // shipped.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  bottom: state.isChoosing ? -80.r : 16.r,
                  left: 16.r,
                  right: 16.r,
                  child: Builder(
                    builder: (context) {
                      final Widget confirm = Consumer(
                        builder: (context, ref, child) {
                          return CustomButton(
                            title: AppHelpers.getTranslation(
                              TrKeys.confirmLocation,
                            ),
                            onPressed: state.location == null
                                ? null
                                : () {
                                    ref
                                        .read(orderAddressProvider.notifier)
                                        .setLocation(
                                          title:
                                              state.textController?.text ??
                                              '',
                                          location: state.location,
                                        );
                                    _close(context);
                                  },
                          );
                        },
                      );
                      if (hosted) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: confirm,
                          ),
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: confirm),
                          8.horizontalSpace,
                          FloatingBackPill(
                            back: FloatingNavBack(
                              icon: Remix.arrow_left_wide_fill,
                              label: AppHelpers.getTranslation(TrKeys.back),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // 695: find-my-location, riding above the bottom row.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  bottom: 89.r,
                  right: state.isChoosing ? -60.r : 15.r,
                  child: CustomIconButton(
                    iconData: Remix.navigation_fill,
                    size: 60,
                    onTap: event.findMyLocation,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
