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
  Future<ApiResult<void>> deleteAddress(int addressId) async {
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
