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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';

/// The driver's van-sales calls, on commerce's `api.order.load.*` defs.
///
/// Same shape as [DriverDepositRepository]: a prefix-free `cmd` base
/// (commerce `manifest.json`'s whitelisted-method keys
/// `{app_name}.api.order.load.*` with the app segment dropped) through
/// base_sdk's universal platform gateway. Nothing here is multipart, so
/// there is no gallery detour — four plain calls.
///
/// `items` travels JSON-ENCODED. The gateway posts its payload as a JSON
/// body, but the Frappe whitelist layer hands a def its kwargs as strings
/// when the call arrives form-encoded, and every list argument this fleet
/// already sends does the same (`statuses` on
/// `get_driver_orders_paginate`, above). A server that json.loads a string
/// and one that receives a list both read this.
class DriverLoadRepository implements DriverLoadRepositoryFacade {
  static const _cmd = 'api.order.load';
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<List<DriverLoad>>> getMyLoad() async {
    try {
      final response = await _gateway.tenant('$_cmd.get_my_load');
      return ApiResult.success(data: DriverLoad.listFrom(response));
    } catch (e) {
      debugPrint('===> get my load error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DriverLoadSale>> createLoadSale({
    required String loadOrder,
    required List<DriverLoadMovement> items,
    String? customer,
    String? note,
    String? poi,
  }) async {
    // The amount to collect is struck from the load's own unit prices by
    // the notifier that assembled these lines and carried alongside the
    // server's answer; the contract's success payload is the order id and
    // the load, not a total.
    try {
      final trimmedNote = (note ?? '').trim();
      final trimmedCustomer = (customer ?? '').trim();
      final trimmedPoi = (poi ?? '').trim();
      final response = await _gateway.tenant('$_cmd.create_load_sale', {
        'load_order': loadOrder,
        'items': _encodeItems(items),
        if (trimmedCustomer.isNotEmpty) 'customer': trimmedCustomer,
        if (trimmedNote.isNotEmpty) 'note': trimmedNote,
        // Only when he named a place. commerce's `create_load_sale` takes
        // `poi=None`, and a sale at no particular corner must not send an
        // empty one.
        if (trimmedPoi.isNotEmpty) 'poi': trimmedPoi,
      });
      return ApiResult.success(data: DriverLoadSale.fromJson(response));
    } catch (e) {
      debugPrint('===> create load sale error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DriverLoad>> returnLoad({
    required String loadOrder,
    required List<DriverLoadMovement> items,
  }) async {
    try {
      final response = await _gateway.tenant('$_cmd.return_load', {
        'load_order': loadOrder,
        'items': _encodeItems(items),
      });
      return _oneLoad(response, op: 'return_load');
    } catch (e) {
      debugPrint('===> return load error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DriverLoad>> closeLoad({required String loadOrder}) async {
    try {
      final response = await _gateway.tenant('$_cmd.close_load', {
        'load_order': loadOrder,
      });
      return _oneLoad(response, op: 'close_load');
    } catch (e) {
      debugPrint('===> close load error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  static String _encodeItems(List<DriverLoadMovement> items) =>
      jsonEncode(items.map((item) => item.toJson()).toList());

  /// A write that answers with the load itself. An empty envelope is a
  /// failure rather than a blank load: redrawing a load as empty would
  /// tell the driver his van is empty when nobody said so.
  static ApiResult<DriverLoad> _oneLoad(dynamic response,
      {required String op}) {
    final load = DriverLoad.oneFrom(response);
    if (load == null) {
      debugPrint('===> $op answered no load');
      return const ApiResult.failure(
        error: 'The load did not come back.',
        statusCode: 500,
      );
    }
    return ApiResult.success(data: load);
  }
}
