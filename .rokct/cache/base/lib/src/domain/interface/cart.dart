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
