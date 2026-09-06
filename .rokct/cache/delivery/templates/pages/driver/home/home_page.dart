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

import 'dart:async';
import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:comms_sdk/comms_sdk.dart' show PushPermissionService;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_sdk/src/driver/application/order/order_provider.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_flow.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_root_nav.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/deferred_map_surface.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:${package}/presentation/pages/home/parcel_bottom_sheet.dart';

import 'package:workmanager/workmanager.dart';

// fetchBackground (the periodic courier-location task id) lives in
// delivery_sdk since driver migration M4 — the generated main.dart no longer
// declares it (the dispatcher is wired by this manifest's boot_hooks entry).
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_service.dart';

import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/pages/home/bottom_sheet_screen.dart';
import 'package:${package}/presentation/pages/home/delivery_bottom_sheet.dart';
import 'package:${package}/presentation/component/buttons/buttons_bouncing_effect.dart';
import 'package:${package}/presentation/component/custom_toggle.dart';
import 'package:${package}/presentation/component/driver_avatar.dart';
import 'package:${package}/presentation/pages/push_order/push_order_screen.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';
import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/marker_image_cropper.dart';
import 'package:base_sdk/src/services/tpying_delay.dart';
import 'package:delivery_sdk/src/driver/application/driver/driver_provider.dart';
import 'package:delivery_sdk/src/driver/application/home/home_provider.dart';
import 'package:${package}/presentation/pages/profile/courier_statistics_provider.dart';
import 'package:delivery_sdk/src/driver/application/profile/provider/profile_image_provider.dart';
import 'package:delivery_sdk/src/driver/application/profile/provider/profile_settings_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_constants.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_helpers.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final bool isLtr = LocalStorage.getLangLtr();
  GoogleMapController? googleMapController;
  BitmapDescriptor myIcon = BitmapDescriptor.defaultMarker;
  OrderDetailData? push;
  Timer? timer;

  /// The on-duty position stream (see [getCurrentLocation]). Held so the
  /// duty toggle and [dispose] can cancel it: un-held, every toggle to
  /// online stacked another listener that kept writing [latLng] and the
  /// stored address for the life of the isolate, page or no page.
  StreamSubscription<Position>? _positionSub;
  LatLng latLng = LatLng(
    (LocalStorage.getAddressSelected()?.latitude ?? AppConstants.demoLatitude),
    (LocalStorage.getAddressSelected()?.longitude ??
        AppConstants.demoLongitude),
  );
  Position? currentLocation;
  final _delayed = Delayed(milliseconds: 36000);

  /// De-duplicates the two un-awaited calls initState makes (see
  /// [getMyLocation]).
  Future<void>? _locationRequest;

  /// Set once the driver has been told, in one friendly line, that the app
  /// has no fix; cleared the moment one arrives, so a later refusal is
  /// reported afresh instead of going silent forever.
  bool _locationRefusalReported = false;

  Future<void> setCustomMarkerIcon() async {
    final Uint8List markerMyIcon = await CourierHelpers.getBytesFromAsset(
      AppAssets.pngMyLocation,
      120,
    );
    myIcon = BitmapDescriptor.fromBytes(markerMyIcon);
  }

  checkPermission() async {
    // firebase_messaging has no Windows/Linux implementation — on desktop
    // Firebase is (correctly) never initialized, so an unguarded
    // FirebaseMessaging.instance throws [core/no-app]. Same platform guard +
    // fail-open idiom as comms' firebase boot hook (defensive: driver is
    // mobile-only today, but this matches the merchants main-page fix).
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        // comms_sdk owns the OS notification prompt for every composition
        // (comms_sdk >= 1.15.0). PushPermissionService keeps this call site's
        // platform guard + fail-open idiom AND de-duplicates concurrent
        // requests: a second sign-in inside one process re-mounts this page
        // and the platform channel refuses a second in-flight request. The
        // service owns the future, so that failure is caught and logged
        // instead of escaping as an uncaught async error past the try below.
        PushPermissionService.request(
          sound: true,
          alert: true,
          badge: false,
        );

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          debugPrint(
            "New notification on message: ${jsonEncode(message.data)}",
          );
          if (message.data["id"] != null && mounted) {
            AppHelpers.showCheckTopSnackBarInfo(
              context,
              "${message.notification?.body}",
            );
          }
          if (message.data["type"] == "new_order") {
            final res = await orderRepository.showOrders(
              message.data["id"].toString(),
            );
            res.map(
              success: (s) {
                attachOrder(s.data.data);
              },
              failure: (f) {},
            );
          } else if (message.data["type"] == "deliveryman") {
            final res = await orderRepository.showOrders(
              message.data["id"].toString(),
            );
            res.map(
              success: (s) {
                newOrder(s.data.data);
              },
              failure: (f) {},
            );
          }
        });
        FirebaseMessaging.onMessageOpenedApp.listen((
          RemoteMessage message,
        ) async {
          debugPrint("New notification oped app: ${jsonEncode(message.data)}");

          if (message.data["type"] == "new_order") {
            final res = await orderRepository.showOrders(
              message.data["id"].toString(),
            );
            res.map(
              success: (s) {
                attachOrder(s.data.data);
              },
              failure: (f) {},
            );
          } else if (message.data["type"] == "deliveryman") {
            final res = await orderRepository.showOrders(
              message.data["id"].toString(),
            );
            res.map(
              success: (s) {
                newOrder(s.data.data);
              },
              failure: (f) {},
            );
          }
        });
      } catch (e) {
        debugPrint('==> driver home FCM setup skipped: $e');
      }
    }

    await getMyLocation();
  }

  /// Puts the map on the courier's own position — or leaves it on the
  /// fallback [latLng] and says so, once, in one friendly line.
  ///
  /// The permission dance and the fix call live in delivery_sdk's
  /// [CourierLocationFix], which never throws: a driver with no location
  /// permission is a normal state, not a crash. This page previously
  /// inlined that logic twice and let `PermissionDeniedException` escape
  /// (paas_driver tour 33623262696) — `initState` fires `checkPermission()`
  /// and this method without awaiting either, so this one ran with `check`
  /// still null, skipped both denial branches and asked for a fix having
  /// requested nothing. Android refused the call outright, and the throw
  /// escaped an un-awaited future and took the whole home page down.
  ///
  /// The two initState calls now share one in-flight future, so the driver
  /// is asked for permission once rather than by two callers racing the
  /// platform channel.
  Future<void> getMyLocation() {
    return _locationRequest ??= _acquireLocation().whenComplete(() {
      _locationRequest = null;
    });
  }

  Future<void> _acquireLocation() async {
    final result = await CourierLocationFix().current();

    if (!result.hasFix) {
      // Reported, never swallowed: one friendly translated line for the
      // driver, the verbatim platform detail to admins via telemetry
      // (delivery/dart CHANGELOG 1.17.4; decision-log entry 56).
      if (_locationRefusalReported) return;
      _locationRefusalReported = true;
      if (mounted) {
        CourierLocationNotice.show(context, result);
      } else {
        // Page gone while the platform call was in flight — nobody left to
        // show a line to, but admins still get the detail.
        CourierLocationNotice.report(result);
      }
      return;
    }

    _locationRefusalReported = false;
    final position = result.position!;
    latLng = LatLng(position.latitude, position.longitude);
    // A pinned fix already is the stored address (or the anchor when none
    // is stored) — see [CourierLocationFix.pinnedBuild]; only a measured
    // one is worth remembering.
    if (!result.pinned) CourierStorage.saveSelectedLocation(latLng);
    await _moveCamera(latLng);
  }

  /// Puts the map on [target] - or does nothing, quietly, when there is no
  /// live map to move.
  ///
  /// Two ways for there to be none. initState calls [getMyLocation] before
  /// the GoogleMap widget has handed over its controller (`null` here, so
  /// no `!`). And the page can be gone by the time the fix lands: the
  /// guided tour signs the demo courier in (which lands on /home), walks
  /// the auth screens and routes to /home again, so the first HomePage is
  /// disposed with its location request still in flight. When that fix
  /// finally arrived (paas_driver tour 33911125552, phone leg) the
  /// controller it kept was non-null but its platform view was already
  /// torn down, and `animateCamera` threw
  /// `PlatformException(channel-error, Unable to establish connection on
  /// channel: ...MapsApi.animateCamera)` out of an un-awaited future and
  /// took the whole tour down. Hence `mounted` first, and the platform
  /// call itself inside a catch: a map that is not there is a normal
  /// state on this page, not a crash.
  Future<void> _moveCamera(LatLng target) async {
    if (!mounted) return;
    final controller = googleMapController;
    if (controller == null) return;
    try {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
    } on PlatformException catch (e) {
      debugPrint('==> driver home: map camera move skipped: ${e.code}');
    }
  }

  void getSetProgressLocation() {
    // One poll at a time: initState (already online) and the duty toggle
    // both start this lane, and a replaced Timer would otherwise run on,
    // unreachable, for the life of the isolate.
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      // The poll is a Timer, not a widget: nothing stops it for us when the
      // page goes. Without this guard it fired `ref.read` on a disposed
      // element ten seconds after the tour had routed on to /orders -
      // "Bad state: Cannot use "ref" after the widget was disposed"
      // (paas_driver tour 33911125552, tablet leg). [dispose] cancels it
      // too; this is the belt to that brace.
      if (!mounted) {
        t.cancel();
        return;
      }
      ref
          .read(homeProvider.notifier)
          .getRouting(
            context: context,
            start: latLng,
            isOnline: (CourierStorage.getOnline()),
          );
    });
  }

  /// The on-duty tracking lane, started only while the courier is online.
  ///
  /// Same denial hazard as [getMyLocation]: both of these are un-awaited, so
  /// a refusal here surfaces as an unhandled async error rather than
  /// anything a driver could act on. Neither has a screen to fail to — they
  /// only refresh [latLng], which already holds a usable fallback — so the
  /// refusal goes to telemetry and tracking simply produces nothing.
  void getCurrentLocation() async {
    getSetProgressLocation();
    // A pinned build has no live courier to follow: the routing poll runs
    // from [latLng] as it stands, and the platform is never asked — its
    // fix would only overwrite the stored address the seed laid out
    // (see [CourierLocationFix.pinnedBuild]).
    if (CourierLocationFix.pinnedBuild) return;
    _geolocatorPlatform.getCurrentPosition().then((location) {
      currentLocation = location;
      latLng = LatLng(
        currentLocation?.latitude ?? latLng.latitude,
        currentLocation?.longitude ?? latLng.longitude,
      );
    }, onError: _reportTrackingRefusal);
    // One listener at a time, for the same reason [getSetProgressLocation]
    // keeps one Timer.
    _positionSub?.cancel();
    _positionSub = _geolocatorPlatform.getPositionStream().listen((newLoc) {
      currentLocation = newLoc;
      latLng = LatLng(
        currentLocation?.latitude ?? latLng.latitude,
        currentLocation?.longitude ?? latLng.longitude,
      );
      _delayed.run(() {
        if (!mounted) return;
        CourierStorage.saveSelectedLocation(
          LatLng(
            currentLocation?.latitude ?? latLng.latitude,
            currentLocation?.longitude ?? latLng.longitude,
          ),
        );
      });
    }, onError: _reportTrackingRefusal);
  }

  /// Stops the on-duty lane: the routing poll and the position stream.
  /// Shared by the duty toggle's OFF path and [dispose], so going off duty
  /// and leaving the page release exactly the same things.
  void _stopTracking() {
    timer?.cancel();
    timer = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Telemetry-only: the on-duty lane has no line to show that the friendly
  /// line from [getMyLocation] has not already said.
  void _reportTrackingRefusal(Object error) {
    CourierLocationNotice.report(
      CourierLocationResult.unavailable(
        denial: error is PermissionDeniedException
            ? CourierLocationDenial.permissionDenied
            : CourierLocationDenial.lookupFailed,
        detail: '$error',
      ),
    );
  }

  Future<void> attachOrder(OrderDetailData? push) async {
    AppHelpers.showAlertDialog(
      context: context,
      child: PushOrder(pushModel: push ?? OrderDetailData(), isActive: false),
    );
    final ImageCropperForMarker image = ImageCropperForMarker();
    ref
        .read(homeProvider.notifier)
        .goMarket(
          context: context,
          orderId: push?.id,
          order: push,
          onSuccess: () async {
            ref
                .read(homeProvider.notifier)
                .getRoutingAll(
                  // ignore: use_build_context_synchronously
                  context: context,
                  start: LatLng(
                    LocalStorage.getAddressSelected()?.latitude ??
                        AppConstants.demoLatitude,
                    LocalStorage.getAddressSelected()?.longitude ??
                        AppConstants.demoLongitude,
                  ),
                  end: LatLng(
                    double.parse(push?.shop?.location?.latitude ?? "0"),
                    double.parse(push?.shop?.location?.longitude ?? "0"),
                  ),
                  market: Marker(
                    markerId: const MarkerId("Shop"),
                    position: LatLng(
                      double.parse(push?.shop?.location?.latitude ?? "0"),
                      double.parse(push?.shop?.location?.longitude ?? "0"),
                    ),
                    icon: await image.resizeAndCircle(
                      push?.shop?.logoImg ?? "",
                      120,
                    ),
                  ),
                );
          },
        );
  }

  Future<void> newOrder(OrderDetailData? push) async {
    AppHelpers.showAlertDialog(
      context: context,
      child: PushOrder(pushModel: push ?? OrderDetailData(), isActive: true),
    );
  }

  @override
  void initState() {
    checkPermission();
    setCustomMarkerIcon();
    getMyLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // deliveryman settings fetch moved here from the retired host splash
      // (base_sdk's splash is courier-agnostic).
      ref.read(driverProvider.notifier).fetchDriverDetails(context: context);
      ref
          .read(courierProfileStatisticsProvider.notifier)
          .fetchProfileStatistics(context: context);
      ref
          .read(profileSettingsProvider.notifier)
          .fetchRequestResponse(context: context);
      ref.read(homeProvider.notifier).fetchCurrentOrder(context);
      ref.read(orderProvider.notifier).fetchActiveOrders(context);
    });
    if (CourierStorage.getOnline()) {
      Workmanager().registerPeriodicTask(
        "${DateTime.now().year}${DateTime.now().day}${DateTime.now().minute}${DateTime.now().second}",
        fetchBackground,
        frequency: const Duration(minutes: 10),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getCurrentLocation();
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    // The 10-second routing poll outlived this page (see
    // [getSetProgressLocation]), and so did the position stream (see
    // [_positionSub]); the toggle's OFF path releases both, leaving the
    // page must too.
    _stopTracking();
    // The controller dies with the GoogleMap platform view. Drop it so a
    // location fix that lands after this point finds nothing to move (see
    // [_moveCamera]); the GoogleMap widget disposes the controller itself.
    googleMapController = null;
    // [_delayed] (base_sdk's Delayed) exposes no cancel, so its pending
    // 36-second callback may still fire after this point; every callback
    // handed to it therefore checks [mounted] before touching `ref`.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        body: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(homeProvider);
            return Stack(
              children: [
                _map(context, ref),
                state.isGoRestaurant || state.isGoUser
                    ? state.parcelDetail == null
                          ? DeliverBottomSheetScreen(
                              order:
                                  push ??
                                  (state.orderDetail ?? OrderDetailData()),
                            )
                          : ParcelBottomSheetScreen(parcel: state.parcelDetail)
                    : BottomSheetScreen(
                        isScrolling: state.isScrolling,
                        // Top up (chip 970) starts the deposit route,
                        // frames 49g -> 49h -> 49i, inside delivery_sdk.
                        onTopUp: () => DriverDepositFlow.openChooser(context, ref),
                        // The wallet lives in revenue_sdk; delivery_sdk
                        // imports only base_sdk, so the destination is
                        // supplied by the host here rather than routed
                        // inside the sheet. DriverIncomeRoute is the
                        // surface the driver's money already lives on
                        // (profile_page.dart uses the same route).
                        onOpenWallet: () =>
                            context.pushRoute(const DriverIncomeRoute()),
                      ),
                state.isGoRestaurant || state.isGoUser
                    ? const SizedBox.shrink()
                    : _myFindButton(ref),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: MediaQuery.paddingOf(context).top + 10.h,
                  left: state.isScrolling ? -64.w : 16.w,
                  child: ButtonsBouncingEffect(
                    child: GestureDetector(
                      onTap: () => context.pushRoute(const ProfileRoute()),
                      child: Hero(
                        tag: CourierConstants.heroTagProfileAvatar,
                        child: Consumer(
                          builder: (context, ref, child) {
                            ref.watch(profileImageProvider);
                            return DriverAvatar(
                              imageUrl: LocalStorage.getUser()?.img,
                              rate: LocalStorage.getUser()?.rate,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: MediaQuery.paddingOf(context).top + 10.h,
                  right: state.isScrolling ? -120.w : 16.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppStyle.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.all(6.r),
                    child: CustomToggle(
                      isOnline: (CourierStorage.getOnline()),
                      onChange: (bool value) {
                        if (value) {
                          Workmanager().registerPeriodicTask(
                            "${DateTime.now().year}${DateTime.now().day}${DateTime.now().minute}${DateTime.now().second}",
                            fetchBackground,
                            frequency: const Duration(minutes: 10),
                          );
                          getCurrentLocation();
                        } else {
                          _stopTracking();
                          Workmanager().cancelAll();
                        }
                        ref
                            .read(homeProvider.notifier)
                            .setOnline(context: context);
                      },
                    ),
                  ),
                ),
                // CHIP 301 — the driver root tab set, mounted the way every
                // sibling page mounts the pill (a full-size slot under a
                // bottom-centre Align, so a tablet-mode rail could self-
                // place if the app ever opted in). It replaces the two
                // free-floating icon buttons that used to sit down the left
                // edge (order history with a count, route): both are tabs
                // now, and the frames draw no such buttons. Home is lit
                // while the driver idles (49a/49d/49e) and JOBS while he is
                // inside a job (49c). The pill is the app's spine and does
                // not tuck away with the sheet when the map is dragged —
                // "the tab set is the app's spine and is not what yields"
                // (49e). It sits above the sheets and below the loading
                // veil.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: DriverRootNav(
                      current: state.isGoRestaurant || state.isGoUser
                          ? DriverRootTab.jobs
                          : DriverRootTab.home,
                      onSelect: _openRootTab,
                    ),
                  ),
                ),
                if (state.isLoading)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    child: _customLoading(context),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// CHIP 301's destinations — every one an EXISTING route; nothing new
  /// is composed for the tab set.
  ///
  ///  * Home — this page. A tap on the lit Home tab has nowhere to go and
  ///    does nothing.
  ///  * Jobs — `OrdersRoute` (/orders): the active + available orders list
  ///    the old left-edge history button opened. It is pushed even while
  ///    Jobs is lit mid-job (frame 49c): the lit tab reads "inside the
  ///    job", but the list is still where a driver with several active
  ///    orders switches between them, and the home sheet is not that list.
  ///  * Route — `DriverRouteRoute` (/driver-route), the stop sequence the
  ///    old left-edge route button opened.
  ///  * Income — revenue_sdk's `DriverIncomeRoute`, the surface the
  ///    driver's money already lives on (chip 970's Open wallet and
  ///    profile_page.dart both use it).
  ///  * Profile — `ProfileRoute` (/profile), the same page the avatar
  ///    opens.
  ///
  /// Pushed, not swapped: the driver app has no root IndexedStack, and
  /// each of these pages already carries the pill's back-only segment
  /// (chip 347's one-back rule) to come home by.
  void _openRootTab(DriverRootTab tab) {
    switch (tab) {
      case DriverRootTab.home:
        return;
      case DriverRootTab.jobs:
        context.pushRoute(const OrdersRoute());
      case DriverRootTab.route:
        context.pushRoute(const DriverRouteRoute());
      case DriverRootTab.income:
        context.pushRoute(const DriverIncomeRoute());
      case DriverRootTab.profile:
        context.pushRoute(const ProfileRoute());
    }
  }

  /// CHIP 942 of design strip section 49, frame 49d — the off-duty veil.
  ///
  /// Off duty is a REAL, PERSISTED, CONSEQUENTIAL state:
  /// `CourierStorage.getOnline()` gates whether the 10-minute
  /// `fetchBackground` location task is registered at all and whether
  /// the 10-second routing poll ever starts. Today the screen looks
  /// IDENTICAL either way, with nothing but a switch position telling a
  /// driver who is working from one who is not.
  ///
  /// Desaturating and dimming the map is the cheapest possible way to
  /// make that legible at a glance, and it is HONEST about what actually
  /// stopped: with the poll cancelled the map genuinely is no longer
  /// live, so it should not look live.
  ///
  /// Applied as a paint-time filter over the shipped GoogleMap rather
  /// than as a map style, deliberately: it needs no style JSON asset, no
  /// controller round-trip, and it cannot get out of step with the
  /// toggle because it is read from the same `getOnline()` the toggle
  /// writes.
  Widget _map(BuildContext context, WidgetRef ref) {
    final map = _mapSurface(context, ref);
    if (CourierStorage.getOnline()) return map;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        // Greyscale luminance, then dimmed to 0.72 — drained, not hidden.
        // The driver must still be able to read where he is.
        0.2126 * 0.72, 0.7152 * 0.72, 0.0722 * 0.72, 0, 0,
        0.2126 * 0.72, 0.7152 * 0.72, 0.0722 * 0.72, 0, 0,
        0.2126 * 0.72, 0.7152 * 0.72, 0.0722 * 0.72, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: map,
    );
  }

  /// The driver's zone, drained to grey while he is off duty.
  Set<Polygon> _zonePolygons(Set<Polygon> polygons) {
    if (CourierStorage.getOnline()) return polygons;
    return polygons
        .map(
          (polygon) => polygon.copyWith(
            strokeColorParam: AppStyle.unselectedBottomItem,
            fillColorParam: AppStyle.unselectedBottomItem.withValues(
              alpha: 0.10,
            ),
          ),
        )
        .toSet();
  }

  /// The GoogleMap is constructed here but MOUNTED only once the page has
  /// settled (see [DeferredMapSurface]): one frame painted, 800 ms of
  /// being the current route, still mounted. The plugin fires its own
  /// un-awaited channel calls the moment its native view connects
  /// (`updateTileOverlays` first), and a page replaced before that point
  /// took the phone tour down (paas_driver tour 34049256577, 4/17 on both
  /// attempts) with a channel-error nothing in this file could catch. The
  /// 1.19.1 mounted guard covers this page's own [_moveCamera]; the
  /// deferral covers the plugin's. Until the map mounts the surface is a
  /// plain box in the theme's surface colour, which is what the map area
  /// shows before the first tiles draw anyway.
  Widget _mapSurface(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      child: DeferredMapSurface(
        child: GoogleMap(
          myLocationButtonEnabled: false,
          initialCameraPosition: CameraPosition(
            bearing: 0,
            target: LatLng(
              (LocalStorage.getAddressSelected()?.latitude ??
                  AppConstants.demoLatitude),
              (LocalStorage.getAddressSelected()?.longitude ??
                  AppConstants.demoLongitude),
            ),
            tilt: 0,
            zoom: 17,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("source"),
              icon: myIcon,
              position: LatLng(
                currentLocation?.latitude ?? latLng.latitude,
                currentLocation?.longitude ?? latLng.longitude,
              ),
            ),
            ...ref.watch(homeProvider).markers,
          },
          // CHIP 942, second half: the zone outline drains to grey off
          // duty. Recoloured here rather than in the notifier so the zone
          // itself stays one source of truth and only its PAINT changes.
          polygons: _zonePolygons(ref.watch(homeProvider).polygon),
          polylines: ref.watch(homeProvider).isGoRestaurant ||
                  ref.watch(homeProvider).isGoUser
              ? {
                  Polyline(
                    polylineId: const PolylineId("startLocation"),
                    points: ref.watch(homeProvider).endPolylineCoordinates,
                    color: AppStyle.primary.withOpacity(0.4),
                    width: 6,
                  ),
                  Polyline(
                    polylineId: const PolylineId("market"),
                    points: ref.watch(homeProvider).polylineCoordinates,
                    color: AppStyle.primary,
                    width: 6,
                  ),
                }
              : {},
          mapToolbarEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            googleMapController = controller;
          },
          onCameraMoveStarted: () {
            if (!(LocalStorage.getUser()?.active ?? false)) {
              ref.read(homeProvider.notifier).scrolling(true);
            }
          },
          onCameraIdle: () {
            // [_delayed] is a 36-second one-shot with no cancel, so it can
            // fire after this page is popped; reading `ref` then throws
            // "Cannot use ref after the widget was disposed" (tablet tour).
            _delayed.run(() {
              if (!mounted) return;
              ref.read(homeProvider.notifier).scrolling(false);
            });
          },
          padding: EdgeInsets.only(
            bottom: ref.watch(homeProvider).isGoRestaurant
                ? 90.h
                : ref.watch(homeProvider).isScrolling
                    ? 60.h
                    : 330.h,
          ),
        ),
      ),
    );
  }

  Widget _customLoading(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.zero,
      blur: 1,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        color: AppStyle.white.withOpacity(0.3),
        child: const Loading(),
      ),
    );
  }

  Widget _myFindButton(WidgetRef ref) {
    return AnimatedPositioned(
      bottom: 342.h,
      right: ref.watch(homeProvider).isScrolling ? -64.w : 16.w,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () async => await getMyLocation(),
        child: Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF7D7D7D),
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Remix.focus_3_fill),
        ),
      ),
    );
  }
}
