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

// The POS till's test doubles, and one call that wires a till the way a
// demo session does. The shop and the Quick flow settings a DI-built till
// reads come from the real repositories answered by the demo fixtures
// (support/demo_fixtures.dart); the catalog (products_sdk's facades in a
// composed app, not a dependency of this package), the checkout's order
// seam (the HOST's adapter) and a writable Quick flow store are doubles
// carrying the same demo data.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/categories_paginate_response.dart';
import 'package:base_sdk/src/models/response/products_paginate_response.dart';
import 'package:get_it/get_it.dart';
import 'package:merchants_sdk/src/manager/di/manager_merchants_di.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_orders.dart';
import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';

import 'demo_fixtures.dart';

/// Starts a demo session (keeping LocalStorage as the test left it) and
/// registers the manager DI with the till doubles in front of it.
Future<void> registerDemoTill({GetIt? getIt}) async {
  final GetIt container = getIt ?? GetIt.instance;
  await startDemoFixtures(resetStorage: false);
  if (!container.isRegistered<PosCatalogRepositoryFacade>()) {
    container.registerSingleton<PosCatalogRepositoryFacade>(DemoTillCatalog());
  }
  if (!container.isRegistered<PosOrdersFacade>()) {
    container.registerSingleton<PosOrdersFacade>(DemoTillOrders());
  }
  if (!container.isRegistered<QuickFlowRepositoryFacade>()) {
    container.registerSingleton<QuickFlowRepositoryFacade>(
      InMemoryQuickFlowRepository(),
    );
  }
  ManagerMerchantsDependencies.register(container);
}

/// The demo shop's till catalog: Mains / Sides / Drinks, and the
/// flame-grilled beef burger (R150.00) in Mains.
class DemoTillCatalog implements PosCatalogRepositoryFacade {
  static const String mainsCategoryId = '1';

  static final List<CategoryData> demoCategories = <CategoryData>[
    _category(mainsCategoryId, 'Mains'),
    _category('2', 'Sides'),
    _category('3', 'Drinks'),
  ];

  static CategoryData _category(String id, String title) => CategoryData(
    id: id,
    uuid: 'demo_category_$id',
    parentId: '0',
    type: 'main',
    active: true,
    translation: Translation(title: title, locale: 'en'),
  );

  static final ProductData demoProduct = ProductData(
    id: '1',
    uuid: 'demo_product_uuid',
    shopId: '1',
    categoryId: mainsCategoryId,
    active: true,
    translation: Translation(
      title: 'Flame-grilled beef burger',
      description: 'Flame-grilled beef patty, toasted bun, house sauce',
      locale: 'en',
    ),
    stocks: [Stocks(id: '1', price: 150, quantity: 100, totalPrice: 150)],
  );

  @override
  Future<ApiResult<ProductsPaginateResponse>> searchProducts({
    required String text,
    int page = 1,
    String? categoryId,
  }) async {
    final bool inCategory =
        categoryId == null || categoryId == demoProduct.categoryId;
    return ApiResult.success(
      data: ProductsPaginateResponse(
        data: inCategory ? [demoProduct] : const <ProductData>[],
      ),
    );
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> categories() async {
    return ApiResult.success(
      data: CategoriesPaginateResponse(data: demoCategories),
    );
  }
}

/// The checkout's order seam with the demo customer, recording the sales
/// it is handed.
class DemoTillOrders implements PosOrdersFacade {
  static const PosCustomer demoCustomer = PosCustomer(
    id: 'demo-customer',
    firstname: 'Thabo',
    lastname: 'Mokoena',
    phone: '072 114 8890',
  );

  static const double demoOutstanding = 89.50;

  final List<PosSaleDraft> submitted = [];

  @override
  Future<ApiResult<List<PosCustomer>>> searchCustomers({
    String? query,
    int page = 1,
  }) async {
    final q = (query ?? '').trim().toLowerCase();
    final match =
        q.isEmpty ||
        demoCustomer.fullName.toLowerCase().contains(q) ||
        (demoCustomer.phone ?? '').replaceAll(' ', '').contains(q);
    return ApiResult.success(data: match ? const [demoCustomer] : const []);
  }

  @override
  Future<double?> customerCreditOutstanding(String customerId) async =>
      customerId == demoCustomer.id ? demoOutstanding : 0;

  @override
  Future<ApiResult<String>> submitSale(PosSaleDraft draft) async {
    submitted.add(draft);
    return ApiResult.success(data: 'offline:demo-${submitted.length}');
  }

  @override
  Future<int> pendingSaleCount() async => submitted.length;
}

/// A Quick flow store that keeps its writes, seeded with the section-42
/// demo shop (the same settings the demo fixtures serve).
class InMemoryQuickFlowRepository implements QuickFlowRepositoryFacade {
  InMemoryQuickFlowRepository() : _settings = seed;

  QuickFlowSettings _settings;

  static ProductData _product(String id, String title, num price) =>
      ProductData(
        id: id,
        shopId: '1',
        active: true,
        translation: Translation(title: title, locale: 'en'),
        stocks: [
          Stocks(id: id, price: price, quantity: 100, totalPrice: price),
        ],
      );

  static QuickFlowSettings get seed => QuickFlowSettings(
    shopName: 'Blue Tap Water Refill',
    autoAcceptOrders: true,
    platformAutoApprove: true,
    autoCompleteAtReady: false,
    keypadAutodial: true,
    presets: [
      QuickFlowPreset(digit: 1, product: _product('1', '5 L refill', 12)),
      QuickFlowPreset(digit: 2, product: _product('2', '10 L refill', 20)),
      QuickFlowPreset(digit: 3, product: _product('3', '20 L refill', 35)),
      QuickFlowPreset(digit: 4, product: _product('4', '25 L bottle swap', 45)),
      QuickFlowPreset(digit: 5, product: _product('5', 'Ice · 2 kg', 28)),
    ],
  );

  @override
  Future<ApiResult<QuickFlowSettings>> getQuickFlowSettings() async =>
      ApiResult.success(data: _settings);

  @override
  Future<ApiResult<QuickFlowSettings>> updateQuickFlowSettings({
    bool? autoAcceptOrders,
    bool? autoCompleteAtReady,
    bool? keypadAutodial,
    List<QuickFlowPreset>? presets,
  }) async {
    _settings = _settings.copyWith(
      autoAcceptOrders: autoAcceptOrders,
      autoCompleteAtReady: autoCompleteAtReady,
      keypadAutodial: keypadAutodial,
      presets: presets,
    );
    return ApiResult.success(data: _settings);
  }
}
