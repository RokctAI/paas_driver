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
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

class AddressRepository implements AddressRepositoryFacade {
  /// Universal platform gateway: every backend call is a POST to the single
  /// gateway endpoint with a prefix-free `cmd`. Cmds are the users module's
  /// `manifest.json` whitelisted-method keys with the app segment dropped
  /// (`api.user.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<AddressesResponse>> getUserAddresses() async {
    try {
      final response = await _gateway.tenant('api.user.get_user_addresses');
      return ApiResult.success(data: AddressesResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> get user addresses failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> deleteAddress(String addressId) async {
    try {
      await _gateway.tenant(
        'api.user.delete_user_address',
        {'name': addressId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete address failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleAddressResponse>> createAddress(
    LocalAddressData address,
  ) async {
    try {
      final response = await _gateway.tenant(
        'api.user.add_user_address',
        {'address_data': address.toJson()},
      );
      return ApiResult.success(
        data: SingleAddressResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> create address failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
