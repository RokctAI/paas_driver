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
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_orders.dart';
import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_sections_tables.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/demo_seller_shop_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/mock_pos_orders_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/mock_products_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/mock_quick_flow_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/pos_catalog_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/quick_flow_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/seller_sections_tables_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/seller_shop_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/services/shop_create_sync_handler.dart';
import 'package:merchants_sdk/src/manager/infrastructure/services/sync_issues_service.dart';

/// Manager-role DI hook (orders_sdk `ManagerOrdersDependencies` /
/// revenue_sdk `ManagerRevenueDependencies` pattern).
///
/// Not exported by the barrel and not called by the generated `main.dart` —
/// the common `MerchantsSdkDependencies.register` cannot import this file
/// because a customer app's cache has `lib/src/manager/` stripped. A manager
/// host calls this from its own DI setup via this direct `src/` path, before
/// any installed restaurant page first builds a provider. Registers
/// idempotently so hand-wired hosts can call it too.
///
/// [SellerSectionsTablesRepositoryFacade] is also the data source the host's
/// installed `orders_adapters.dart` (`ManagerPosSectionsTablesAdapter`,
/// ADR-005) should delegate to once it swaps off its transitional direct
/// endpoint calls — register this before that adapter.
class ManagerMerchantsDependencies {
  static void register(GetIt getIt) {
    // The manager's own shop identity (restaurant hub header, shop-edit
    // flow, open/closed switch). Demo-gated like the POS seams below:
    // --dart-define=IS_DEMO=true serves MockShopsRepository's demoShop --
    // the SAME shop the customer-facing ShopsRepositoryFacade serves in
    // demo builds, not a second invention -- so the hub renders with a shop
    // instead of a blank header, with zero backend contact.
    if (!getIt.isRegistered<SellerShopRepositoryFacade>()) {
      getIt.registerSingleton<SellerShopRepositoryFacade>(
        AppConstants.isDemo
            ? DemoSellerShopRepository()
            : SellerShopRepository(),
      );
    }
    if (!getIt.isRegistered<SellerSectionsTablesRepositoryFacade>()) {
      getIt.registerSingleton<SellerSectionsTablesRepositoryFacade>(
        SellerSectionsTablesRepository(),
      );
    }
    // The POS till's product-lookup seam (BillingPage barcode scans and
    // the Add Items lane). Demo-gated like MerchantsSdkDependencies'
    // ShopsRepositoryFacade: --dart-define=IS_DEMO=true routes lookups to
    // this SDK's MockProductsRepository ("Demo Product", 150.00) so
    // headless tours and the standalone POS test harness run with zero
    // backend contact; otherwise the real repository delegates to the
    // composed app's ProductsRepositoryFacade (products_sdk's, resolved
    // lazily per call).
    if (!getIt.isRegistered<PosCatalogRepositoryFacade>()) {
      getIt.registerSingleton<PosCatalogRepositoryFacade>(
        AppConstants.isDemo ? MockProductsRepository() : PosCatalogRepository(),
      );
    }
    // The POS checkout's order seam (customer attach, credit outstanding,
    // and the cart -> create-order handoff into the seller pipeline).
    // Demo builds get this SDK's mock so tours and the standalone harness
    // run the full checkout with zero backend contact. REAL registration
    // is the HOST's: the installed ManagerPosOrdersAdapter
    // (templates/adapters/manager/pos_orders_adapter.dart) delegates to
    // orders_sdk, which this lib must not import (ADR-005). Unregistered,
    // the checkout degrades honestly — no customer/credit surface, sales
    // complete locally only.
    if (AppConstants.isDemo && !getIt.isRegistered<PosOrdersFacade>()) {
      getIt.registerSingleton<PosOrdersFacade>(MockPosOrdersRepository());
    }
    // Quick flow settings (design strip section 42): the shop's three
    // order-automation switches and the till keypad's digit->product map,
    // read by BOTH the Quick flow page and the till (the pad arms off the
    // same provider). Demo-gated like the catalog seam: --dart-define=
    // IS_DEMO=true serves the section-42 seed shop from memory so headless
    // tours and the standalone harness drive the whole surface, and the
    // till's autodial, with zero backend contact.
    if (!getIt.isRegistered<QuickFlowRepositoryFacade>()) {
      getIt.registerSingleton<QuickFlowRepositoryFacade>(
        AppConstants.isDemo
            ? MockQuickFlowRepository()
            : QuickFlowRepository(),
      );
    }
    // Attach the shop.create push handler so offline shop creates drain to
    // the backend (auth_di's AuthSyncHandler pattern). Registered here rather
    // than in the common MerchantsSdkDependencies because a customer app's
    // cache has lib/src/manager/ stripped, so the common hook cannot import
    // this slice. BaseSdkDependencies.register puts the engine in get_it
    // before feature SDKs run; the process-singleton fallback keeps
    // hand-wired hosts that skipped it working. registerHandler replaces any
    // previous handler, so this is idempotent too. Requires
    // base_sdk >= 1.5.0 (SyncEngine/SyncHandler).
    final engine =
        getIt.isRegistered<SyncEngine>() ? getIt<SyncEngine>() : SyncEngine();
    engine.registerHandler(ShopCreateSyncHandler.opType, ShopCreateSyncHandler());
    // Park-and-surface read API over the three manager local-first boxes.
    if (!getIt.isRegistered<SyncIssuesService>()) {
      getIt.registerLazySingleton<SyncIssuesService>(SyncIssuesService.new);
    }
  }
}
