import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_customers.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_sections_tables.dart';
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        // Recorded gap: seller_operations.py has menus/kitchens/receipts but
        // no shop-section listing yet.
        '/api/method/paas.api.seller_operations.seller_operations.get_seller_sections',
        queryParameters: {
          if (page != null) 'page': page,
          if (query != null && query.isNotEmpty) 'search': query,
        },
      );
      return ApiResult.success(
        data: ShopSectionResponse.fromJson(response.data),
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
    int? shopSectionId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        // Recorded gap: no seller table listing endpoint yet.
        '/api/method/paas.api.seller_operations.seller_operations.get_seller_tables',
        queryParameters: {
          if (page != null) 'page': page,
          if (query != null && query.isNotEmpty) 'search': query,
          if (shopSectionId != null) 'shop_section_id': shopSectionId,
        },
      );
      return ApiResult.success(data: TableResponse.fromJson(response.data));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}

class ManagerPosCustomersAdapter implements PosCustomersFacade {
  @override
  Future<ApiResult<UsersPaginateResponse>> searchUsers({
    String? query,
    int? page,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        // users_sdk's search endpoint (its Dart facade is S-2; swap to it
        // once merged).
        '/api/method/paas.api.user.user.search_users',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'search': query,
          if (page != null) 'page': page,
        },
      );
      return ApiResult.success(
        data: UsersPaginateResponse.fromJson(response.data),
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
