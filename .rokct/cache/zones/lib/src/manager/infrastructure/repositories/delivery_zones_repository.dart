import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

/// The manager (merchant) flavour's own [DeliveryZonesFacade] implementation
/// over base_sdk's HTTP infrastructure.
///
/// Absorbed from paas_manager's retired host users-repository delivery-zone
/// slice (lib/infrastructure/repositories/users_repository.dart, manager
/// migration M5): the shop's catchment polygon is persisted against the
/// merchant's shop (legacy Laravel endpoint
/// `/api/v1/dashboard/seller/delivery-zones`, shop_id-scoped). With the
/// endpoint knowledge living HERE, no host-owned repository remains — the
/// installed manager zones_adapters.dart is a thin shim over this class,
/// registered via the manifest's app_type.manager di_hooks entry.
///
/// The paginate response carries a list of zones, each with an `address` of
/// `[latitude, longitude]` pairs; the seller dashboard only ever edits the
/// first (fetched with perPage: 1), so the first zone's polygon is the
/// facade's whole answer — already exactly the primitive shape the facade
/// speaks, so no model class is needed.
class ManagerDeliveryZonesRepository implements DeliveryZonesFacade {
  @override
  Future<ApiResult<List<List<double>>>> fetchDeliveryZones() async {
    final data = {
      'lang': LocalStorage.getLanguage()?.locale,
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'perPage': 1,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/seller/delivery-zones',
        queryParameters: data,
      );
      final List<dynamic> zones =
          (response.data?['data'] as List<dynamic>?) ?? const [];
      if (zones.isEmpty) {
        return const ApiResult.success(data: <List<double>>[]);
      }
      final List<dynamic> address =
          (zones.first['address'] as List<dynamic>?) ?? const [];
      return ApiResult.success(
        data: address
            .map((point) => (point as List<dynamic>)
                .map((coordinate) => double.parse(coordinate.toString()))
                .toList())
            .toList(),
      );
    } catch (e) {
      debugPrint('==> get delivery zone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<List<double>> points,
  }) async {
    final data = {
      'shop_id': LocalStorage.getShopJson()?['id'],
      'address': [
        for (final point in points) {'0': point[0], '1': point[1]},
      ],
    };
    debugPrint('====> update delivery zone ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/seller/delivery-zones',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update delivery zones failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
