import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_sections_tables.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';
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
    if (!getIt.isRegistered<SellerShopRepositoryFacade>()) {
      getIt.registerSingleton<SellerShopRepositoryFacade>(
        SellerShopRepository(),
      );
    }
    if (!getIt.isRegistered<SellerSectionsTablesRepositoryFacade>()) {
      getIt.registerSingleton<SellerSectionsTablesRepositoryFacade>(
        SellerSectionsTablesRepository(),
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
