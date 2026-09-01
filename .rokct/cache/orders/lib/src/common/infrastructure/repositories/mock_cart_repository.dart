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
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/request/cart_request.dart';

class MockCartRepository implements CartRepositoryFacade {
  final UserCart _demoUserCart = UserCart(
    id: "1",
    cartId: "1",
    userId: "1",
    status: true,
    name: "Demo Cart",
    uuid: "demo_cart_uuid",
    cartDetails: [
      CartDetail(
        id: "101",
        quantity: 2,
        price: 150,
        bonus: false,
        stock: Stocks(price: 150, quantity: 100),
      ),
    ],
  );

  @override
  Future<ApiResult<CartModel>> deleteCart({required String cartId}) async {
    return ApiResult.success(
      data: CartModel(
        data: Cart(id: "1", userCarts: []),
      ),
    );
  }

  @override
  Future<ApiResult<CartModel>> getCart(String shopId) async {
    return ApiResult.success(
      data: CartModel(
        data: Cart(id: "1", totalPrice: 300, userCarts: [_demoUserCart]),
      ),
    );
  }

  @override
  Future<ApiResult<CartModel>> insertCart({required CartRequest cart}) async {
    return ApiResult.success(
      data: CartModel(
        data: Cart(
          id: "1",
          totalPrice: 150,
          userCarts: [_demoUserCart], // Simplified for mock
        ),
      ),
    );
  }

  @override
  Future<ApiResult<dynamic>> changeStatus({
    required String? userUuid,
    required String? cartId,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<CartModel>> createAndCart({
    required CartRequest cart,
  }) async {
    return insertCart(cart: cart);
  }

  @override
  Future<ApiResult<CartModel>> createCart({required CartRequest cart}) async {
    return insertCart(cart: cart);
  }

  @override
  Future<ApiResult<dynamic>> deleteUser({
    required String cartId,
    required String userId,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<CartModel>> getCartInGroup(
    String? cartId,
    String? shopId,
    String? cartUuid,
  ) async {
    return getCart(shopId ?? "0");
  }

  @override
  Future<ApiResult<CartModel>> insertCartWithGroup({
    required CartRequest cart,
  }) async {
    return insertCart(cart: cart);
  }

  @override
  Future<ApiResult<CartModel>> removeProductCart({
    required String cartDetailId,
    List<String>? listOfId,
  }) async {
    return ApiResult.success(
      data: CartModel(
        data: Cart(
          id: "1",
          userCarts: [_demoUserCart.copyWith(cartDetails: [])],
        ),
      ),
    );
  }

  @override
  Future<ApiResult<dynamic>> startGroupOrder({required String cartId}) async {
    return ApiResult.success(data: null);
  }
}
