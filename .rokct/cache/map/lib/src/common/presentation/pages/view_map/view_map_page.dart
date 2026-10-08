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

// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
//import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/models/data/address_information.dart';
import 'package:base_sdk/src/models/data/address_new_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tpying_delay.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:map_sdk/src/common/presentation/pages/view_map/view_map_modal.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/application/map/view_map_notifier.dart';
import 'package:base_sdk/src/application/map/view_map_provider.dart';
import 'package:map_sdk/src/common/application/poidata/poi_data_provider.dart';
import 'package:map_sdk/src/common/presentation/pages/view_map/poi_markers.dart';
import 'package:map_sdk/src/common/presentation/pages/view_map/poi_read_window.dart';
import 'package:base_sdk/src/models/data/poi_data.dart';
// Imported directly (not via handlers.dart) because ApiResult's `when` is an
// EXTENSION declared in the generated `api_result.freezed.dart` part - it is
// only in scope for a library that imports its defining library.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:lottie/lottie.dart' as lottie;

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:map_sdk/src/common/di/map_di.dart';

@RoutePage()
class ViewMapPage extends ConsumerStatefulWidget {
  final bool isShopLocation;
  final bool isPop;
  final bool isParcel;
  final String? shopId;
  final int? indexAddress;
  final AddressNewModel? address;

  const ViewMapPage({
    super.key,
    this.isParcel = false,
    this.isPop = true,
    this.isShopLocation = false,
    this.shopId,
    this.indexAddress,
    this.address,
  });

  @override
  ConsumerState<ViewMapPage> createState() => _ViewMapPageState();
}

