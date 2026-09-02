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

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/models/response/draw_routing_response.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

import 'package:base_sdk/src/handlers/api_result.dart';

class DrawRepository implements DrawRepositoryFacade {
  @override
  Future<ApiResult<DrawRouting>> getRouting({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false, routing: true);
      final response = await client.get(
        '/v2/directions/driving-car',
        queryParameters: {
          "api_key": AppConstants.routingKey,
          "start": (start.longitude, start.latitude),
          "end": (end.longitude, end.latitude),
        },
      );
      return ApiResult.success(data: DrawRouting.fromJson(response.data));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
