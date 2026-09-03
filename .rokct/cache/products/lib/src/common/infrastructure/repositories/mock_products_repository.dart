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

import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/products_paginate_response.dart';
import 'package:base_sdk/src/models/response/single_product_response.dart';
import 'package:base_sdk/src/models/response/product_calculate_response.dart';
import 'package:base_sdk/src/models/response/all_products_response.dart';
import 'package:base_sdk/src/models/data/cart_product_data.dart';

class MockProductsRepository implements ProductsRepositoryFacade {
  final ProductData _demoProduct = ProductData(
    id: "1",
    uuid: "demo_product_uuid",
    shopId: "1",
    categoryId: "1",
    keywords: "burger, flame-grilled, beef",
    brandId: "1",
    tax: 5,
    interval: 1,
    minQty: 1,
    maxQty: 100,
    active: true,
    img: DemoImages.product,
    createdAt: DateTime.now().toString(),
    updatedAt: DateTime.now().toString(),
    ratingAvg: 4.5,
    ordersCount: 50,
    translation: Translation(
      title: "Flame-grilled beef burger",
      description: "Chargrilled patty, smoked cheddar and house sauce",
      locale: "en",
    ),
    stocks: [Stocks(id: "1", price: 150, quantity: 100, totalPrice: 150)],
  );

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsPaginate({
    String? shopId,
    String? categoryId,
    String? brandId,
    required int page,
    String? orderBy,
  }) async {
    return ApiResult.success(
      data: ProductsPaginateResponse(
        data: [
          _demoProduct,
          _demoProduct.copyWith(
            id: "2",
            translation: Translation(title: "Margherita pizza"),
          ),
          // Demo seed for the 18+ (adults only) feature: exercises the
          // customer-facing badge and the checkout age gate in demo builds.
          _demoProduct.copyWith(
            id: "3",
            isAdult: true,
            translation: Translation(
              // Named for what it is: the 18+ badge and the checkout age
              // gate need a seed item that is actually age-restricted.
              title: "Craft lager 440ml",
              description: "18+ only - proof of age required on delivery",
              locale: "en",
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int? page,
  }) async {
    return ApiResult.success(
      data: ProductsPaginateResponse(data: [_demoProduct]),
    );
  }

  @override
  Future<ApiResult<SingleProductResponse>> getProductDetails(
    String uuid,
  ) async {
    return ApiResult.success(data: SingleProductResponse(data: _demoProduct));
  }

  @override
  Future<ApiResult<ProductCalculateResponse>> getProductCalculations(
    String stockId,
    int quantity,
  ) async {
    // Mock calculation logic
    double price = 150.0;
    double total = price * quantity;
    return ApiResult.success(
      data: ProductCalculateResponse(
        data: CalculatedData(
          products: [
            CalculatedProduct(
              id: int.tryParse(stockId) ?? 0,
              qty: quantity,
              price: price,
              totalPrice: total,
              tax: 0,
              shopTax: 0,
              discount: 0,
              priceWithoutTax: price,
            ),
          ],
          productTotal: total,
          orderTotal: total,
          productTax: 0,
          orderTax: 0,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getMostSoldProducts({
    String? shopId,
    String? categoryId,
    String? brandId,
  }) async {
    return ApiResult.success(
      data: ProductsPaginateResponse(data: [_demoProduct]),
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getRelatedProducts(
    String? brandId,
    String? shopId,
    String? categoryId,
  ) async {
    return ApiResult.success(
      data: ProductsPaginateResponse(data: [_demoProduct]),
    );
  }

  @override
  Future<ApiResult<void>> addReview(
    String productUuid,
    String comment,
    double rating,
    String? imageUrl,
  ) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<ProductCalculateResponse>> getAllCalculations(
    List<CartProductData> cartProducts,
  ) async {
    return ApiResult.success(
      data: ProductCalculateResponse(
        data: CalculatedData(
          products: [],
          productTotal: 0,
          orderTotal: 0,
          productTax: 0,
          orderTax: 0,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<AllProductsResponse>> getAllProducts({
    required String shopId,
  }) async {
    return ApiResult.success(
      data: AllProductsResponse(
        data: Data(
          all: [
            All(
              products: [
                Product(
                  id: _demoProduct.id,
                  uuid: _demoProduct.uuid,
                  shopId: _demoProduct.shopId,
                  img: _demoProduct.img,
                  translation: _demoProduct.translation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getDiscountProducts({
    String? shopId,
    String? brandId,
    String? categoryId,
    int? page,
  }) async {
    return getProductsPaginate(page: 1);
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getNewProducts({
    String? shopId,
    String? brandId,
    String? categoryId,
    int? page,
  }) async {
    return getProductsPaginate(page: 1);
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsByCategoryPaginate({
    String? shopId,
    required int page,
    required String categoryId,
  }) async {
    return getProductsPaginate(
      page: page,
      shopId: shopId,
      categoryId: categoryId,
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsByIds(
    List<String> ids,
  ) async {
    return getProductsPaginate(page: 1);
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProductsPopularPaginate({
    String? shopId,
    required int page,
  }) async {
    return getProductsPaginate(page: page, shopId: shopId);
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
      page: page,
      shopId: shopId,
      categoryId: categoryId,
    );
  }

  @override
  Future<ApiResult<ProductsPaginateResponse>> getProfitableProducts({
    String? brandId,
    String? categoryId,
    int? page,
  }) async {
    return getProductsPaginate(page: 1);
  }
}