class _ViewMapPageState extends ConsumerState<ViewMapPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
  );
  late ViewMapNotifier event;
  late TextEditingController controller;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  GoogleMapController? googleMapController;
  CameraPosition? cameraPosition;
  dynamic check;
  late LatLng latLng;
  final Delayed delayed = Delayed(milliseconds: 700);
  Set<Marker> markers = {};
  String _nearestPOIInfo = '';

  /// How far from the map centre a stored point is still drawn, and how
  /// wide a slice of them is read from the platform at a time.
  ///
  /// The read is deliberately wider than the draw: the loaded disc is
  /// re-centred only once the map centre has travelled the draw radius, so
  /// a read radius of twice that keeps every point the page could draw
  /// already in hand and a pan inside the loaded area costs no call.
  static const double _poiRadiusMeters = 1000;
  static const double _poiReadRadiusKm = 2 * _poiRadiusMeters / 1000;

  /// The centre the points currently in hand were read around, and whether
  /// a read is in flight (camera moves arrive faster than a round trip).
  LatLng? _poiReadCentre;
  bool _poiReading = false;

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(viewMapProvider.notifier);
    super.didChangeDependencies();
  }

  bool _isPoiInRadius(POIData poi, LatLng location, double radius) {
    final double distance = GeolocatorPlatform.instance.distanceBetween(
      location.latitude,
      location.longitude,
      poi.latitude,
      poi.longitude,
    );
    return distance <= radius;
  }

  POIData? _findNearestPOI(LatLng currentLocation, List<POIData> poiData) {
    POIData? nearestPOI;
    double minDistance = double.infinity;

    for (var poi in poiData) {
      final distance = GeolocatorPlatform.instance.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        poi.latitude,
        poi.longitude,
      );

      if (distance < minDistance && distance <= _poiRadiusMeters) {
        minDistance = distance;
        nearestPOI = poi;
      }
    }

    return nearestPOI;
  }

  /// Reads the stored points of interest around [centre] and hands them to
  /// [poiDataProvider], which is what the markers are drawn from.
  ///
  /// Called once for the centre the page opens on and again whenever the
  /// camera has carried the centre clear of the disc the points in hand
  /// cover; a pan inside that disc, and a move while a read is in flight,
  /// cost nothing. A failed read leaves the points already on screen alone
  /// - blanking a map because one call timed out tells the shopper the area
  /// has no landmarks, which is a different and wrong statement.
  Future<void> _loadPOIData(LatLng centre) async {
    if (_poiReading) return;
    if (!poiReadNeeded(
      loadedCentre: _poiReadCentre,
      centre: centre,
      radiusMeters: _poiRadiusMeters,
    )) {
      return;
    }
    final repository = customerPoisOrNull;
    if (repository == null) return;
    _poiReading = true;
    final response = await repository.getCustomerPois(
      latitude: centre.latitude,
      longitude: centre.longitude,
      radiusKm: _poiReadRadiusKm,
    );
    _poiReading = false;
    if (!mounted) return;
    response.when(
      success: (pois) {
        _poiReadCentre = centre;
        ref.read(poiDataProvider.notifier).updatePOIData(pois);
        _createMarkers();
      },
      failure: (error, statusCode) {
        debugPrint('===> read points of interest failed $statusCode $error');
      },
    );
  }

  Future<void> _createMarkers() async {
    final poiData = ref.read(poiDataProvider);
    // Until the first camera move the centre is the target the map opened
    // on; reading it from `latLng` rather than waiting for a gesture is what
    // lets the points arriving from the first read draw straight away.
    final LatLng centre = cameraPosition?.target ?? latLng;

    final filteredPoiData = poiData
        .where((poi) => _isPoiInRadius(poi, centre, _poiRadiusMeters))
        .toList();

    final markers = await buildPoiMarkers(
      filteredPoiData,
      onTap: (markerId) => googleMapController?.showMarkerInfoWindow(markerId),
    );

    // Find the nearest POI
    final nearestPOI = _findNearestPOI(centre, filteredPoiData);

    if (!mounted) return;
    setState(() {
      this.markers = markers;
      if (nearestPOI != null) {
        final distance = GeolocatorPlatform.instance
            .distanceBetween(
              centre.latitude,
              centre.longitude,
              nearestPOI.latitude,
              nearestPOI.longitude,
            )
            .round();
        _nearestPOIInfo = 'Nearest POI: ${nearestPOI.name} (${distance}m)';

        // Open the info window of the nearest POI
        WidgetsBinding.instance.addPostFrameCallback((_) {
          googleMapController?.showMarkerInfoWindow(MarkerId(nearestPOI.name));
        });
      } else {
        _nearestPOIInfo = '';
      }
    });
  }

  checkPermission() async {
    check = await _geolocatorPlatform.checkPermission();
  }

  Future<void> getMyLocation() async {
    if (check == LocationPermission.denied ||
        check == LocationPermission.deniedForever) {
      check = await Geolocator.requestPermission();
      if (check != LocationPermission.denied &&
          check != LocationPermission.deniedForever) {
        var loc = await Geolocator.getCurrentPosition();
        latLng = LatLng(loc.latitude, loc.longitude);
        if (googleMapController != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          googleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));
        }
      }
    } else {
      if (check != LocationPermission.deniedForever) {
        var loc = await Geolocator.getCurrentPosition();
        latLng = LatLng(loc.latitude, loc.longitude);
        if (googleMapController != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          googleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));
        }
      }
    }
  }

  @override
  void initState() {
    controller = TextEditingController();
    latLng = LatLng(
      widget.address?.location?.first ??
          LocalStorage.getAddressSelected()?.location?.latitude ??
          (AppHelpers.getInitialLatitude() ?? AppConstants.demoLatitude),
      widget.address?.location?.last ??
          LocalStorage.getAddressSelected()?.location?.longitude ??
          (AppHelpers.getInitialLongitude() ?? AppConstants.demoLongitude),
    );
    checkPermission();
    _createMarkers();
    _loadPOIData(latLng);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(viewMapProvider);
    final bool isLtr = LocalStorage.getLangLtr();
    final bool isDarkMode = ref.watch(appProvider).isDarkMode;

    return KeyboardDismisser(
      child: Directionality(
        textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor:
              isDarkMode ? AppStyle.mainBackDark : AppStyle.mainBack,
          body: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            child: Stack(
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: state.isScrolling
                      ? MediaQuery.sizeOf(context).height
                      : MediaQuery.sizeOf(context).height - 0.r,
                  child: GoogleMap(
                    onCameraMoveStarted: () {
                      ref.read(viewMapProvider.notifier).scrolling(true);
                      _animationController.repeat();
                    },
                    myLocationButtonEnabled: false,
                    initialCameraPosition: CameraPosition(
                      bearing: 0,
                      target: latLng,
                      tilt: 0,
                      zoom: 17,
                    ),
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    onTap: (position) {
                      event.updateActive();
                      delayed.run(() async {
                        try {
                          final List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                            cameraPosition?.target.latitude ?? latLng.latitude,
                            cameraPosition?.target.longitude ??
                                latLng.longitude,
                          );
                          if (placemarks.isNotEmpty) {
                            final Placemark pos = placemarks[0];
                            final List<String> addressData = [];
                            addressData.add(pos.locality!);
                            if (pos.subLocality != null &&
                                pos.subLocality!.isNotEmpty) {
                              addressData.add(pos.subLocality!);
                            }
                            if (pos.thoroughfare != null &&
                                pos.thoroughfare!.isNotEmpty) {
                              addressData.add(pos.thoroughfare!);
                            }
                            addressData.add(pos.name!);
                            final String placeName = addressData.join(', ');
                            controller.text = placeName;
                          }
                        } catch (e) {
                          controller.text = '';
                        }

                        event
                          ..checkDriverZone(
                            context: context,
                            location: LatLng(
                              cameraPosition?.target.latitude ??
                                  latLng.latitude,
                              cameraPosition?.target.longitude ??
                                  latLng.longitude,
                            ),
                            shopId: widget.shopId,
                          )
                          ..changePlace(
                            AddressNewModel(
                              address: AddressInformation(
                                address: controller.text,
                              ),
                              location: [
                                cameraPosition?.target.latitude ??
                                    latLng.latitude,
                                cameraPosition?.target.longitude ??
                                    latLng.longitude,
                              ],
                            ),
                          );
                      });
                      googleMapController!.animateCamera(
                        CameraUpdate.newLatLng(latLng),
                      );
                    },
                    onCameraIdle: () {
                      event.updateActive();
                      delayed.run(() async {
                        try {
                          final List<Placemark> placemarks =
                              await placemarkFromCoordinates(
                            cameraPosition?.target.latitude ?? latLng.latitude,
                            cameraPosition?.target.longitude ??
                                latLng.longitude,
                          );
                          if (placemarks.isNotEmpty) {
                            final Placemark pos = placemarks[0];
                            final List<String> addressData = [];
                            addressData.add(pos.locality!);
                            if (pos.subLocality != null &&
                                pos.subLocality!.isNotEmpty) {
                              addressData.add(pos.subLocality!);
                            }
                            if (pos.thoroughfare != null &&
                                pos.thoroughfare!.isNotEmpty) {
                              addressData.add(pos.thoroughfare!);
                            }
                            addressData.add(pos.name!);
                            final String placeName = addressData.join(', ');
                            controller.text = placeName;
                          }
                        } catch (e) {
                          controller.text = '';
                        }

                        if (!widget.isShopLocation) {
                          event
                            ..checkDriverZone(
                              context: context,
                              location: LatLng(
                                cameraPosition?.target.latitude ??
                                    latLng.latitude,
                                cameraPosition?.target.longitude ??
                                    latLng.longitude,
                              ),
                              shopId: widget.shopId,
                            )
                            ..changePlace(
                              AddressNewModel(
                                address: AddressInformation(
                                  address: controller.text,
                                ),
                                location: [
                                  cameraPosition?.target.latitude ??
                                      latLng.latitude,
                                  cameraPosition?.target.longitude ??
                                      latLng.longitude,
                                ],
                              ),
                            );
                        } else {
                          event.changePlace(
                            AddressNewModel(
                              address: AddressInformation(
                                address: controller.text,
                              ),
                              location: [
                                cameraPosition?.target.latitude ??
                                    latLng.latitude,
                                cameraPosition?.target.longitude ??
                                    latLng.longitude,
                              ],
                            ),
                          );
                        }
                        ref.read(viewMapProvider.notifier).scrolling(false);
                      });
                      _animationController.forward(from: 0.0);
                    },
                    onCameraMove: (position) {
                      cameraPosition = position;
                      _createMarkers();
                      _loadPOIData(position.target);
                    },
                    onMapCreated: (controller) {
                      googleMapController = controller;
                      _animationController.forward(from: 0.0);
                    },
                    markers: markers,
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 78.0),
                      child: lottie.Lottie.asset(
                        "assets/lottie/pin.json",
                        onLoaded: (composition) {
                          _animationController.duration = composition.duration;
                        },
                        controller: _animationController,
                        width: 250.w,
                        height: 250.h,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 24,
                  right: 24,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      5.verticalSpace,
                      Row(
                        children: [
                          10.horizontalSpace,
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppStyle.textGrey,
                                  offset: Offset(0, 2),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                ),
                              ],
                              shape: BoxShape.circle,
                              color: AppStyle.cardFor(Theme.of(context).brightness),
                            ),
                            padding: EdgeInsets.all(10.r),
                            child: const Center(
                              child: Icon(
                                FlutterRemix.map_pin_range_line,
                                size: 30,
                              ),
                            ),
                          ),
                          6.horizontalSpace,
                          Container(
                            width: MediaQuery.sizeOf(context).width - 122,
                            height: 50.r,
                            padding: REdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: AppStyle.textGrey,
                                  offset: Offset(0, 2),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                ),
                              ],
                              color: AppStyle.cardFor(Theme.of(context).brightness),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Center(
                              child: Text(
                                controller.text,
                                style: AppStyle.interNormal(size: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  bottom: 94.r,
                  right: state.isScrolling ? -100 : 16.w,
                  child: InkWell(
                    onTap: () async {
                      await getMyLocation();
                    },
                    child: Container(
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        color: AppStyle.cardFor(Theme.of(context).brightness),
                        borderRadius: BorderRadius.all(Radius.circular(10.r)),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyle.shimmerBase,
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(FlutterRemix.navigation_line),
                      ),
                    ),
                  ),
                ),
                if (widget.address != null &&
                    !(widget.address?.active ?? false))
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    top: 32.r,
                    right: state.isScrolling ? -100 : 16.w,
                    child: InkWell(
                      onTap: () async {
                        ref.read(profileProvider.notifier).deleteAddress(
                              index: widget.indexAddress ?? 0,
                              id: widget.address?.id,
                            );
                        context.maybePop();
                      },
                      child: Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: AppStyle.red,
                          borderRadius: BorderRadius.all(Radius.circular(24.r)),
                          boxShadow: [
                            BoxShadow(
                              color: AppStyle.shimmerBase,
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            FlutterRemix.delete_bin_fill,
                            color: AppStyle.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  left: 16,
                  right: 16,
                  bottom: 32,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      // Inside the build method, add this before the CustomButton
                      if (_nearestPOIInfo.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.r),
                          child: Text(
                            _nearestPOIInfo,
                            style: AppStyle.interNormal(
                              size: 14,
                              color: AppStyle.inkFor(Theme.of(context).brightness),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Row(
                        children: [
                          if (widget.isPop)
                            Padding(
                              padding: REdgeInsets.only(right: 8),
                              child: const PopButton(),
                            ),
                          Expanded(
                            child: Opacity(
                              opacity: state.isScrolling ? 0.5 : 1,
                              child: CustomButton(
                                isLoading: controller.text.isEmpty,
                                title: AppHelpers.getTranslation(
                                  TrKeys.confirmLocation,
                                ),
                                onPressed: () {
                                  if (widget.isParcel) {
                                    Navigator.pop(
                                      context,
                                      AddressNewModel(
                                        address: AddressInformation(
                                          address: controller.text,
                                        ),
                                        location: [
                                          cameraPosition?.target.latitude ??
                                              latLng.latitude,
                                          cameraPosition?.target.longitude ??
                                              latLng.longitude,
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  if (!state.isScrolling) {
                                    AppHelpers.showCustomModalBottomSheet(
                                      paddingTop: -50,
                                      context: context,
                                      modal: ViewMapModal(
                                        controller: controller,
                                        address: widget.address,
                                        latLng: latLng,
                                        isShopLocation: widget.isShopLocation,
                                        onSearch: () async {
                                          final placeId =
                                              await AppRoutes.I.pushMapSearchRoute(context);
                                          if (placeId != null) {
                                            final res = await googlePlaces
                                                .getPlaceDetails(
                                                    placeId.toString());
                                            try {
                                              final List<Placemark> placemarks =
                                                  await placemarkFromCoordinates(
                                                res?.latitude ??
                                                    latLng.latitude,
                                                res?.longitude ??
                                                    latLng.longitude,
                                              );
                                              if (placemarks.isNotEmpty) {
                                                final Placemark pos =
                                                    placemarks[0];
                                                final List<String> addressData =
                                                    [];
                                                addressData.add(pos.locality!);
                                                if (pos.subLocality != null &&
                                                    pos.subLocality!
                                                        .isNotEmpty) {
                                                  addressData.add(
                                                    pos.subLocality!,
                                                  );
                                                }
                                                if (pos.thoroughfare != null &&
                                                    pos.thoroughfare!
                                                        .isNotEmpty) {
                                                  addressData.add(
                                                    pos.thoroughfare!,
                                                  );
                                                }
                                                addressData.add(pos.name!);
                                                final String placeName =
                                                    addressData.join(', ');
                                                controller.text = placeName;
                                              }
                                            } catch (e) {
                                              controller.text = '';
                                            }

                                            googleMapController!.animateCamera(
                                              CameraUpdate.newLatLngZoom(
                                                LatLng(
                                                  res?.latitude ??
                                                      latLng.latitude,
                                                  res?.longitude ??
                                                      latLng.longitude,
                                                ),
                                                15,
                                              ),
                                            );
                                            event.changePlace(
                                              AddressNewModel(
                                                address: AddressInformation(
                                                  address: controller.text,
                                                ),
                                                location: [
                                                  cameraPosition
                                                          ?.target.latitude ??
                                                      latLng.latitude,
                                                  cameraPosition
                                                          ?.target.longitude ??
                                                      latLng.longitude,
                                                ],
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      isDarkMode: isDarkMode,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
