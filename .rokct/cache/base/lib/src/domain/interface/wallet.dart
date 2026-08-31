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


import 'package:base_sdk/src/handlers/handlers.dart';

import 'package:base_sdk/src/models/data/wallet_data.dart';
import 'package:base_sdk/src/models/data/wallet_transfer_data.dart';

/// Wallet operations over the platform gateway (`api.payment.*` /
/// `api.transfer.*` cmds).
///
/// The CashSend-style transfer surface replaced the legacy enumerable
/// recipient search (`searchSending`) and the old
/// `sendWalletBalance(userUuid, amount)`: a sender either confirms a FULL
/// phone number ([confirmRecipient] then [sendWalletToPhone]) or redeems a
/// receiver-minted 6-digit claim code ([sendWalletByCode]). Codes are
/// minted by the receiver via [generateReceiveClaim] and handed over
/// out-of-band — never pushed or SMSed.
abstract class WalletRepositoryFacade {
  /// Resolve a FULL registered phone number to ONLY that one user's name
  /// fields for a pre-send confirmation. Never a list, never an email.
  Future<ApiResult<WalletRecipientData>> confirmRecipient({
    required String phone,
  });

  /// Receiver mints a pending claim: a 6-digit code linked to the
  /// logged-in user and [amount], to be read to the sender out-of-band.
  Future<ApiResult<WalletReceiveClaimData>> generateReceiveClaim({
    required double amount,
  });

  /// Receiver cancels their own pending claim.
  Future<ApiResult<bool>> cancelReceiveClaim({required String code});

  /// Send [amount] to the user whose registered phone number is exactly
  /// [phone] (confirm first via [confirmRecipient]).
  Future<ApiResult<WalletTransferData>> sendWalletToPhone({
    required String phone,
    required double amount,
  });

  /// Redeem a receiver-minted claim code: pays the claim's exact amount to
  /// its receiver and consumes the code (single-use).
  Future<ApiResult<WalletTransferData>> sendWalletByCode({
    required String code,
  });

  /// Top the wallet up by charging a saved card.
  ///
  /// [token] keeps its name for source compatibility with the shipped
  /// implementations, but what it carries is the Saved Card docname --
  /// `SavedCardModel.id`, the `name` returned by `getSavedCards` /
  /// `tokenizeCard`. The gateway reuse credential is server-side only;
  /// a caller that sends one is refused without charging.
  Future<ApiResult<dynamic>> walletTopUp({
    required double amount,
    String? token,
  });
  Future<ApiResult<List<WalletHistoryData>>> getWalletHistory();
}
