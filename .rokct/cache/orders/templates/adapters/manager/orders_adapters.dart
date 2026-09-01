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

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:get_it/get_it.dart';
import 'package:merchants_sdk/src/manager/utils/pos_receipt_printer.dart';
import 'package:orders_sdk/src/manager/domain/interface/order_receipt.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_customers.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_sections_tables.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/shop_section_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_user_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/table_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/users_paginate_response.dart';

/// Host-side wiring for orders_sdk's manager POS seams (ADR-005, the zones_sdk
/// `zones_adapters.dart` precedent).
///
/// orders_sdk owns the POS screens (section/table pickers, walk-in customer
/// picker) but must not import the SDKs that own the data — merchants_sdk
/// (shop sections/tables) and users_sdk (customers). It declares
/// [PosSectionsTablesFacade] and [PosCustomersFacade] in its own terms and the
/// manager host supplies both. This file is host-composition code: it lives in
/// templates/ and installs into the app at compose time (manager flavour only,
/// see manifest.json app_type.manager), which is why it may reference any
/// composed SDK. The validator scans SDK lib/ only, so nothing here is a
/// cross-SDK import violation.
///
/// Register both in the host's main(), OUTSIDE the @generated-sdk-di markers,
/// after ManagerOrdersDependencies.register:
///
///   ManagerOrdersDependencies.register(GetIt.instance);
///   GetIt.instance.registerLazySingleton<PosSectionsTablesFacade>(
///       () => ManagerPosSectionsTablesAdapter());
///   GetIt.instance.registerLazySingleton<PosCustomersFacade>(
///       () => ManagerPosCustomersAdapter());
///   GetIt.instance.registerLazySingleton<OrderReceiptFacade>(
///       () => ManagerOrderReceiptAdapter());
///
/// Without these registrations the section/table/customer providers fall back
/// to a 501 "not wired" stand-in and the POS shipping flow surfaces a named
/// failure instead of data.
///
/// TRANSITIONAL STATE — both adapters currently call the target Frappe
/// endpoints directly, because neither owner exposes a Dart facade yet:
/// merchants_sdk has no sections/tables repository (S-11 in the fork plan) and
/// users_sdk is repositories-only with no seller-scoped search/create
/// (S-2 + a recorded backend gap for walk-in customer creation, see
/// orders_sdk/docs/frappe-endpoint-contract.md). When those land, each
/// adapter body collapses to a delegation onto the owner SDK's facade — the
/// method shapes below were chosen to make that a mechanical swap.
class ManagerPosSectionsTablesAdapter implements PosSectionsTablesFacade {
  @override
  Future<ApiResult<ShopSectionResponse>> getSections({
    int? page,
    String? query,
  }) async {
    try {
      // merchants' seller_operations.get_seller_sections via the universal
      // platform gateway (whitelisted-method key registered alongside this
      // change in merchants/frappe/manifest.json).
      final response = await const PlatformGateway().tenant(
        'api.seller_operations.get_seller_sections',
        {
          if (page != null) 'page': page,
          if (query != null && query.isNotEmpty) 'search': query,
        },
      );
      return ApiResult.success(
        data: ShopSectionResponse.fromJson(response),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<TableResponse>> getTables({
    int? page,
    String? query,
    String? shopSectionId,
  }) async {
    try {
      // merchants' seller_operations.get_seller_tables via the universal
      // platform gateway (whitelisted-method key registered alongside this
      // change in merchants/frappe/manifest.json).
      final response = await const PlatformGateway().tenant(
        'api.seller_operations.get_seller_tables',
        {
          if (page != null) 'page': page,
          if (query != null && query.isNotEmpty) 'search': query,
          if (shopSectionId != null) 'shop_section_id': shopSectionId,
        },
      );
      return ApiResult.success(data: TableResponse.fromJson(response));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}

class ManagerPosCustomersAdapter implements PosCustomersFacade {
  /// Mirrors the backend's `limit_page_length` default.
  static const int _pageSize = 20;

  @override
  Future<ApiResult<UsersPaginateResponse>> searchUsers({
    String? query,
    int? page,
  }) async {
    try {
      // merchants' shop-scoped seller_shop_settings.get_shop_users via the
      // universal platform gateway (whitelisted-method key already
      // registered in merchants/frappe/manifest.json). Shop-scoped is the
      // pre-fork behavior: a manager only ever sees their own shop's users.
      final response = await const PlatformGateway().tenant(
        'api.seller_shop_settings.get_shop_users',
        {
          if (query != null && query.isNotEmpty) 'search': query,
          if (page != null) 'limit_start': (page - 1) * _pageSize,
          'limit_page_length': _pageSize,
        },
      );
      // The endpoint keeps the legacy bare-list shape; wrap it into the
      // paginate envelope the POS model expects.
      return ApiResult.success(
        data: UsersPaginateResponse.fromJson(
          response is List ? {'data': response} : response,
        ),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleUserResponse>> createUser({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        // Recorded backend gap: register_user is self-signup; a seller-scoped
        // walk-in-customer create does not exist yet. This call fails visibly
        // (ApiResult.failure) until it lands.
        '/api/method/paas.api.user.user.create_walk_in_customer',
        data: {
          'firstname': firstname,
          'lastname': lastname,
          'phone': phone,
          'email': email,
        },
      );
      return ApiResult.success(
        data: SingleUserResponse.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}


/// Host wiring for the order detail's RECEIPT REPRINT (approved frame 38a
/// amendment, Ray 2026-08-30 12:23Z: "receipt reprint action in the order
/// detail (wired to the till receipt path)").
///
/// The till receipt path is merchants_sdk's [PosReceiptPrinter] — the
/// same seam the POS checkout's "Print Receipt & Finish" prints through,
/// so a reprint comes out of the same hardware, formatted the same way.
/// orders_sdk must not import merchants_sdk, so it declares
/// [OrderReceiptFacade] in its own terms and this host file binds them
/// (ADR-005; templates/ is host-composition code, which is why it may
/// reference both SDKs).
///
/// [isAvailable] follows the printer's own installation state: with no
/// `PosReceiptPrinter.handler` installed the app has no printing
/// hardware, and the order detail simply does not offer the action.
class ManagerOrderReceiptAdapter implements OrderReceiptFacade {
  @override
  bool get isAvailable => PosReceiptPrinter.handler != null;

  @override
  Future<void> reprint(OrderData order) {
    final lines = <PosReceiptLine>[
      for (final detail in order.details ?? <OrderDetail>[])
        PosReceiptLine(
          title:
              detail.stock?.product?.translation?.title ??
              detail.stock?.countable?.translation?.title ??
              '',
          quantity: (detail.quantity ?? 0).toDouble(),
          lineTotal: (detail.totalPrice ?? 0).toDouble(),
        ),
    ];
    return PosReceiptPrinter.print(
      order.id ?? '',
      lines,
      (order.totalPrice ?? 0).toDouble(),
    );
  }
}
