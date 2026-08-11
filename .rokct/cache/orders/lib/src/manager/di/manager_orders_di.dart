import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/pos_products_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/seller_orders_repository.dart';

/// Manager-role DI hook (revenue_sdk's `ManagerRevenueDependencies` pattern).
///
/// Not exported by the barrel and not called by the generated `main.dart` —
/// the common `OrdersSdkDependencies.register` cannot import this file because
/// a customer app's cache has `lib/src/manager/` stripped. A manager host
/// calls this from its own DI setup, importing it via this direct `src/` path,
/// before any installed orders page first builds a provider (they resolve
/// these facades from GetIt). Registers idempotently so hand-wired hosts can
/// call it too.
///
/// Only the facades orders_sdk itself implements are registered here. The two
/// ADR-005 seams — [PosSectionsTablesFacade] and [PosCustomersFacade] — are
/// the host's to supply via the installed
/// `lib/presentation/routes/orders_adapters.dart` (see that file's doc
/// comment); their providers fall back to a failing stand-in when unwired.
class ManagerOrdersDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<SellerOrdersRepositoryFacade>()) {
      getIt.registerSingleton<SellerOrdersRepositoryFacade>(
        SellerOrdersRepository(),
      );
    }
    if (!getIt.isRegistered<PosProductsRepositoryFacade>()) {
      getIt.registerSingleton<PosProductsRepositoryFacade>(
        PosProductsRepository(),
      );
    }
  }
}
