import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:zones_sdk/src/manager/application/delivery_zone/delivery_zone_notifier.dart';
import 'package:zones_sdk/src/manager/application/delivery_zone/delivery_zone_state.dart';
import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

/// Stand-in used when the host app composes zones_sdk but never registers a
/// [DeliveryZonesFacade].
///
/// Same reasoning as the driver provider's stand-in: an unwired host should
/// surface "delivery zones aren't available" rather than showing a merchant
/// an empty map that is indistinguishable from "you have no zone yet".
class _UnavailableDeliveryZones implements DeliveryZonesFacade {
  static const _message =
      'No DeliveryZonesFacade is registered: the host app has not wired '
      'delivery zones to a shop/user provider.';

  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async =>
      const ApiResult.failure(error: _message, statusCode: 501);

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async => const ApiResult.failure(error: _message, statusCode: 501);
}

/// No [ZoneEditPolicy] lookup here, unlike the driver provider: the merchant
/// flavour has no edit restriction to consult (see the contract's doc), and
/// its notifier deliberately has no `canEdit` hook to wire one into.
final deliveryZoneProvider =
    StateNotifierProvider<DeliveryZoneNotifier, DeliveryZoneState>((ref) {
  final getIt = GetIt.instance;
  return DeliveryZoneNotifier(
    getIt.isRegistered<DeliveryZonesFacade>()
        ? getIt<DeliveryZonesFacade>()
        : _UnavailableDeliveryZones(),
  );
});
