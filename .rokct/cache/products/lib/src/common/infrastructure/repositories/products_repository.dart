import 'package:flutter/material.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/response/all_products_response.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class ProductsRepository implements ProductsRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): product cmds are the
  /// products module's `manifest.json` whitelisted-method keys with the app
  /// segment dropped (`api.product.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int? page,
  }) async {
    final params = {
      'search': text,
      'limit_start': ((page ?? 1) - 1) * 14,
      'limit_page_length': 14,
    };
    try {
      final response = await _gateway.call(
        'api.product.get_products',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleProductResponse>> getProductDetails(
    String uuid,
  ) async {
    try {
      final response = await _gateway.call(
        'api.product.get_product_by_uuid',
        payload: {'uuid': uuid},
        requireAuth: false,
      );
      return ApiResult.success(
        data: SingleProductResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get product details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsPaginate({
    String? shopId,
    String? categoryId,
    String? brandId,
    int? page,
    String? orderBy,
  }) async {
    final params = {
      'limit_start': ((page ?? 1) - 1) * 14,
      'limit_page_length': 14,
      if (shopId != null) 'shop_id': shopId,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
      if (orderBy != null) 'order_by': orderBy,
    };
    try {
      final response = await _gateway.call(
        'api.product.get_products',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> getProductsPaginate failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getMostSoldProducts({
    String? shopId,
    String? categoryId,
    String? brandId,
  }) async {
    final params = {
      'limit_page_length': 14,
      if (shopId != null) 'shop_id': shopId,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
    };
    try {
      final response = await _gateway.call(
        'api.product.most_sold_products',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get most sold products failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProductCalculateResponse>> getAllCalculations(
    List<CartProductData> cartProducts,
  ) async {
    final products = cartProducts
        .map((p) => {'product_id': p.selectedStock?.id, 'quantity': p.quantity})
        .toList();

    try {
      final response = await _gateway.call(
        'api.product.order_products_calculate',
        payload: {'products': products},
        requireAuth: false,
      );
      return ApiResult.success(
        data: ProductCalculateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get all calculations failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsByIds(
    List<String> ids,
  ) async {
    try {
      final response = await _gateway.call(
        'api.product.get_products_by_ids',
        payload: {'ids': ids},
        requireAuth: false,
      );
      return ApiResult.success(
        data: ProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get products by ids failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> addReview(
    String productUuid,
    String comment,
    double rating,
    String? imageUrl,
  ) async {
    final data = {
      'uuid': productUuid,
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    };
    try {
      await _gateway.tenant('api.product.add_product_review', data);
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add review failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getDiscountProducts({
    String? shopId,
    String? brandId,
    String? categoryId,
    int? page,
  }) async {
    final params = {
      'limit_start': ((page ?? 1) - 1) * 14,
      'limit_page_length': 14,
      if (shopId != null) 'shop_id': shopId,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
    };
    try {
      final response = await _gateway.call(
        'api.product.get_discounted_products',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: ProductsPaginateResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get discount products failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are now covered by the enhanced getProductsPaginate method
  // or are no longer needed.
  // - getProductsByCategoryPaginate
  // - getAllProducts
  // - getProductsShopByCategoryPaginate
  // - getProductsPopularPaginate
  // - getRelatedProducts
  // - getProductCalculations
  // - getNewProducts
  // - getProfitableProducts

  @override
  Future<ApiResult<AllProductsResponse>> getAllProducts({
    required String shopId,
  }) async {
    try {
      final response = await _gateway.call(
        'api.product.get_products',
        payload: {'shop_id': shopId, 'limit_page_length': 100},
        requireAuth: false,
      );
      return ApiResult.success(
        data: AllProductsResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get all products failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getNewProducts({
    String? shopId,
    String? brandId,
    String? categoryId,
    int? page,
  }) async {
    return getProductsPaginate(
      shopId: shopId,
      brandId: brandId,
      categoryId: categoryId,
      page: page,
      orderBy: 'created_at',
    );
  }

  @override
  Future<ApiResult<ProductCalculateResponse>> getProductCalculations(
    String stockId,
    int quantity,
  ) async {
    return getAllCalculations([
      CartProductData(
        selectedStock: Stocks(id: stockId),
        quantity: quantity,
      ),
    ]);
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsByCategoryPaginate({
    String? shopId,
    required int page,
    required String categoryId,
  }) async {
    return getProductsPaginate(
      shopId: shopId,
      categoryId: categoryId,
      page: page,
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsPopularPaginate({
    String? shopId,
    required int page,
  }) async {
    return getProductsPaginate(shopId: shopId, page: page, orderBy: 'rating');
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>>
      getProductsShopByCategoryPaginate({
    String? shopId,
    List<String>? brands,
    int? sortIndex,
    required int page,
    required String categoryId,
  }) async {
    return getProductsPaginate(
      shopId: shopId,
      categoryId: categoryId,
      page: page,
      // Implement sort index logic if needed
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProfitableProducts({
    String? brandId,
    String? categoryId,
    int? page,
  }) async {
    return getProductsPaginate(
      brandId: brandId,
      categoryId: categoryId,
      page: page,
      orderBy: 'discount',
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getRelatedProducts(
    String? brandId,
    String? shopId,
    String? categoryId,
  ) async {
    return getProductsPaginate(
      shopId: shopId,
      brandId: brandId,
      categoryId: categoryId,
      page: 1,
    );
  }
}
