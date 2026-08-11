/// Contract for the seller/manager product-authoring surface: the product
/// catalogue a shop owner creates and edits, as distinct from the public
/// browsing surface `ProductsRepositoryFacade` (base_sdk) already covers.
///
/// Lives in `common/` rather than a role folder because it is a seam a host
/// implements against — common by design, not by consumer count. Its DTOs are
/// in `common/` for the same reason: a facade here cannot return a type that
/// lives in `manager/` without inverting the dependency.
///
/// Endpoint coverage and the gaps the backend workstream still owns are in
/// `docs/frappe-endpoint-contract.md`.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/create_seller_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_extras_groups_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_group_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_products_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_extras_group_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_product_response.dart';

abstract class SellerProductsRepositoryFacade {
  /// [needAddons] switches the listing to addon products only, and [status]
  /// filters by moderation status ('pending' / 'published' / 'unpublished') —
  /// the addon pickers list published addons; the legacy client's
  /// `ProductStatus` enum collapsed to the wire string it always became.
  Future<ApiResult<SellerProductsPaginateResponse>> getProducts({
    int? page,
    String? query,
    int? categoryId,
    bool needAddons = false,
    String? status,
  });

  Future<ApiResult<SingleSellerProductResponse>> getProductDetails(String uuid);

  Future<ApiResult<SingleSellerProductResponse>> createProduct({
    required Map<String, dynamic> product,
  });

  Future<ApiResult<SingleSellerProductResponse>> updateProduct({
    required String uuid,
    required Map<String, dynamic> product,
  });

  /// [deletedStockIds] carries the ids of stocks removed in the edit flow;
  /// [isAddon] marks the single-stock addon save.
  Future<ApiResult<SingleSellerProductResponse>> updateStocks({
    required String uuid,
    required List<Map<String, dynamic>> stocks,
    List<int> deletedStockIds = const [],
    bool isAddon = false,
  });

  Future<ApiResult<SingleSellerProductResponse>> updateExtras({
    required String productUuid,
    required List<Map<String, dynamic>> extras,
  });

  /// [needOnlyValid] keeps the legacy `valid` filter: true returns only groups
  /// that have extra values (what the stock-variant picker wants), false
  /// returns every group (what the group-management list wants).
  Future<ApiResult<SellerExtrasGroupsResponse>> getExtrasGroups({
    int? page,
    bool needOnlyValid = true,
  });

  Future<ApiResult<SellerGroupExtrasResponse>> getExtras({int? groupId});

  Future<ApiResult<SingleSellerExtrasGroupResponse>> createExtrasGroup({
    required Map<String, dynamic> group,
  });

  Future<ApiResult<SingleSellerExtrasGroupResponse>> updateExtrasGroup({
    required int groupId,
    required Map<String, dynamic> group,
  });

  Future<ApiResult<void>> deleteExtrasGroup({int? groupId});

  Future<ApiResult<CreateSellerExtrasResponse>> createExtrasItem({
    required Map<String, dynamic> item,
  });

  Future<ApiResult<CreateSellerExtrasResponse>> updateExtrasItem({
    required int extrasId,
    required Map<String, dynamic> item,
  });

  Future<ApiResult<void>> deleteExtrasItem({required List<int> ids});
}
