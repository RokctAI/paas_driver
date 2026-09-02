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

import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/response/products_paginate_response.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';

/// Real POS catalog: delegates to the composed app's registered
/// [ProductsRepositoryFacade] (products_sdk registers it in every manager
/// compose — the foods tab needs it — routed through the universal
/// platform gateway). Resolved lazily per call so registration order
/// between SDK DI hooks doesn't matter.
class PosCatalogRepository implements PosCatalogRepositoryFacade {
  @override
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int page = 1,
  }) =>
      GetIt.instance<ProductsRepositoryFacade>()
          .searchProducts(text: text, page: page);
}
