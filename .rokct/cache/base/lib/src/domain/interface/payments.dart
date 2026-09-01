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

  /// Charge a saved card for [orderBody].
  ///
  /// The second argument is the Saved Card docname -- `SavedCardModel.id`,
  /// the `name` returned by `getSavedCards` / `tokenizeCard` -- not a
  /// gateway reuse credential. The credential is server-side only and is
  /// resolved there; a caller that sends one is refused without charging.
  Future<ApiResult<String>> processTokenPayment(
    OrderBodyData orderBody,
    String token,
  );

  Future<ApiResult<bool>> deleteCard(String cardId);

  Future<ApiResult<bool>> setDefaultCard(String cardId);
}
