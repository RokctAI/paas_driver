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
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:base_sdk/src/services/demo_session.dart';
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
///
/// The demo twins follow the RUNTIME demo switch, base_sdk's
/// [DemoSession.demoActive] (a demo build OR a demo session): the
/// facades are chosen by that read at registration, and the one listener
/// this hook adds to [DemoSession.instance] swaps them again when the
/// switch flips - after a demo account's login, before routing, and back
/// on sign-out. Only registrations this hook made are ever swapped; a
/// facade a host registered itself is left alone.
class ProductsSdkDependencies {
  /// The container the last [register] call wired; the listener re-wires
  /// the same one. Null until the first call, so a flip that lands before
  /// any registration is a no-op and the registration then reads the
  /// switch itself.
  static GetIt? _container;

  /// Guards the listener against being added twice.
  static bool _listening = false;

  /// The instances this hook registered (weak), so a flip replaces exactly
  /// those and never a host's own registration.
  static final Expando<bool> _ours = Expando<bool>();

  static void register(GetIt getIt) {
    _container = getIt;
    _registerDemoTwins(getIt, replace: false);
    if (!getIt.isRegistered<GalleryRepositoryFacade>()) {
      getIt.registerSingleton<GalleryRepositoryFacade>(GalleryRepository());
    }
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
    if (!_listening) {
      _listening = true;
      DemoSession.instance.addListener(_onDemoSessionChanged);
    }
  }

  /// The facades that have a demo twin. The customer-facing catalog
  /// (products, categories, brands) and the seller/manager product
  /// authoring seams - the latter registered for every app that composes
  /// products_sdk (a non-manager app simply never resolves them): a demo
  /// build or a demo session serves a seeded fictional menu from memory so
  /// the manager foods tab and its category/unit pickers render stocked
  /// with zero backend contact. The production path is untouched.
  /// `replace` is false at boot (an existing registration wins, as before)
  /// and true on a flip. Nothing here can throw: unregister runs only
  /// behind `isRegistered`, and a fresh registration never collides.
  static void _registerDemoTwins(GetIt getIt, {required bool replace}) {
    final bool demo = DemoSession.demoActive;
    _put<ProductsRepositoryFacade>(
      getIt,
      () => demo ? MockProductsRepository() : ProductsRepository(),
      replace: replace,
    );
    _put<CategoriesRepositoryFacade>(
      getIt,
      () => demo ? MockCategoriesRepository() : CategoriesRepository(),
      replace: replace,
    );
    _put<BrandsRepositoryFacade>(
      getIt,
      () => demo ? MockBrandsRepository() : BrandsRepository(),
      replace: replace,
    );
    _put<SellerProductsRepositoryFacade>(
      getIt,
      () => demo ? DemoSellerProductsRepository() : SellerProductsRepository(),
      replace: replace,
    );
    _put<SellerCatalogRepositoryFacade>(
      getIt,
      () => demo ? DemoSellerCatalogRepository() : SellerCatalogRepository(),
      replace: replace,
    );
  }

  static void _put<T extends Object>(
    GetIt getIt,
    T Function() build, {
    required bool replace,
  }) {
    if (getIt.isRegistered<T>()) {
      if (!replace || _ours[getIt<T>()] != true) return;
      getIt.unregister<T>();
    }
    final T instance = build();
    _ours[instance] = true;
    getIt.registerSingleton<T>(instance);
  }

  static void _onDemoSessionChanged() {
    final GetIt? getIt = _container;
    if (getIt == null) return;
    _registerDemoTwins(getIt, replace: true);
  }
}
