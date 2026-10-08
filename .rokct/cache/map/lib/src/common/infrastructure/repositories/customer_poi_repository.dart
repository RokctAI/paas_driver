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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Colors;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/poi_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:map_sdk/src/common/domain/interface/customer_poi.dart';

/// The customer map's points of interest, on the platform gateway's
/// `api.poi.get_customer_pois` def.
///
/// Same shape as delivery_sdk's `DriverLoadRepository`: a prefix-free `cmd`
/// base (the whitelisted-method key with the app segment dropped) through
/// base_sdk's universal gateway. The def is `allow_guest`, so the call goes
/// out with [PlatformGateway.call]'s `requireAuth: false` - a shopper
/// browsing the map before signing in sees the same points a signed-in one
/// does, and no token is attached to a public read.
///
/// WHAT THIS DOES NOT CARRY. A stored point of interest holds more than a
/// shopper may see: contact details, the internal note, the shop it belongs
/// to, who created it. None of that is read here, mapped here, or reachable
/// from [POIData] - the customer map draws a name, a type and a position,
/// and that is the whole of it. The gateway's answer is read key by key
/// below; a key that is not in that short list is dropped on the floor even
/// if the server sends it.
class CustomerPoiRepository implements CustomerPoiRepositoryFacade {
  static const String _cmd = 'api.poi';
  static const PlatformGateway _gateway = PlatformGateway();

  /// The def's own default radius, mirrored so a caller that does not care
  /// asks for what the server would have used anyway.
  static const double defaultRadiusKm = 5;

  /// The basename the map page appends to `assets/images/poi/` when it
  /// builds a marker icon.
  ///
  /// Nothing ships under that directory - not in this SDK's
  /// `templates/assets`, not in base_sdk's - so there is no pin file to
  /// name, and naming one that is not there would be a guess that fails at
  /// runtime on every marker. Every point therefore carries the empty
  /// basename and the page falls back to the platform's own map pin. When a
  /// pin image is added to an SDK's `templates/assets/images/poi/`, name it
  /// here (and branch on the point's type, if more than one ships); the
  /// page needs no change for that.
  static const String pinAsset = '';

  /// The tint the page multiplies over a bundled pin. Transparent means
  /// "leave the pin as it is": the colour is a drawing instruction, not a
  /// property of the point, and the map has no per-type palette to read.
  static const Color pinTint = Colors.transparent;

  @override
  Future<ApiResult<List<POIData>>> getCustomerPois({
    required double latitude,
    required double longitude,
    double radiusKm = defaultRadiusKm,
  }) async {
    try {
      final response = await _gateway.call(
        '$_cmd.get_customer_pois',
        payload: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
        },
        requireAuth: false,
      );
      return ApiResult.success(data: poiListFrom(response));
    } catch (e) {
      debugPrint('===> get customer pois error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Maps the def's answer onto the map's own [POIData].
  ///
  /// Tolerant by design: the contract is a list of
  /// `{name, label, type, custom_type, latitude, longitude, address}`, but
  /// a missing or differently-wrapped key must cost the shopper a marker,
  /// never the whole map. A row with no usable coordinates is dropped - a
  /// point at 0,0 would be drawn in the Atlantic.
  @visibleForTesting
  static List<POIData> poiListFrom(dynamic response) {
    final pois = <POIData>[];
    for (final row in _rowsOf(response)) {
      final latitude = _toDouble(row['latitude']);
      final longitude = _toDouble(row['longitude']);
      if (latitude == null || longitude == null) continue;
      pois.add(
        POIData(
          name: displayName(row),
          latitude: latitude,
          longitude: longitude,
          titleColor: pinTint,
          pin: pinAsset,
        ),
      );
    }
    return pois;
  }

  /// What the marker is labelled with: the point's own label, and for a
  /// point typed `other` the admin's free-text type alongside it, because
  /// "other" on its own tells a shopper nothing. Falls back through the
  /// free-text type to the record id so a row is never drawn nameless.
  @visibleForTesting
  static String displayName(Map<String, dynamic> row) {
    final label = _text(row['label']);
    final type = _text(row['type']).toLowerCase();
    final customType = _text(row['custom_type']);
    if (type == 'other' && customType.isNotEmpty) {
      return label.isEmpty ? customType : '$label · $customType';
    }
    if (label.isNotEmpty) return label;
    if (customType.isNotEmpty) return customType;
    return _text(row['name']);
  }

  /// The gateway hands back the def's own return value. That is a list
  /// here, but a server that wraps it in a one-key envelope is read too
  /// rather than treated as no points at all.
  static Iterable<Map<String, dynamic>> _rowsOf(dynamic response) {
    final list = _listOf(response);
    return list.whereType<Map>().map((row) => row.cast<String, dynamic>());
  }

  static List<dynamic> _listOf(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      for (final key in const ['data', 'pois', 'message', 'result']) {
        final value = response[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  static String _text(dynamic value) =>
      value == null ? '' : value.toString().trim();

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
