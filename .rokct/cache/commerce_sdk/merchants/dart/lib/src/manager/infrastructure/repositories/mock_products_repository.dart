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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/products_paginate_response.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';

/// Demo-mode POS catalog (`--dart-define=IS_DEMO=true` routes the till's
/// barcode lookup here, `ManagerMerchantsDependencies.register`): any
/// barcode or search text resolves to one "Demo Product" at 150.00, the
/// same demo identity products_sdk's mock serves — so headless tours and
/// the standalone test harness scan, cart and check out with zero backend
/// contact.
class MockProductsRepository implements PosCatalogRepositoryFacade {
  static final ProductData demoProduct = ProductData(
    id: '1',
    uuid: 'demo_product_uuid',
    shopId: '1',
    active: true,
    translation: Translation(
      title: 'Demo Product',
      description: 'This is a demo product description',
      locale: 'en',
    ),
    stocks: [Stocks(id: '1', price: 150, quantity: 100, totalPrice: 150)],
  );

  @override
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int page = 1,
  }) async {
    return ApiResult.success(
      data: ProductsPaginateResponse(data: [demoProduct]),
    );
  }
}
