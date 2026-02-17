import 'dart:async';
import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:driver/presentation/app_assets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/domain/di/dependency_manager.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/presentation/component/loading.dart';
import 'package:driver/presentation/pages/pages.dart';
import 'package:workmanager/workmanager.dart';
import 'package:driver/application/providers.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/main.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/routes/app_router.gr.dart';
import 'package:driver/presentation/styles/style.dart';
import 'bottom_sheet_screen.dart';
import 'delivery_bottom_sheet.dart';
import 'parcel_bottom_sheet.dart';

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
  LatLng latLng = LatLng(
    (LocalStorage.getAddressSelected()?.latitude ?? AppConstants.demoLatitude),
    (LocalStorage.getAddressSelected()?.longitude ??
        AppConstants.demoLongitude),
  );
  Position? currentLocation;
  dynamic check;
  final _delayed = Delayed(milliseconds: 36000);

  Future<void> setCustomMarkerIcon() async {
    final Uint8List markerMyIcon = await AppHelpers.svgToPng(
      Assets.svgMyLocation,
    );
    myIcon = BitmapDescriptor.bytes(markerMyIcon);
  }

  Future<void> checkPermission() async {
    FirebaseMessaging.instance.requestPermission(
      sound: true,
      alert: true,
      badge: false,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("New notification on message: ${jsonEncode(message.data)}");
      if (message.data["id"] != null && mounted) {
        AppHelpers.showCheckTopSnackBarInfo(
          context,
          "${message.notification?.body}",
        );
      }
      if (message.data["type"] == "new_order") {
        final res = await orderRepository.showOrders(
          int.tryParse(message.data["id"].toString()) ?? 0,
        );
        res.when(
          success: (s) {
            attachOrder(s.data);
          },
          failure: (f, s) {},
        );
      } else if (message.data["type"] == "deliveryman") {
        final res = await orderRepository.showOrders(
          int.tryParse(message.data["id"].toString()) ?? 0,
        );
        res.when(
          success: (s) {
            newOrder(s.data);
          },
          failure: (f, s) {},
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint("New notification oped app: ${jsonEncode(message.data)}");

      if (message.data["type"] == "new_order") {
        final res = await orderRepository.showOrders(
          int.tryParse(message.data["id"].toString()) ?? 0,
        );
        res.when(
          success: (s) {
            attachOrder(s.data);
          },
          failure: (f, s) {},
        );
      } else if (message.data["type"] == "deliveryman") {
        final res = await orderRepository.showOrders(
          int.tryParse(message.data["id"].toString()) ?? 0,
        );
        res.when(
          success: (s) {
            newOrder(s.data);
          },
          failure: (f, s) {},
        );
      }
    });

    check = await _geolocatorPlatform.checkPermission();
    if (check == LocationPermission.denied) {
      check = await Geolocator.requestPermission();
      if (check != LocationPermission.denied &&
          check != LocationPermission.deniedForever) {
        var loc = await Geolocator.getCurrentPosition();
        latLng = LatLng(loc.latitude, loc.longitude);
        LocalStorage.setAddressSelected(latLng);
        googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    } else {
      if (check != LocationPermission.deniedForever) {
        var loc = await Geolocator.getCurrentPosition();
        latLng = LatLng(loc.latitude, loc.longitude);
        LocalStorage.setAddressSelected(latLng);
        googleMapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    }
  }

  Future<void> getMyLocation() async {
    try {
      check = await _geolocatorPlatform.checkPermission();
      if (check == LocationPermission.denied ||
          check == LocationPermission.deniedForever) {
        check = await Geolocator.requestPermission();
        if (check != LocationPermission.denied &&
            check != LocationPermission.deniedForever) {
          var loc = await Geolocator.getCurrentPosition(
            // ignore: deprecated_member_use
            timeLimit: Duration(seconds: 1),
          );
          latLng = LatLng(loc.latitude, loc.longitude);
          LocalStorage.setAddressSelected(latLng);
          googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 15),
          );
        }
      } else {
        if (check != LocationPermission.deniedForever) {
          var loc = await Geolocator.getCurrentPosition(
            // ignore: deprecated_member_use
            timeLimit: Duration(seconds: 1),
          );
          latLng = LatLng(loc.latitude, loc.longitude);
          LocalStorage.setAddressSelected(latLng);
          googleMapController!.animateCamera(
            CameraUpdate.newLatLngZoom(latLng, 15),
          );
        }
      }
    } catch (e) {
      var loc = await Geolocator.getLastKnownPosition();
      latLng = LatLng(loc?.latitude ?? 0, loc?.longitude ?? 0);
      LocalStorage.setAddressSelected(latLng);
      googleMapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    }
  }

  void getSetProgressLocation() {
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      ref
          .read(homeProvider.notifier)
          .getRouting(
            context: context,
            start: latLng,
            isOnline: (LocalStorage.getOnline()),
          );
    });
  }

  void getCurrentLocation() async {
    getSetProgressLocation();
    _geolocatorPlatform.getCurrentPosition().then((location) {
      currentLocation = location;
      latLng = LatLng(
        currentLocation?.latitude ?? latLng.latitude,
        currentLocation?.longitude ?? latLng.longitude,
      );
    });
    _geolocatorPlatform.getPositionStream().listen((newLoc) {
      currentLocation = newLoc;
      latLng = LatLng(
        currentLocation?.latitude ?? latLng.latitude,
        currentLocation?.longitude ?? latLng.longitude,
      );
      _delayed.run(() {
        LocalStorage.setAddressSelected(
          LatLng(
            currentLocation?.latitude ?? latLng.latitude,
            currentLocation?.longitude ?? latLng.longitude,
          ),
        );
      });
    });
  }

  Future<void> attachOrder(OrderDetailData? push) async {
    AppHelpers.showAlertDialog(
      context: context,
      child: PushOrder(pushModel: push ?? OrderDetailData(), isActive: false),
    );
    final ImageCropperMarker image = ImageCropperMarker();
    ref
        .read(homeProvider.notifier)
        .goMarket(
          context: context,
          orderId: (push?.id ?? 0).toString(),
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
      ref
          .read(profileSettingsProvider.notifier)
          .fetchProfileStatistics(context: context);
      ref
          .read(profileSettingsProvider.notifier)
          .fetchRequestResponse(context: context);
      ref.read(homeProvider.notifier).fetchCurrentOrder(context);
      ref.read(orderProvider.notifier).fetchActiveOrders(context);
    });
    if (LocalStorage.getOnline()) {
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
                    : BottomSheetScreen(isScrolling: state.isScrolling),
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
                        tag: AppConstants.heroTagProfileAvatar,
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
                  top: MediaQuery.paddingOf(context).top + 80.h,
                  left: state.isScrolling ? -64.w : 12.w,
                  child: ButtonsBouncingEffect(
                    child: Consumer(
                      builder: (context, ref, child) {
                        ref.watch(profileImageProvider);
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Style.primary,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              margin: EdgeInsets.all(8.r),
                              child: IconButton(
                                onPressed: () =>
                                    context.pushRoute(const OrdersRoute()),
                                icon: const Icon(
                                  FlutterRemix.history_fill,
                                  color: Style.white,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2.r,
                              right: 8.r,
                              child: Text(
                                ref
                                    .watch(orderProvider)
                                    .totalActiveOrder
                                    .toString(),
                                style: Style.interBold(
                                  color: Style.black,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  top: MediaQuery.paddingOf(context).top + 10.h,
                  right: state.isScrolling ? -120.w : 16.w,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Style.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.all(6.r),
                    child: CustomToggle(
                      isOnline: (LocalStorage.getOnline()),
                      onChange: (bool value) {
                        if (value) {
                          Workmanager().registerPeriodicTask(
                            "${DateTime.now().year}${DateTime.now().day}${DateTime.now().minute}${DateTime.now().second}",
                            fetchBackground,
                            frequency: const Duration(minutes: 10),
                          );
                          getCurrentLocation();
                        } else {
                          timer?.cancel();
                          Workmanager().cancelAll();
                        }
                        ref
                            .read(homeProvider.notifier)
                            .setOnline(context: context);
                      },
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

  Widget _map(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
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
        polygons: ref.watch(homeProvider).polygon,
        polylines:
            ref.watch(homeProvider).isGoRestaurant ||
                ref.watch(homeProvider).isGoUser
            ? {
                Polyline(
                  polylineId: const PolylineId("startLocation"),
                  points: ref.watch(homeProvider).endPolylineCoordinates,
                  color: Style.primary.withValues(alpha: 0.4),
                  width: 6,
                ),
                Polyline(
                  polylineId: const PolylineId("market"),
                  points: ref.watch(homeProvider).polylineCoordinates,
                  color: Style.primary,
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
          if (ref.watch(homeProvider).orderDetail != null) {
            // if (!(LocalStorage.getUser()?.active ?? false)) {
            ref.read(homeProvider.notifier).scrolling(true);
          }
        },
        onTap: (s) {
          ref.read(homeProvider.notifier).scrolling(false);
        },
        onCameraIdle: () {
          _delayed.run(() {
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
    );
  }

  Widget _customLoading(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.zero,
      blur: 1,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        color: Style.white.withValues(alpha: 0.3),
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
        onTap: () async {
          await getMyLocation();
        },
        child: Container(
          width: 50.r,
          height: 50.r,
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: const [
              BoxShadow(
                color: Style.shadowColor,
                blurRadius: 2,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(FlutterRemix.focus_3_fill),
        ),
      ),
    );
  }
}
