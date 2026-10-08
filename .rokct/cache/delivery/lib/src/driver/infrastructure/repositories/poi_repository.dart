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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/domain/interface/poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';

/// The driver's point-of-interest calls, on map's `api.poi.*` defs.
///
/// Same shape as [DriverLoadRepository]: a prefix-free `cmd` base (map
/// `manifest.json`'s whitelisted-method keys `{app_name}.api.poi.*` with
/// the app segment dropped) through base_sdk's universal platform gateway.
/// Nothing here is multipart, so there is no gallery detour.
///
/// WHAT IS NOT SENT IS THE POINT. There is no `is_platform_wide` key, no
/// `created_by_deliveryman` key and no `owner_user` key on the create
/// call, because the server takes all three from the session, the driver's
/// admin-set profile and the owner's own number. A key added here later
/// would be ignored server-side; it would still be a lie about who
/// decides, so it must not be added.
///
/// ONE REFUSAL IS READ RATHER THAN REPORTED. The server answers a number
/// held under another first name with its own exception class
/// (`PoiOwnerMismatch`), which is a QUESTION for the driver and not a
/// failure. [_ownerClashIn] reads it off the response by EXCEPTION TYPE,
/// never by matching the English of a message, and `create` answers it as
/// a value on [DriverPoiFiling]. Every other error stays an error.
class DriverPoiRepository implements DriverPoiRepositoryFacade {
  static const _cmd = 'api.poi';
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<List<DriverPoiType>>> types() async {
    try {
      final response = await _gateway.tenant('$_cmd.get_poi_types');
      return ApiResult.success(data: DriverPoiType.listFrom(response));
    } catch (e) {
      debugPrint('===> get poi types error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<DriverPoi>>> nearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? type,
    String? shop,
  }) async {
    try {
      final response = await _gateway.tenant('$_cmd.get_nearby_pois', {
        'latitude': latitude,
        'longitude': longitude,
        if (radiusKm != null) 'radius_km': radiusKm,
        if ((type ?? '').trim().isNotEmpty) 'poi_type': type!.trim(),
        if ((shop ?? '').trim().isNotEmpty) 'shop': shop!.trim(),
      });
      return ApiResult.success(data: DriverPoi.listFrom(response));
    } catch (e) {
      debugPrint('===> get nearby pois error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DriverPoiFiling>> create({
    required String label,
    required String type,
    required double latitude,
    required double longitude,
    String? customType,
    String? shop,
    String? address,
    String? note,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerPhone,
    bool ownerConfirmedUser = false,
  }) async {
    try {
      final trimmedCustom = (customType ?? '').trim();
      final trimmedShop = (shop ?? '').trim();
      final trimmedAddress = (address ?? '').trim();
      final trimmedNote = (note ?? '').trim();
      final trimmedFirst = (ownerFirstName ?? '').trim();
      final trimmedLast = (ownerLastName ?? '').trim();
      final trimmedPhone = (ownerPhone ?? '').trim();
      final response = await _gateway.tenant('$_cmd.create_poi', {
        'label': label.trim(),
        'type': type.trim(),
        'latitude': latitude,
        'longitude': longitude,
        if (trimmedCustom.isNotEmpty) 'custom_type': trimmedCustom,
        if (trimmedShop.isNotEmpty) 'shop': trimmedShop,
        if (trimmedAddress.isNotEmpty) 'address': trimmedAddress,
        if (trimmedNote.isNotEmpty) 'note': trimmedNote,
        if (trimmedFirst.isNotEmpty) 'owner_first_name': trimmedFirst,
        if (trimmedLast.isNotEmpty) 'owner_last_name': trimmedLast,
        if (trimmedPhone.isNotEmpty) 'owner_phone': trimmedPhone,
        // Sent ONLY once he has answered the question. Absent is the
        // honest default: "nobody has confirmed anything".
        if (ownerConfirmedUser) 'owner_confirmed_user': 1,
      });
      final point = DriverPoi.oneFrom(response);
      if (point == null) {
        // An empty envelope is a failure rather than a blank point:
        // redrawing a nameless pin would tell the driver his point is on
        // the map when nobody said so.
        debugPrint('===> create poi answered no point');
        return const ApiResult.failure(
          error: 'The point did not come back.',
          statusCode: 500,
        );
      }
      return ApiResult.success(data: DriverPoiFiling.filed(point));
    } catch (e) {
      final clash = _ownerClashIn(e);
      if (clash != null) {
        // NOT a failure: the server wrote nothing and handed the driver a
        // question. Reporting it as an error would show him a red line
        // where he needs a yes/no.
        debugPrint('===> create poi owner clash');
        return ApiResult.success(data: DriverPoiFiling.ownerClash(clash));
      }
      debugPrint('===> create poi error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DriverPoiOwner>> lookupOwner({
    required String phone,
  }) async {
    try {
      final response = await _gateway.tenant('$_cmd.lookup_poi_owner', {
        'phone': phone.trim(),
      });
      return ApiResult.success(data: DriverPoiOwner.fromJson(response));
    } catch (e) {
      debugPrint('===> lookup poi owner error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// The owner clash inside a thrown error, or null when it is any other
  /// failure.
  ///
  /// Frappe names the raised class in `exc_type` and repeats it inside
  /// `exception`, so the type is what is matched — an English message can
  /// be translated or reworded, a class name cannot. The first name the
  /// account carries is read back out of the server's own sentence, which
  /// is the only place it exists; a sentence this cannot read still asks
  /// the question, just without a name in it.
  static DriverPoiOwnerClash? _ownerClashIn(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    if (data is! Map) return null;
    final excType = (data['exc_type'] ?? '').toString().trim();
    final exception = (data['exception'] ?? '').toString();
    final named = excType == DriverPoiOwnerClash.excType ||
        exception.contains(DriverPoiOwnerClash.excType);
    if (!named) return null;
    final detail = [
      data['message'],
      data['_server_messages'],
      exception,
    ].map((part) => (part ?? '').toString()).firstWhere(
          (part) => part.trim().isNotEmpty,
          orElse: () => '',
        );
    return DriverPoiOwnerClash(
      firstName: _firstNameIn(detail),
      detail: detail.isEmpty ? null : detail,
    );
  }

  /// The first name out of the server's "already on file under X." line.
  static String? _firstNameIn(String detail) {
    final match =
        RegExp(r'on file under ([^.<"\\]+)').firstMatch(detail);
    final name = (match?.group(1) ?? '').trim();
    return name.isEmpty ? null : name;
  }

  @override
  Future<ApiResult<DriverPoiShopChoices>> myShops() async {
    try {
      final response = await _gateway.tenant('$_cmd.get_my_poi_shops');
      return ApiResult.success(
        data: DriverPoiShopChoices.fromJson(response),
      );
    } catch (e) {
      debugPrint('===> get my poi shops error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<RouteStopData>>> route({
    double? latitude,
    double? longitude,
    String? type,
    String? shop,
  }) async {
    try {
      final response = await _gateway.tenant('$_cmd.get_poi_route', {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if ((type ?? '').trim().isNotEmpty) 'poi_type': type!.trim(),
        if ((shop ?? '').trim().isNotEmpty) 'shop': shop!.trim(),
      });
      return ApiResult.success(data: RouteStopData.listFromJson(response));
    } catch (e) {
      debugPrint('===> get poi route error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DriverPoiSales>> sales({
    required String poi,
    int limit = 50,
  }) async {
    try {
      final response = await _gateway.tenant('$_cmd.get_poi_sales', {
        'poi': poi,
        'limit': limit,
      });
      return ApiResult.success(data: DriverPoiSales.fromJson(response));
    } catch (e) {
      debugPrint('===> get poi sales error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
