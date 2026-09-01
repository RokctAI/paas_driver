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
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/demo_seller_orders_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/pos_products_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/seller_orders_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/collect_conversion_sync_handler.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/order_create_sync_handler.dart';

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
    // Demo-gated like merchants_sdk's POS seams and products_sdk's catalog
    // facades: --dart-define=IS_DEMO=true serves a seeded shift of seller
    // orders from memory, so the manager order board and /order-history
    // render stocked with zero backend contact instead of capturing their
    // empty states. The production path is untouched.
    if (!getIt.isRegistered<SellerOrdersRepositoryFacade>()) {
      getIt.registerSingleton<SellerOrdersRepositoryFacade>(
        AppConstants.isDemo
            ? DemoSellerOrdersRepository()
            : SellerOrdersRepository(),
      );
    }
    if (!getIt.isRegistered<PosProductsRepositoryFacade>()) {
      getIt.registerSingleton<PosProductsRepositoryFacade>(
        PosProductsRepository(),
      );
    }
    // Attach the order.create push handler so offline POS sales drain to
    // the backend (auth_di's AuthSyncHandler pattern). Registered here
    // rather than in the common OrdersSdkDependencies because a customer
    // app's cache has lib/src/manager/ stripped, so the common hook cannot
    // import this slice. BaseSdkDependencies.register puts the engine in
    // get_it before feature SDKs run; the process-singleton fallback keeps
    // hand-wired hosts that skipped it working. registerHandler replaces
    // any previous handler, so this is idempotent too. Requires
    // base_sdk >= 1.5.0 (SyncEngine/SyncHandler).
    final engine =
        getIt.isRegistered<SyncEngine>() ? getIt<SyncEngine>() : SyncEngine();
    engine.registerHandler(
      OrderCreateSyncHandler.opType,
      OrderCreateSyncHandler(),
    );
    // ... and the collected-in-person conversion (section 43): the goods
    // go over the counter offline too, so the conversion itself has to be
    // able to run later. A backend refusal parks in Sync issues.
    engine.registerHandler(
      CollectConversionSyncHandler.opType,
      CollectConversionSyncHandler(),
    );
  }
}
