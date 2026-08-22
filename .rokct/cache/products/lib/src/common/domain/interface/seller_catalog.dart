// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Contract for the seller/manager catalogue surface: the product categories
/// and units a shop owner manages, as distinct from the public category
/// browsing `CategoriesRepositoryFacade` (base_sdk) covers.
///
/// Kept separate from [SellerProductsRepositoryFacade] because `paas_manager`
/// had it separate too (`catalog_repository` vs `products_repository`) and the
/// two are independently useful — the units picker needs catalogue access
/// without any product-authoring capability.
///
/// In `common/` because it is a host-implemented seam; its DTOs likewise.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_categories_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_units_paginate_response.dart';

abstract class SellerCatalogRepositoryFacade {
  Future<ApiResult<SellerUnitsPaginateResponse>> getUnits();

  /// `type: main`, active only — the categories a product can be filed under.
  Future<ApiResult<SellerCategoriesPaginateResponse>> getCategories({
    int? page,
    String? query,
  });

  /// `type: main`, no active filter — the shop's own category list, including
  /// inactive ones, for management screens.
  Future<ApiResult<SellerCategoriesPaginateResponse>> getShopCategories({
    int? page,
    String? query,
  });

  /// `type: sub_shop`, active only.
  Future<ApiResult<SellerCategoriesPaginateResponse>> getCategoriesSub({
    int? page,
    String? query,
  });

  Future<ApiResult<void>> createCategory({
    required String title,
    required String input,
  });

  Future<ApiResult<void>> deleteCategory({required int? id});
}
