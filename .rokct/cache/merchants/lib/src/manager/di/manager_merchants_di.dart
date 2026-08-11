import 'package:get_it/get_it.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_sections_tables.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/seller_sections_tables_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/seller_shop_repository.dart';

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
  }
}
