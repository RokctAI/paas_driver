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
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_sections_tables.dart';
import 'package:merchants_sdk/src/manager/infrastructure/models/data/sections_tables.dart';

/// Port of the section/table listing + CRUD subset of `paas_manager`'s
/// `TableRepository` (the subset with a reader in the fork: the POS dine-in
/// pickers via the host adapter, plus section/table upkeep), repointed from
/// `/api/v1/dashboard/{role}/shop-sections|tables` to
/// `seller_operations.py`. The booking/statistics remainder of the legacy
/// interface has no surviving page and is recorded, not ported — see
/// `docs/frappe-endpoint-contract.md`.
const _base = '/api/method/paas.api.seller_operations.seller_operations';

class SellerSectionsTablesRepository
    implements SellerSectionsTablesRepositoryFacade {
  ApiResult<T> _fail<T>(Object e, String label) {
    debugPrint('==> $label failure: $e');
    return ApiResult.failure(
      error: AppHelpers.errorHandler(e),
      statusCode: NetworkExceptions.getDioStatus(e),
    );
  }

  @override
  Future<ApiResult<SellerSectionsResponse>> getSections({
    int? page,
    String? query,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_sections',
        queryParameters: {
          if (page != null) 'limit_start': (page - 1) * 14,
          'limit_page_length': 14,
          // Recorded gap: the endpoint takes no search filter yet.
          if (query != null && query.isNotEmpty) 'search': query,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SellerSectionsResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'get seller sections');
    }
  }

  @override
  Future<ApiResult<SellerTablesResponse>> getTables({
    int? page,
    String? query,
    int? shopSectionId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '$_base.get_seller_tables',
        queryParameters: {
          if (page != null) 'limit_start': (page - 1) * 14,
          'limit_page_length': 14,
          if (query != null && query.isNotEmpty) 'search': query,
          // Recorded gap: no section filter server-side yet.
          if (shopSectionId != null) 'shop_section_id': shopSectionId,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SellerTablesResponse.fromJson(response.data),
      );
    } catch (e) {
      return _fail(e, 'get seller tables');
    }
  }

  @override
  Future<ApiResult<void>> createSection({
    required String name,
    required num area,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '$_base.create_seller_section',
        data: {
          'section_data': {
            'title': name,
            'area': area,
          },
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return _fail(e, 'create seller section');
    }
  }

  @override
  Future<ApiResult<void>> deleteTable({required String tableId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '$_base.delete_seller_tables',
        data: {'table_id': tableId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return _fail(e, 'delete seller table');
    }
  }
}
