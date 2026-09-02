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

  /// [id] is the category's `uuid` (the lookup key
  /// `delete_seller_category(uuid)` resolves), falling back to the Category
  /// docname string. Callers must abort with a debug log when neither is
  /// available — never send a numeric or empty sentinel.
  Future<ApiResult<void>> deleteCategory({required String id});
}
