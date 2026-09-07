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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// The zone slice now lives in zones_sdk (ported from paas_driver's
// application/delivery_zone/ in the 2026-07 refork), not delivery_sdk as this
// page originally assumed. zones_sdk owns zone geometry for both the driver
// and manager flavours of this page. Deep import rather than the
// zones_sdk.dart barrel: the barrel is common-only (role folders are
// stripped per-host by the composer), and this page only exists in driver
// hosts, where src/driver/ survives.
import 'package:zones_sdk/src/driver/application/delivery_zone/delivery_zone_provider.dart';
// delivery_sdk's map surface pieces, host-side like every template import
// (home_page.dart imports comms_sdk the same way): the driver zone page only
// installs into a driver compose, which always carries delivery_sdk as its
// home SDK, and lib/ of this SDK still imports no delivery_sdk (ADR-005).
import 'package:delivery_sdk/src/driver/presentation/widgets/deferred_map_surface.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/driver_map_style.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

@RoutePage(name: 'DriverDeliveryZoneRoute')
class DriverDeliveryZonePage extends ConsumerStatefulWidget {
  const DriverDeliveryZonePage({super.key});

  @override
  ConsumerState<DriverDeliveryZonePage> createState() =>
      _DeliveryZonePageState();
}

class _DeliveryZonePageState extends ConsumerState<DriverDeliveryZonePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(deliveryZoneProvider.notifier).fetchDeliveryZone(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      resizeToAvoidBottomInset: false,
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(deliveryZoneProvider);
          final event = ref.read(deliveryZoneProvider.notifier);
          // Tablet audit 2026-09-07 (13-driver_delivery_zone, an all-black
          // frame): the page painted a pinned grey scaffold, a pinned WHITE
          // loading box and a bare GoogleMap whose platform view painted
          // nothing before the tour's still. The same three fixes the
          // driver home already carries: the ground and the loading box
          // resolve with the mode, the map is MOUNTED only once the page
          // has settled (DeferredMapSurface: one frame painted, 800 ms of
          // being the current route, still mounted - the plugin's own
          // un-awaited channel calls on a page that is already leaving are
          // what took the phone tour down), and the map resolves with the
          // mode too. Camera, polygon and tap handling are untouched.
          const placeholder = _MapPlaceholder();
          return Stack(
            children: [
              state.isLoading
                  ? placeholder
                  : DeferredMapSurface(
                      placeholder: placeholder,
                      child: GoogleMap(
                        style: DriverMapStyle.forMode(),
                        tiltGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        polygons: state.polygon,
                        onTap: event.addTappedPoint,
                        initialCameraPosition: CameraPosition(
                          bearing: 0,
                          target: LatLng(
                            state.polygon.isNotEmpty
                                ? state.polygon.first.points.first.latitude
                                : LocalStorage.getAddressSelected()
                                          ?.location
                                          ?.latitude ??
                                      AppConstants.demoLatitude,
                            state.polygon.isNotEmpty
                                ? state.polygon.first.points.first.longitude
                                : LocalStorage.getAddressSelected()
                                          ?.location
                                          ?.longitude ??
                                      AppConstants.demoLongitude,
                          ),
                          tilt: 0,
                          zoom: 11,
                        ),
                      ),
                    ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                bottom: 20.r,
                left: 15.r,
                right: 15.r,
                child: Row(
                  children: [
                    const PopButton(),
                    8.horizontalSpace,
                    if (state.tappedPoints.length > 3)
                      Expanded(
                        child: CustomButton(
                          title: AppHelpers.getTranslation(TrKeys.save),
                          isLoading: state.isSaving,
                          onPressed: () => event.updateDeliveryZone(
                            updateSuccess: context.router.maybePop,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What the map area shows before the zone has loaded and until the map
/// mounts: a box in the mode's card colour with a quiet spinner, instead of
/// the pinned white sheet that read as a blank page in dark mode.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppStyle.cardDark,
      child: Center(
        child: SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppStyle.textDarkSecondary,
          ),
        ),
      ),
    );
  }
}
