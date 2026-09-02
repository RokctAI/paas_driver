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


import 'package:base_sdk/src/models/response/all_products_response.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/models.dart';

abstract class ProductsRepositoryFacade {
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int page,
  });

  Future<ApiResult<SingleProductResponse>> getProductDetails(String uuid);

  Future<ApiResult<ProductsPaginateResponse>> getProductsPaginate({
    String? shopId,
    String? categoryId,
    String? brandId,
    required int page,
    String? orderBy,
  });

  Future<ApiResult<AllProductsResponse>> getAllProducts({
    required String shopId,
  });

  Future<ApiResult<ProductsPaginateResponse>> getProductsPopularPaginate({
    String? shopId,
    required int page,
  });

  Future<ApiResult<ProductsPaginateResponse>> getProductsByCategoryPaginate({
    String? shopId,
    required int page,
    required String categoryId,
  });

  Future<ApiResult<ProductsPaginateResponse>>
      getProductsShopByCategoryPaginate({
    String? shopId,
    List<String>? brands,
    int? sortIndex,
    required int page,
    required String categoryId,
  });

  Future<ApiResult<ProductsPaginateResponse>> getMostSoldProducts({
    String? shopId,
    String? categoryId,
    String? brandId,
  });

  Future<ApiResult<ProductsPaginateResponse>> getRelatedProducts(
    String? brandId,
    String? shopId,
    String? categoryId,
  );

  Future<ApiResult<ProductCalculateResponse>> getProductCalculations(
    String stockId,
    int quantity,
  );

  Future<ApiResult<ProductCalculateResponse>> getAllCalculations(
    List<CartProductData> cartProducts,
  );

  Future<ApiResult<ProductsPaginateResponse>> getProductsByIds(
    List<String> ids,
  );

  Future<ApiResult<void>> addReview(
    String productUuid,
    String comment,
    double rating,
    String? imageUrl,
  );

  Future<ApiResult<ProductsPaginateResponse>> getNewProducts({
    String? shopId,
    String? brandId,
    String? categoryId,
    int? page,
  });

  Future<ApiResult<ProductsPaginateResponse>> getDiscountProducts({
    String? shopId,
    String? brandId,
    String? categoryId,
    int? page,
  });

  Future<ApiResult<ProductsPaginateResponse>> getProfitableProducts({
    String? brandId,
    String? categoryId,
    int? page,
  });
}
