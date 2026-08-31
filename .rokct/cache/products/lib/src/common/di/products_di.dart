// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/products_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/mock_products_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/categories_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/mock_categories_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/brands_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/mock_brands_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/gallery_repository.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/demo_seller_catalog_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/demo_seller_products_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/seller_catalog_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/seller_products_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/services/product_create_sync_handler.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `ProductsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class ProductsSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<ProductsRepositoryFacade>()) {
      getIt.registerSingleton<ProductsRepositoryFacade>(
        AppConstants.isDemo ? MockProductsRepository() : ProductsRepository(),
      );
    }
    if (!getIt.isRegistered<CategoriesRepositoryFacade>()) {
      getIt.registerSingleton<CategoriesRepositoryFacade>(
        AppConstants.isDemo ? MockCategoriesRepository() : CategoriesRepository(),
      );
    }
    if (!getIt.isRegistered<BrandsRepositoryFacade>()) {
      getIt.registerSingleton<BrandsRepositoryFacade>(
        AppConstants.isDemo ? MockBrandsRepository() : BrandsRepository(),
      );
    }
    if (!getIt.isRegistered<GalleryRepositoryFacade>()) {
      getIt.registerSingleton<GalleryRepositoryFacade>(GalleryRepository());
    }
  
    // Seller/manager product authoring. Registered for every app that
    // composes products_sdk: a non-manager app simply never resolves it.
    // Demo-gated like the customer-facing facades above —
    // --dart-define=IS_DEMO=true serves a seeded fictional menu from memory
    // so the manager foods tab and its category/unit pickers render stocked
    // with zero backend contact. The production path is untouched.
    if (!getIt.isRegistered<SellerProductsRepositoryFacade>()) {
      getIt.registerSingleton<SellerProductsRepositoryFacade>(
        AppConstants.isDemo
            ? DemoSellerProductsRepository()
            : SellerProductsRepository(),
      );
    }
    if (!getIt.isRegistered<SellerCatalogRepositoryFacade>()) {
      getIt.registerSingleton<SellerCatalogRepositoryFacade>(
        AppConstants.isDemo
            ? DemoSellerCatalogRepository()
            : SellerCatalogRepository(),
      );
    }
    // Attach the product.create push handler so offline product creates
    // drain to the backend (auth_di's AuthSyncHandler pattern).
    // BaseSdkDependencies.register puts the engine in get_it before feature
    // SDKs run; the process-singleton fallback keeps hand-wired hosts that
    // skipped it working. registerHandler replaces any previous handler, so
    // this is idempotent too. Requires base_sdk >= 1.5.0
    // (SyncEngine/SyncHandler).
    final engine =
        getIt.isRegistered<SyncEngine>() ? getIt<SyncEngine>() : SyncEngine();
    engine.registerHandler(
      ProductCreateSyncHandler.opType,
      ProductCreateSyncHandler(),
    );
}
}
