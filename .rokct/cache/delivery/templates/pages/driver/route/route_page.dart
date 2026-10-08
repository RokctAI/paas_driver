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

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/application/route/route_provider.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/add_poi_sheet.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/poi_sheet.dart';

import 'package:${package}/presentation/component/maps_list.dart';

/// The driver's numbered, server-ordered route: active order and parcel
/// stops merged with the pending stops of an admin-composed Dispatch
/// Route. The driver just drives stop to stop — the backend decides the
/// order (nearest-next, pickups before their drop-offs) and re-orders
/// after every completion.
///
/// TWO SOURCES, ONE LIST. The toggle at the top switches between the day's
/// work and the round's POINTS OF INTEREST, which the server orders with
/// the same optimiser. It is a source argument on one repository rather
/// than a second page precisely because the driver is doing the same thing
/// with both: reading a numbered list of places and driving to them.
@RoutePage()
class DriverRoutePage extends ConsumerStatefulWidget {
  const DriverRoutePage({super.key});

  @override
  ConsumerState<DriverRoutePage> createState() => _DriverRoutePageState();
}

class _DriverRoutePageState extends ConsumerState<DriverRoutePage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeProvider.notifier).fetchRoute(context);
    });
    super.initState();
  }

  void _showSource(DriverRouteSource source) {
    if (ref.read(routeProvider).source == source) return;
    ref.read(routeProvider.notifier).fetchRoute(context, source: source);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routeProvider);
    return Scaffold(
      // Was the PINNED AppStyle.bgGrey. The stop cards on it carry no
      // explicit ink (AppStyle.interSemi/interRegular default to
      // textPrimary), so page and cards had to move together: fixing only
      // one of the two would have swapped which half was unreadable.
      backgroundColor: AppStyle.surfaceDark,
      body: Stack(
        children: [
          Column(
            children: [
              CustomAppBar(
                bottomPadding: 16.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.myRoute),
                      style: AppStyle.interSemi(size: 18.sp),
                    ),
                    if (state.dispatchRoute != null)
                      Text(
                        "${AppHelpers.getTranslation(state.dispatchRoute?.mode == 'Pickup' ? TrKeys.pickupRoute : TrKeys.deliveryRoute)}"
                        " · ${state.dispatchRoute?.pendingStops ?? 0}/${state.dispatchRoute?.totalStops ?? 0}",
                        style: AppStyle.interRegular(
                          size: 12.sp,
                          letterSpacing: -0.3,
                        ),
                      ),
                    10.verticalSpace,
                    Row(
                      children: [
                        _SourceChip(
                          chipKey: 'routeSourceWork',
                          label: AppHelpers.getTranslation(TrKeys.myRoute),
                          selected: !state.isPoiRoute,
                          onTap: () => _showSource(DriverRouteSource.work),
                        ),
                        8.horizontalSpace,
                        _SourceChip(
                          chipKey: 'routeSourcePois',
                          label: AppHelpers.getTranslation('poi_route'),
                          selected: state.isPoiRoute,
                          onTap: () => _showSource(DriverRouteSource.pois),
                        ),
                        const Spacer(),
                        // FILING A PLACE FROM THE ROUTE, with no load
                        // needed. This page is where a driver looks at the
                        // round he is on, so it is where he notices a
                        // corner that is not on it yet — and the POI route
                        // the chip beside it switches to is the very list
                        // the new point joins. Off a load the sheet asks
                        // which shop; on one it never gets the chance to,
                        // because the load card answers first.
                        //
                        // Built to _SourceChip's own geometry rather than as
                        // a TextButton: this Row lives in a CustomAppBar of
                        // FIXED height, and a Material button's 48dp tap
                        // target would grow it past that.
                        _AddPlaceAction(
                          onTap: () => AddPoiSheet.open(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if ((state.dispatchRoute?.notes ?? '').isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 12.h),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppStyle.cardDark,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.all(12.r),
                    child: Text(
                      state.dispatchRoute?.notes ?? '',
                      style: AppStyle.interRegular(size: 13.sp),
                    ),
                  ),
                ),
              Expanded(
                child: state.isLoading
                    ? const Loading()
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(routeProvider.notifier).fetchRoute(context),
                        child: state.stops.isEmpty
                            ? _emptyRoute(state.isPoiRoute)
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  left: 16.w,
                                  right: 16.w,
                                  top: 16.h,
                                  bottom:
                                      MediaQuery.paddingOf(context).bottom + 72.h,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: state.stops.length,
                                itemBuilder: (context, index) {
                                  return _stopCard(
                                    context,
                                    state.stops[index],
                                    isNext: index == state.nextStopIndex,
                                    isCompleting: state.isCompleting,
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
          // The floating nav's back-only pill (FloatingNavBack, core#125 — design
          // strip section 12's one-back rule): the shared pill housing carrying
          // only the leading back segment, this screen's ONE back affordance,
          // replacing the standalone PopButton. Back-only (empty tab list): the
          // driver app composes no root tab set.
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingBottomNav(
                mode: FloatingNavTabsMode(
                  tabs: const [],
                  currentIndex: 0,
                  onSelect: (_) {},
                  back: FloatingNavBack(
                    icon: Remix.arrow_left_wide_fill,
                    label: AppHelpers.getTranslation(TrKeys.back),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRoute(bool isPoiRoute) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        16.verticalSpace,
        Lottie.asset("assets/lottie/empty-box.json"),
        Text(
          isPoiRoute
              // Nothing filed on this round yet is the normal first day,
              // and it is one sentence: the driver fills it by passing
              // places, not by being told to.
              ? AppHelpers.getTranslation('no_places_on_this_round_yet')
              : AppHelpers.getTranslation(TrKeys.noRouteStops),
          key: const Key('routeEmpty'),
          style: AppStyle.interSemi(size: 18.sp),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _stopCard(
    BuildContext context,
    RouteStopData stop, {
    required bool isNext,
    required bool isCompleting,
  }) {
    final isDone = !stop.isPending;
    return GestureDetector(
      onTap: () => _openStop(context, stop),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(10.r),
          border: isNext
              ? Border.all(color: AppStyle.primary, width: 2.r)
              : null,
        ),
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppStyle.unselectedTab
                        : (isNext ? AppStyle.primary : AppStyle.black),
                  ),
                  child: Text(
                    "${stop.sequence ?? ''}",
                    style: AppStyle.interBold(
                      size: 14,
                      color: isNext && !isDone
                          ? AppStyle.black
                          : AppStyle.white,
                    ),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.label ?? stop.refName ?? '',
                        style: AppStyle.interSemi(size: 14.sp),
                      ),
                      4.verticalSpace,
                      Row(
                        children: [
                          Icon(
                            stop.stopType == 'pickup'
                                ? Remix.store_2_line
                                : Remix.map_pin_2_line,
                            size: 14.sp,
                            color: AppStyle.textGrey,
                          ),
                          4.horizontalSpace,
                          Text(
                            AppHelpers.getTranslation(stop.stopType ?? ''),
                            style: AppStyle.interRegular(
                              size: 12.sp,
                              color: AppStyle.textGrey,
                            ),
                          ),
                          if (stop.distanceFromPreviousKm != null) ...[
                            8.horizontalSpace,
                            Icon(
                              Remix.route_line,
                              size: 14.sp,
                              color: AppStyle.textGrey,
                            ),
                            4.horizontalSpace,
                            Text(
                              "${stop.distanceFromPreviousKm} ${AppHelpers.getTranslation(TrKeys.km)}",
                              style: AppStyle.interRegular(
                                size: 12.sp,
                                color: AppStyle.textGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (stop.hasCoordinates)
                  Icon(
                    Remix.navigation_fill,
                    size: 18.sp,
                    color: AppStyle.primary,
                  ),
              ],
            ),
            if (stop.quantity != null) ...[
              10.verticalSpace,
              Row(
                children: [
                  Icon(Remix.drop_fill, size: 16.sp, color: AppStyle.primary),
                  6.horizontalSpace,
                  Text(
                    "${AppHelpers.getTranslation(TrKeys.quantity)}: ${stop.quantity} ${stop.unit ?? ''}",
                    style: AppStyle.interSemi(size: 13.sp),
                  ),
                ],
              ),
            ],
            if ((stop.paymentTag ?? '').toLowerCase() == 'cash') ...[
              8.verticalSpace,
              Row(
                children: [
                  Icon(
                    Remix.money_dollar_circle_fill,
                    size: 16.sp,
                    color: AppStyle.primary,
                  ),
                  6.horizontalSpace,
                  Text(
                    "${AppHelpers.getTranslation(TrKeys.cashToCollect)}${stop.totalPrice != null ? ": ${AppHelpers.numberFormat(number: stop.totalPrice)}" : ""}",
                    style: AppStyle.interSemi(
                      size: 13.sp,
                      color: AppStyle.primary,
                    ),
                  ),
                ],
              ),
            ],
            if (stop.missingCoordinates) ...[
              8.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.noLocationForStop),
                style: AppStyle.interRegular(
                  size: 12.sp,
                  color: AppStyle.textGrey,
                ),
              ),
            ],
            if (stop.isDispatchStop && stop.isPending) ...[
              12.verticalSpace,
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: isCompleting
                          ? null
                          : () => _completeStop(context, stop, 'Done'),
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.done),
                        style: AppStyle.interSemi(
                          size: 13.sp,
                          // NOT textPrimary: this label's ground is the
                          // button's own AppStyle.primary, not the card, and
                          // black on orange is the fleet's pairing (it is
                          // CustomButton's textColor default too). Resolving
                          // it would put white on orange - 2.94:1, WORSE than
                          // the 4.91:1 it has. The Skip button beside it does
                          // sit on the card, so that one does resolve.
                          color: AppStyle.black,
                        ),
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: isCompleting
                          ? null
                          : () => _completeStop(context, stop, 'Skipped'),
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.skip),
                        style: AppStyle.interSemi(
                          size: 13.sp,
                          color: AppStyle.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _completeStop(BuildContext context, RouteStopData stop, String status) {
    final routeId = stop.routeId;
    final stopName = stop.refName;
    if (routeId == null || stopName == null) return;
    ref
        .read(routeProvider.notifier)
        .completeStop(
          context,
          routeId: routeId,
          stopName: stopName,
          status: status,
        );
  }

  /// A POI stop opens the PLACE — what was filed and what has been sold
  /// there — because that is what the driver needs before he knocks. Every
  /// other stop opens the maps chooser, which is what he needs to get to
  /// it.
  void _openStop(BuildContext context, RouteStopData stop) {
    if (stop.refDoctype == 'Point Of Interest' && stop.refName != null) {
      PoiSheet.open(context, _poiOf(stop));
      return;
    }
    _openInMaps(context, stop);
  }

  /// The stop's own point, rebuilt from the row the route already carries,
  /// so opening the sheet costs no extra read.
  DriverPoi _poiOf(RouteStopData stop) => DriverPoi(
        id: stop.refName ?? '',
        label: stop.label,
        type: stop.meta['type']?.toString(),
        customType: stop.meta['custom_type']?.toString(),
        typeLabel: stop.meta['type_label']?.toString(),
        latitude: stop.latitude,
        longitude: stop.longitude,
        address: stop.meta['address']?.toString(),
        note: stop.meta['note']?.toString(),
        shopId: stop.meta['shop']?.toString(),
      );

  void _openInMaps(BuildContext context, RouteStopData stop) {
    if (!stop.hasCoordinates) return;
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 16.h),
          child: MapsList(
            location: Coords(stop.latitude ?? 0, stop.longitude ?? 0),
            title: stop.label ?? '',
          ),
        ),
      ),
      isDarkMode: false,
    );
  }
}

/// One source chip in the route header.
/// "ADD A PLACE" on the route header, in the source chips' own shape.
class _AddPlaceAction extends StatelessWidget {
  const _AddPlaceAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppStyle.cardDarkAlt,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        key: const Key('routeAddPlace'),
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Remix.map_pin_line,
                size: 14.r,
                color: AppStyle.primary,
              ),
              6.horizontalSpace,
              Text(
                AppHelpers.getTranslation('add_a_place'),
                style: AppStyle.interSemi(
                  size: 12.sp,
                  color: AppStyle.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String chipKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppStyle.primary : AppStyle.cardDarkAlt,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        key: Key(chipKey),
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          child: Text(
            label,
            style: AppStyle.interSemi(
              size: 12.sp,
              // Black on the chip's own AppStyle.primary ground, the
              // fleet's pairing; the unselected chip sits on the card and
              // takes the resolved ink.
              color: selected ? AppStyle.black : AppStyle.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
