import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:${package}/presentation/theme/theme.dart';
// TODO: this providers.dart target does not exist in merchants_sdk yet - the
// real implementation still lives in the old pre-refork monolith at
// paas_manager/lib/application/restaurant/delivery_zone/
// (delivery_zone_provider.dart, delivery_zone_notifier.dart,
// delivery_zone_state.dart) and needs to be ported over, not written from
// scratch. Same gap as the driver variant of this page. This page cannot
// compile until it is ported.
import 'package:merchants_sdk/src/application/providers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

@RoutePage(name: 'ManagerDeliveryZoneRoute')
class ManagerDeliveryZonePage extends ConsumerStatefulWidget {
  const ManagerDeliveryZonePage({super.key});

  @override
  ConsumerState<ManagerDeliveryZonePage> createState() =>
      _DeliveryZonePageState();
}

class _DeliveryZonePageState extends ConsumerState<ManagerDeliveryZonePage> {
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
      backgroundColor: AppStyle.textGrey,
      resizeToAvoidBottomInset: false,
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(deliveryZoneProvider);
          final event = ref.read(deliveryZoneProvider.notifier);
          return Stack(
            children: [
              state.isLoading
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppStyle.white,
                    )
                  : GoogleMap(
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
                              : AppHelpers.getInitialLatitude() ??
                                    AppConstants.demoLatitude,
                          state.polygon.isNotEmpty
                              ? state.polygon.first.points.first.longitude
                              : AppHelpers.getInitialLongitude() ??
                                    AppConstants.demoLongitude,
                        ),
                        tilt: 0,
                        zoom: 11,
                      ),
                    ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                bottom: 20.r,
                left: 15.r,
                right: 15.r,
                child: Row(
                  children: [
                    const PopButton(
                      heroTag: AppConstants.heroTagAddOrderButton,
                    ),
                    8.horizontalSpace,
                    if (state.tappedPoints.length > 3)
                      Expanded(
                        child: CustomButton(
                          title: AppHelpers.getTranslation(TrKeys.save),
                          isLoading: state.isSaving,
                          onPressed: () => event.updateDeliveryZone(
                            updateSuccess: context.maybePop,
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

