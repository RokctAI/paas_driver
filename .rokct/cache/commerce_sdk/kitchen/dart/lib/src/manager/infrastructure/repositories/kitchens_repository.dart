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
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:kitchen_sdk/src/common/domain/interface/kitchens.dart';
import 'package:kitchen_sdk/src/common/infrastructure/models/response/kitchens_paginate_response.dart';

/// Port of `paas_manager`'s `getKitchens`, repointed from
/// `/api/v1/dashboard/seller/kitchen/` to its Frappe counterpart
/// (merchants' seller_operations.get_seller_kitchens) via the universal
/// platform gateway.
class KitchensRepository implements KitchensRepositoryFacade {
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<KitchensPaginateResponse>> getKitchens({int? perPage}) async {
    try {
      final response = await _gateway.tenant(
        'api.seller_operations.get_seller_kitchens',
        {
          'lang': LocalStorage.getLanguage()?.locale,
          'limit_page_length': perPage ?? 100,
        },
      );
      return ApiResult.success(
        data: KitchensPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get kitchens paginate failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
