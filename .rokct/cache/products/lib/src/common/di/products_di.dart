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
import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/products_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/categories_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/brands_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/gallery_repository.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/seller_catalog_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/seller_products_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/services/product_create_sync_handler.dart';

/// Host asset directory holding products_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/products`.
const String productsDemoFixtureDirectory = 'assets/demo/products';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `ProductsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// Demo runs the REAL repositories: base_sdk's DemoGatewayInterceptor
/// answers every platform cmd they send from the `<cmd>.json` fixtures in
/// [productsDemoFixtureDirectory] while DemoSession.demoActive (read per
/// request, so a demo account signing in later is honoured), and an
/// unknown cmd fails loudly with DemoFixtureMissing. The fixtures carry the
/// customer catalog (products, categories, brands) and the seller menu
/// (products, add-ons, extras groups, categories, units).
class ProductsSdkDependencies {
  static void register(GetIt getIt) {
    DemoFixtures.registerAssetDirectory(productsDemoFixtureDirectory);
    _put<ProductsRepositoryFacade>(getIt, ProductsRepository.new);
    _put<CategoriesRepositoryFacade>(getIt, CategoriesRepository.new);
    _put<BrandsRepositoryFacade>(getIt, BrandsRepository.new);
    // The seller/manager product authoring seams, registered for every app
    // that composes products_sdk (a non-manager app simply never resolves
    // them).
    _put<SellerProductsRepositoryFacade>(getIt, SellerProductsRepository.new);
    _put<SellerCatalogRepositoryFacade>(getIt, SellerCatalogRepository.new);
    _put<GalleryRepositoryFacade>(getIt, GalleryRepository.new);
    // Attach the product.create push handler so offline product creates
    // drain to the backend (auth_di's AuthSyncHandler pattern).
    // BaseSdkDependencies.register puts the engine in get_it before feature
    // SDKs run; the process-singleton fallback keeps hand-wired hosts that
    // skipped it working. registerHandler replaces any previous handler, so
    // this is idempotent too. Requires base_sdk >= 1.5.0
    // (SyncEngine/SyncHandler).
    final engine = getIt.isRegistered<SyncEngine>()
        ? getIt<SyncEngine>()
        : SyncEngine();
    engine.registerHandler(
      ProductCreateSyncHandler.opType,
      ProductCreateSyncHandler(),
    );
  }

  /// An existing registration (a host's own) wins.
  static void _put<T extends Object>(GetIt getIt, T Function() build) {
    if (!getIt.isRegistered<T>()) getIt.registerSingleton<T>(build());
  }
}
