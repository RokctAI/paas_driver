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
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/infrastructure/services/manager_products_local_store.dart';
import 'package:products_sdk/src/manager/infrastructure/services/product_create_sync_handler.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/create_seller_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_extras_groups_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_group_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_products_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_extras_group_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_product_response.dart';

/// Port of `paas_manager`'s product-authoring calls, repointed from the legacy
/// `/api/v1/dashboard/seller/...` paths to `seller_product.py` in the merchants
/// Frappe app, reached as `api.seller_product.*` cmds through the universal
/// gateway. Payloads follow the server signatures (`product_name` +
/// `product_data`, `group_name` + `group_data`, `value_name` + `value_data`).
///
/// Two calls have NO whitelisted server method yet and stay on the dead
/// per-method path so they fail visibly (fixplan M20): [updateStocks] and
/// [updateExtras] — see the TODOs on them.
const _base = '/api/method/paas.api.seller_product.seller_product';

class SellerProductsRepository implements SellerProductsRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): cmds mirror the
  /// merchants module's `manifest.json` whitelisted-method keys with the app
  /// segment dropped.
  static const _gateway = PlatformGateway();

  /// Mirrors the backend's `limit_page_length` default; the legacy `page`
  /// query becomes `limit_start`.
  static const int _pageSize = 20;

  @override
  Future<ApiResult<SellerProductsPaginateResponse>> getProducts({
    int? page,
    String? query,
    String? categoryId,
    bool needAddons = false,
    String? status,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.seller_product.get_seller_products',
        {
          'lang': LocalStorage.getLanguage()?.locale,
          if (page != null) 'limit_start': (page - 1) * _pageSize,
          'limit_page_length': _pageSize,
          if (query != null && query.isNotEmpty) 'search': query,
          if (categoryId != null) 'category_id': categoryId,
          if (needAddons) 'addon': 1,
          if (status != null) 'status': status,
        },
      );
      return ApiResult.success(
        data: SellerProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get seller products failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> getProductDetails(
    String uuid,
  ) async {
    try {
      // seller_product.get_product_details(product_name): the authoring
      // `uuid` is the Product docname.
      final response = await _gateway.tenant(
        'api.seller_product.get_product_details',
        {
          'product_name': uuid,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SingleSellerProductResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get seller product details failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> createProduct({
    required Map<String, dynamic> product,
  }) async {
    // Local-first: write the record through before the network attempt so a
    // dead connection can never lose the manager's input.
    final String localId = SyncEngine.newTempId();
    await ManagerProductsLocalStore.putPending(localId, {'product': product});
    try {
      // Same cmd + payload shape the outbox handler replays
      // (ProductCreateSyncHandler): seller_product.create_product(product_data).
      final response = await _gateway.tenant(
        'api.seller_product.create_product',
        {'product_data': product},
      );
      // Backend reachable and accepted: it is authoritative from here on
      // (the product list refetch supplies the row), so the write-through
      // record goes.
      await ManagerProductsLocalStore.delete(localId);
      return ApiResult.success(
        data: SingleSellerProductResponse.fromJson(response),
      );
    } catch (e) {
      final status = NetworkExceptions.getDioStatus(e);
      if (status >= 400 && status < 500 && status != 408) {
        // Backend reachable and said no — unchanged backend-first behavior;
        // the local record must not survive a definitive rejection.
        await ManagerProductsLocalStore.delete(localId);
        debugPrint('==> create product failure: $e');
        return _fail(e);
      }
      // Backend unreachable / transient: keep the record, queue the push and
      // report success (getDioStatus maps connection failures and timeouts
      // to 500). A shop that is itself still offline-only makes the shop op
      // this op's parent, so creates land in order.
      final shopId = LocalStorage.getShopJson()?['id'];
      final dependsOn = shopId is String && shopId.startsWith(kOfflineIdPrefix)
          ? await ManagerProductsLocalStore.pendingOpIdsCreating([shopId])
          : const <String>[];
      await SyncEngine().enqueue(
        opType: ProductCreateSyncHandler.opType,
        sdk: ProductCreateSyncHandler.sdkName,
        payload: {'localId': localId, 'product': product},
        tempIds: [localId],
        dependsOn: dependsOn,
      );
      final record = await ManagerProductsLocalStore.get(localId);
      return ApiResult.success(
        data: SingleSellerProductResponse(
          data: record == null
              ? null
              : ManagerProductsLocalStore.toProductData(record),
        ),
      );
    }
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateProduct({
    required String uuid,
    required Map<String, dynamic> product,
  }) =>
      _postProduct('api.seller_product.update_seller_product', {
        'product_name': uuid,
        'product_data': product,
      });

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateStocks({
    required String uuid,
    required List<Map<String, dynamic>> stocks,
    List<String> deletedStockIds = const [],
    bool isAddon = false,
  }) =>
      // TODO(fix-wave 2026-09-02): no server method — seller_product.py's
      // update_product_stocks is an un-aliased placeholder returning
      // {"status": true} without touching stock, so aliasing it would make a
      // stock update look successful. Left on the dead path so it fails
      // visibly; needs an owner decision (fixplan M20).
      _postProductLegacy('$_base.update_product_stocks', {
        'uuid': uuid,
        'stocks': stocks,
        if (deletedStockIds.isNotEmpty) 'delete_ids': deletedStockIds,
        if (isAddon) 'addon': 1,
      });

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateExtras({
    required String productUuid,
    required List<Map<String, dynamic>> extras,
  }) =>
      // TODO(fix-wave 2026-09-02): no server method — same placeholder
      // situation as updateStocks (seller_product.update_product_extras);
      // left on the dead path, needs an owner decision (fixplan M20).
      _postProductLegacy('$_base.update_product_extras', {
        'uuid': productUuid,
        'extras': extras,
      });

  @override
  Future<ApiResult<SellerExtrasGroupsResponse>> getExtrasGroups({
    int? page,
    bool needOnlyValid = true,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.seller_product.get_seller_extra_groups',
        {
          'lang': LocalStorage.getLanguage()?.locale,
          if (page != null) 'limit_start': (page - 1) * _pageSize,
          'limit_page_length': _pageSize,
          if (needOnlyValid) 'valid': true,
        },
      );
      return ApiResult.success(
        data: SellerExtrasGroupsResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get extras groups failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SellerGroupExtrasResponse>> getExtras({
    required String groupId,
  }) async {
    try {
      // seller_product.get_seller_extra_values(group_name, ...).
      final response = await _gateway.tenant(
        'api.seller_product.get_seller_extra_values',
        {
          'group_name': groupId,
          'lang': LocalStorage.getLanguage()?.locale,
        },
      );
      return ApiResult.success(
        data: SellerGroupExtrasResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get extras failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<SingleSellerExtrasGroupResponse>> createExtrasGroup({
    required Map<String, dynamic> group,
  }) =>
      _postGroup('api.seller_product.create_seller_extra_group', {
        'group_data': group,
      });

  @override
  Future<ApiResult<SingleSellerExtrasGroupResponse>> updateExtrasGroup({
    required String groupId,
    required Map<String, dynamic> group,
  }) =>
      _postGroup('api.seller_product.update_seller_extra_group', {
        'group_name': groupId,
        'group_data': group,
      });

  @override
  Future<ApiResult<void>> deleteExtrasGroup({required String groupId}) async {
    try {
      await _gateway.tenant(
        'api.seller_product.delete_seller_extra_group',
        {'group_name': groupId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete extras group failure: $e');
      return _fail(e);
    }
  }

  @override
  Future<ApiResult<CreateSellerExtrasResponse>> createExtrasItem({
    required Map<String, dynamic> item,
  }) =>
      _postExtrasValue('api.seller_product.create_seller_extra_value', {
        'value_data': item,
      });

  @override
  Future<ApiResult<CreateSellerExtrasResponse>> updateExtrasItem({
    required String extrasId,
    required Map<String, dynamic> item,
  }) =>
      _postExtrasValue('api.seller_product.update_seller_extra_value', {
        'value_name': extrasId,
        'value_data': item,
      });

  @override
  Future<ApiResult<void>> deleteExtrasItem({
    required List<String> ids,
  }) async {
    try {
      // seller_product.delete_seller_extra_value(value_name) takes ONE
      // value; the legacy bulk delete becomes one cmd per id.
      for (final id in ids) {
        await _gateway.tenant(
          'api.seller_product.delete_seller_extra_value',
          {'value_name': id},
        );
      }
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete extras item failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<SingleSellerProductResponse>> _postProduct(
    String cmd,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _gateway.tenant(cmd, payload);
      return ApiResult.success(
        data: SingleSellerProductResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> $cmd failure: $e');
      return _fail(e);
    }
  }

  /// The pre-gateway per-method POST, kept ONLY for the two calls that have
  /// no whitelisted server method yet ([updateStocks], [updateExtras]) so
  /// they keep failing visibly instead of being faked.
  Future<ApiResult<SingleSellerProductResponse>> _postProductLegacy(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(path, data: body);
      return ApiResult.success(
        data: SingleSellerProductResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> $path failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<SingleSellerExtrasGroupResponse>> _postGroup(
    String cmd,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _gateway.tenant(cmd, payload);
      return ApiResult.success(
        data: SingleSellerExtrasGroupResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> $cmd failure: $e');
      return _fail(e);
    }
  }

  Future<ApiResult<CreateSellerExtrasResponse>> _postExtrasValue(
    String cmd,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _gateway.tenant(cmd, payload);
      return ApiResult.success(
        data: CreateSellerExtrasResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> $cmd failure: $e');
      return _fail(e);
    }
  }

  ApiResult<T> _fail<T>(Object e) => ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
}
