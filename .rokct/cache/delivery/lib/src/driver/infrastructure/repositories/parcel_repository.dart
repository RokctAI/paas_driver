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

import 'package:flutter/material.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';
import 'package:base_sdk/src/models/response/parcel_paginate_response.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class CourierParcelRepository implements CourierParcelRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: delivery's
  /// `manifest.json` whitelisted-method keys
  /// (`{app_name}.api.driver_parcel.*`) with the app segment dropped.
  static const _cmd = 'api.driver_parcel';

  /// Prefix-free cmd base for the deliveryman-scoped reads
  /// (`{app_name}.api.delivery_man.*`), app segment dropped.
  static const _deliveryCmd = 'api.delivery_man';

  /// Rows fetched per page for the courier's own parcel list. Wider than the
  /// legacy `perPage: 10` on purpose: get_deliveryman_parcel_orders takes no
  /// status filter (a server-side kwarg is a pending owner decision), so the
  /// active/history split happens client-side on each fetched page - with a
  /// narrow window a page of closed parcels would read as "no active
  /// parcels" before the notifier ever asked for the next one.
  static const _perPage = 50;

  /// Parcel Order statuses each tab keeps, compared through
  /// [_normalizeStatus] so the doctype's Select labels ("On a way") and the
  /// legacy lowercase driver vocabulary ("on_a_way") are the same status.
  static const _activeStatuses = {'accepted', 'ready', 'on_a_way'};
  static const _historyStatuses = {'delivered'};

  static const _gateway = PlatformGateway();

  static String _normalizeStatus(dynamic status) =>
      (status?.toString() ?? '').trim().toLowerCase().replaceAll(' ', '_');

  /// One page of the session courier's own parcels through the gateway,
  /// reduced to the statuses (and optional delivery-date window) a tab
  /// shows. See [parseOwnParcels] for the row contract.
  Future<List<ParcelOrder>> _fetchOwnParcels(
    int page, {
    required Set<String> keep,
    DateTime? from,
    DateTime? to,
  }) async {
    final data = {
      'limit_start': (page - 1) * _perPage,
      'limit_page_length': _perPage,
    };
    final response = await _gateway.tenant(
      '$_deliveryCmd.get_deliveryman_parcel_orders',
      data,
    );
    return parseOwnParcels(response, keep: keep, from: from, to: to);
  }

  /// Turns get_deliveryman_parcel_orders' answer into the models a tab
  /// shows. The def returns a plain `frappe.get_list` row list (name,
  /// status, total_price, delivery_date); a `{data: [...]}` envelope is
  /// accepted too should it ever grow the paginate shape. Rows are keyed by
  /// docname (`name`) while base_sdk's ParcelOrder reads `id`, so the
  /// docname is mirrored under `id`. Statuses outside [keep] are dropped;
  /// with a [from]/[to] window only rows whose delivery_date falls inside
  /// it (both bound days inclusive, like the legacy date-only filter) stay.
  @visibleForTesting
  static List<ParcelOrder> parseOwnParcels(
    dynamic response, {
    required Set<String> keep,
    DateTime? from,
    DateTime? to,
  }) {
    final rows = response is Map ? response['data'] : response;
    if (rows is! List) return const [];
    final lower =
        from == null ? null : DateTime(from.year, from.month, from.day);
    final upper = to == null
        ? null
        : DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final orders = <ParcelOrder>[];
    for (final row in rows) {
      if (row is! Map) continue;
      if (!keep.contains(_normalizeStatus(row['status']))) continue;
      final order = ParcelOrder.fromJson({
        ...Map<String, dynamic>.from(row),
        'id': row['id'] ?? row['name'],
      });
      if (lower != null || upper != null) {
        final when = order.deliveryDate;
        if (when == null) continue;
        if (lower != null && when.isBefore(lower)) continue;
        if (upper != null && when.isAfter(upper)) continue;
      }
      orders.add(order);
    }
    return orders;
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getActiveOrders(int page) async {
    // Repointed from the dead legacy
    // `/api/v1/dashboard/deliveryman/parcel-orders/paginate?statuses[]=...`
    // path to the whitelisted Frappe def (delivery manifest key
    // `{app_name}.api.delivery_man.get_deliveryman_parcel_orders`) through
    // the universal platform gateway. The def lists the session courier's
    // own parcels (deliveryman == user) newest first with offset paging and
    // no status filter, so the legacy currency/lang knobs are dropped and
    // the accepted/ready/on-a-way split is applied client-side.
    try {
      final orders = await _fetchOwnParcels(page, keep: _activeStatuses);
      return ApiResult.success(data: orders);
    } catch (e) {
      debugPrint('==> get active orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getAvailableOrders(int page) async {
    // Deliberately NOT repointed in the 2026-09-02 gateway wave. The only
    // driver parcel list on the server, get_deliveryman_parcel_orders,
    // filters `deliveryman == session user`, so it can never answer this
    // tab's question (parcels with NO courier yet - the legacy
    // `empty-deliveryman=1`): routing it there would show the courier's own
    // ready parcels as "available", wrong data silently, which is worse
    // than the visible failure below. Needs an unassigned-parcels def (or
    // kwarg) on the delivery frappe half; owner decision pending. Until
    // then the call keeps failing visibly and the notifier's failure branch
    // handles it - see the fix-wave report, not deleted (flag, never
    // delete).
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()!.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'page': page,
      "status": "ready",
      "empty-deliveryman": 1,
      "perPage": 10,
      "delivery_type": "delivery"
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/parcel-orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ParcelPaginateResponse.fromJson(response.data).data ?? [],
      );
    } catch (e) {
      debugPrint('==> get canceled orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ParcelOrder>> showParcel(String id) async {
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/parcel-orders$id',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ParcelOrder.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get single order failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<ParcelOrder>>> getHistoryOrders(int page,
      {DateTime? start, DateTime? end}) async {
    // Same repoint as getActiveOrders (the legacy path filtered
    // `status=delivered` plus delivery_date_from/to). The def takes no date
    // kwargs either, so the window is applied client-side on
    // delivery_date, both bound days inclusive like the Laravel date-only
    // filter was.
    try {
      final orders = await _fetchOwnParcels(
        page,
        keep: _historyStatuses,
        from: start,
        to: end,
      );
      return ApiResult.success(data: orders);
    } catch (e) {
      debugPrint('==> get delivered orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> setCurrentOrder(String? orderId) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-orders/{id}/current` path
      // to the whitelisted Frappe def, through the universal platform
      // gateway (delivery's manifest registers the
      // `{app_name}.api.driver_parcel.set_current_parcel_order` alias).
      // The caller ignores the response body.
      await _gateway.tenant(
        '$_cmd.set_current_parcel_order',
        {'order_id': orderId},
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> get delivered orders failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> updateParcel(
      String? parcelId, String? status) async {
    try {
      // Rewired from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-orders/{id}/status/update`
      // path to the working Frappe convention, now through the universal
      // platform gateway. The backend normalizes the legacy lowercase
      // statuses ("delivered", "on_a_way", "canceled").
      await _gateway.tenant(
        '$_cmd.update_driver_parcel_order_status',
        {"order_id": parcelId, "status": status},
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('===> error statistics settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> confirmParcelCodCollection(
      String? parcelId, num amountReceived) async {
    try {
      // FrappeResponseInterceptor already unwraps the top-level `message`
      // key, so the gateway answer is the endpoint's payload itself.
      final response = await _gateway.tenant(
        '$_cmd.confirm_parcel_cod_collection',
        {"parcel_id": parcelId, "amount_received": amountReceived},
      );
      return ApiResult.success(data: response);
    } catch (e) {
      debugPrint('===> error confirm parcel cod collection $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<void>> addReviewParcel(
    String orderId, {
    required double rating,
    required String comment,
  }) async {
    final data = {
      'order_id': orderId,
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    };
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-orders/{id}/review` path
      // to the whitelisted Frappe def, through the universal platform
      // gateway (delivery's manifest registers the
      // `{app_name}.api.driver_parcel.add_parcel_order_review` alias);
      // signature: add_parcel_order_review(order_id, rating, comment).
      await _gateway.tenant(
        '$_cmd.add_parcel_order_review',
        data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add order review failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ParcelOrder>> setParcel(String parcelId) async {
    try {
      // Repointed from the dead legacy
      // `/api/v1/dashboard/deliveryman/parcel-order/{id}/attach/me` path
      // to the whitelisted Frappe def, through the universal platform
      // gateway (delivery's manifest registers the
      // `{app_name}.api.driver_parcel.attach_parcel_order_to_me` alias).
      // The def answers {"status": bool, "data": <raw doc dict>}; the
      // raw doc dict is not legacy ParcelOrder-shaped and the only
      // caller (home_notifier.setParcel) ignores the model, so an empty
      // ParcelOrder is returned on success instead of force-parsing it.
      final body = await _gateway.tenant(
        '$_cmd.attach_parcel_order_to_me',
        {'order_id': parcelId},
      );
      if (body is! Map || body['status'] != true) {
        // Parcel gone or already attached to another courier.
        return ApiResult.failure(
          error: 'Parcel order is no longer available',
          statusCode: 0,
        );
      }
      return ApiResult.success(
        data: ParcelOrder(),
      );
    } catch (e) {
      debugPrint('===> error statistics settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
