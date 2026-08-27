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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/shop_section_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/table_response.dart';

/// Narrow seam for the POS dine-in flow's section/table pickers (ADR-005).
///
/// merchants_sdk owns shop sections and tables (`seller_operations` domain);
/// orders_sdk owns the `select_section_page` / `select_table_page` screens.
/// Neither may import the other, so orders_sdk declares the contract in its
/// own terms ([ShopSection]/[TableData] live in this package) and the manager
/// host installs an adapter (`templates/adapters/manager/orders_adapters.dart`)
/// that binds it to whatever repository actually serves the data — the
/// zones_sdk `DeliveryZonesFacade` precedent.
///
/// Deliberately narrower than `paas_manager`'s `TableInterface`: the POS flow
/// only ever lists sections and tables. Booking, statistics and CRUD stay with
/// the owner (merchants workstream); the unimplemented legacy calls are
/// recorded in `docs/frappe-endpoint-contract.md`.
abstract class PosSectionsTablesFacade {
  Future<ApiResult<ShopSectionResponse>> getSections({
    int? page,
    String? query,
  });

  Future<ApiResult<TableResponse>> getTables({
    int? page,
    String? query,
    String? shopSectionId,
  });
}

/// GetIt-or-stand-in resolution used by `sectionProvider`/`tableProvider`
/// (zones_sdk's `deliveryZoneProvider` fallback pattern): composing orders_sdk
/// without wiring the adapter degrades to a visible named failure instead of
/// crashing at startup or looking like an empty section list.
PosSectionsTablesFacade resolvePosSectionsTablesFacade() {
  final getIt = GetIt.instance;
  return getIt.isRegistered<PosSectionsTablesFacade>()
      ? getIt<PosSectionsTablesFacade>()
      : const _UnwiredPosSectionsTables();
}

class _UnwiredPosSectionsTables implements PosSectionsTablesFacade {
  const _UnwiredPosSectionsTables();

  static const _message =
      'No PosSectionsTablesFacade is registered: the host app has not '
      'installed/wired orders_adapters.dart to a sections/tables repository.';

  @override
  Future<ApiResult<ShopSectionResponse>> getSections({
    int? page,
    String? query,
  }) async =>
      const ApiResult.failure(error: _message, statusCode: 501);

  @override
  Future<ApiResult<TableResponse>> getTables({
    int? page,
    String? query,
    String? shopSectionId,
  }) async =>
      const ApiResult.failure(error: _message, statusCode: 501);
}
