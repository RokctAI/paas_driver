// Copyright (c) 2026 RokctAI
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
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/pos_products_repository.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/seller_orders_repository.dart';
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
  }
}
