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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/categories_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/products_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_product_response.dart';

/// The POS create-order flow's read-only view of the seller's catalogue:
/// the product grid and its category tabs.
///
/// Owned and implemented by orders_sdk ([PosProductsRepository]) against the
/// same `seller_product.py` endpoints products_sdk's authoring repositories
/// use. ADR-005 keeps orders_sdk from importing products_sdk, so the POS
/// carries its own read models ([ProductData]/[Stock] in this package, the
/// classes products_sdk ported as `SellerProductData`/`SellerStock`) — that
/// twin-model situation is recorded in `docs/frappe-endpoint-contract.md` as
/// a dedup candidate, not resolved here.
///
/// The legacy `ProductStatus` enum is collapsed to the wire string it always
/// became ('published' / 'pending' / 'unpublished'), the same call products_sdk
/// made in its facade.
abstract class PosProductsRepositoryFacade {
  Future<ApiResult<ProductsPaginateResponse>> getProducts({
    bool active = true,
    int? page,
    String? categoryId,
    String? query,
    String? status,
  });

  Future<ApiResult<CategoriesPaginateResponse>> getShopCategories({int? page});

  Future<ApiResult<SingleProductResponse>> getProductDetails(String uuid);
}
