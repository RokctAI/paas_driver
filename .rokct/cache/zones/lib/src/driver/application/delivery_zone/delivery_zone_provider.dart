// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
