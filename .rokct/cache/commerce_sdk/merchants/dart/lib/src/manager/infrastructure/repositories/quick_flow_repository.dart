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

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';

/// Quick flow settings over `seller_shop.py`'s two endpoints (design strip
/// section 42). Same host neighbourhood and same failure discipline as
/// [SellerShopRepository]: a call the backend cannot answer fails through
/// [ApiResult.failure] rather than being faked.
const _shop = '/api/method/paas.api.seller_shop.seller_shop';

class QuickFlowRepository implements QuickFlowRepositoryFacade {
  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  @override
  Future<ApiResult<QuickFlowSettings>> getQuickFlowSettings() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('$_shop.get_quick_flow_settings');
      return ApiResult.success(
        data: QuickFlowSettings.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'get quick flow settings');
    }
  }

  @override
  Future<ApiResult<QuickFlowSettings>> updateQuickFlowSettings({
    bool? autoAcceptOrders,
    bool? autoCompleteAtReady,
    bool? keypadAutodial,
    List<QuickFlowPreset>? presets,
  }) async {
    // Only the keys the caller actually moved are sent: the endpoint leaves
    // an omitted switch exactly as it was, so saving one toggle can never
    // clobber another the seller changed on a second device.
    final settings = <String, dynamic>{
      if (autoAcceptOrders != null) 'auto_accept_orders': autoAcceptOrders,
      if (autoCompleteAtReady != null)
        'auto_complete_at_ready': autoCompleteAtReady,
      if (keypadAutodial != null) 'keypad_autodial': keypadAutodial,
      if (presets != null)
        'digit_presets': presets.map((p) => p.toJson()).toList(),
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '$_shop.update_quick_flow_settings',
        data: {'settings': settings},
      );
      return ApiResult.success(
        data: QuickFlowSettings.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'update quick flow settings');
    }
  }
}
