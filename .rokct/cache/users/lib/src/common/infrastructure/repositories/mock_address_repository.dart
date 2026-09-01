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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/models/data/address_new_data.dart';
import 'package:base_sdk/src/models/data/address_information.dart';
import 'package:base_sdk/src/models/data/local_address_data.dart';
import 'package:base_sdk/src/models/response/addresses_response.dart';
import 'package:base_sdk/src/models/response/single_address_response.dart';

class MockAddressRepository implements AddressRepositoryFacade {
  final AddressNewModel _demoAddress = AddressNewModel(
    id: "1",
    title: "Home",
    address: AddressInformation(
      address: "123 Demo St",
      house: "123",
      floor: "1",
    ),
    active: true,
    location: [37.7749, -122.4194],
  );

  @override
  Future<ApiResult<SingleAddressResponse>> createAddress(
    LocalAddressData address,
  ) async {
    return ApiResult.success(
      data: SingleAddressResponse(
        data: _demoAddress.copyWith(
          title: address.title,
          address: AddressInformation(address: address.address),
          location: address.location != null
              ? [
                  address.location!.latitude ?? 0.0,
                  address.location!.longitude ?? 0.0,
                ]
              : null,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<void>> deleteAddress(String addressId) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<AddressesResponse>> getUserAddresses() async {
    return ApiResult.success(
      data: AddressesResponse(
        data: [
          _demoAddress,
          _demoAddress.copyWith(
            id: "2",
            title: "Work",
            address: AddressInformation(address: "456 Office Blvd"),
          ),
        ],
      ),
    );
  }
}
