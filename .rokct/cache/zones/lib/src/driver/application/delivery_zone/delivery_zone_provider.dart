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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:zones_sdk/src/driver/application/delivery_zone/delivery_zone_notifier.dart';
import 'package:zones_sdk/src/driver/application/delivery_zone/delivery_zone_state.dart';
import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';
import 'package:zones_sdk/src/common/domain/interface/zone_edit_policy_contract.dart';

/// Stand-in used when the host app composes zones_sdk but never registers a
/// [DeliveryZonesFacade].
///
/// It reports a named failure rather than returning empty data, so an
/// unwired host surfaces "delivery zones aren't available" instead of showing
/// a courier an empty map that looks like "you have no zone" — the same
/// reasoning as lms_sdk's `LessonPurchaseOutcome.paymentSetupRequired`: an
/// unwired backend should be visible, not silently indistinguishable from an
/// empty result.
class _UnavailableDeliveryZones implements DeliveryZonesFacade {
  static const _message =
      'No DeliveryZonesFacade is registered: the host app has not wired '
      'delivery zones to a profile/user provider.';

  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async =>
      const ApiResult.failure(error: _message, statusCode: 501);

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async => const ApiResult.failure(error: _message, statusCode: 501);
}

final deliveryZoneProvider =
    StateNotifierProvider<DeliveryZoneNotifier, DeliveryZoneState>((ref) {
  final getIt = GetIt.instance;
  return DeliveryZoneNotifier(
    getIt.isRegistered<DeliveryZonesFacade>()
        ? getIt<DeliveryZonesFacade>()
        : _UnavailableDeliveryZones(),
    // Absent registration means "no restriction" — the notifier's default is
    // permissive. Only a flavour that actually restricts editing (the driver
    // app) registers a policy.
    canEdit: getIt.isRegistered<ZoneEditPolicy>()
        ? getIt<ZoneEditPolicy>().canEdit
        : null,
  );
});
