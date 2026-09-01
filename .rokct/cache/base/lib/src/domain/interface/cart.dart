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


import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/request/cart_request.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

abstract class CartRepositoryFacade {
  Future<ApiResult<CartModel>> getCart(String shopId);

  Future<ApiResult<CartModel>> getCartInGroup(
    String? cartId,
    String? shopId,
    String? cartUuid,
  );

  Future<ApiResult<dynamic>> startGroupOrder({required String cartId});

  Future<ApiResult<dynamic>> changeStatus({
    required String? userUuid,
    required String? cartId,
  });

  Future<ApiResult<CartModel>> deleteCart({required String cartId});

  Future<ApiResult<dynamic>> deleteUser({
    required String cartId,
    required String userId,
  });

  Future<ApiResult<CartModel>> removeProductCart({
    required String cartDetailId,
    List<String> listOfId,
  });

  Future<ApiResult<CartModel>> createAndCart({required CartRequest cart});

  Future<ApiResult<CartModel>> insertCart({required CartRequest cart});

  Future<ApiResult<CartModel>> insertCartWithGroup({required CartRequest cart});

  Future<ApiResult<CartModel>> createCart({required CartRequest cart});
}
