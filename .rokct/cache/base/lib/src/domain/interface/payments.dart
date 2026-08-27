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


import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';

import 'package:base_sdk/src/models/data/saved_card.dart';

abstract class PaymentsRepositoryFacade {
  Future<ApiResult<PaymentsResponse?>> getPayments();

  Future<ApiResult<TransactionsResponse>> createTransaction({
    required String orderId,
    required String paymentId,
  });

  Future<ApiResult<List<SavedCardModel>>> getSavedCards();

  Future<ApiResult<String>> processDirectCardPayment(
    OrderBodyData orderBody,
    String cardNumber,
    String cardName,
    String expiryDate,
    String cvc,
  );

  Future<ApiResult<String>> tokenizeCard({
    required String cardNumber,
    required String cardName,
    required String expiryDate,
    required String cvc,
  });

  Future<ApiResult<String>> tokenizeAfterPayment(
    String cardNumber,
    String cardName,
    String expiryDate,
    String cvc, [
    String? token,
    String? lastFour,
    String? cardType,
  ]);

  Future<ApiResult<String>> processTokenPayment(
    OrderBodyData orderBody,
    String token,
  );

  Future<ApiResult<bool>> deleteCard(String cardId);

  Future<ApiResult<bool>> setDefaultCard(String cardId);
}
