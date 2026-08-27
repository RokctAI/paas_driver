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
