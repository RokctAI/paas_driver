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
