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

/// Narrow contract for the driver's wallet PLANE (design strip frame 49f):
/// the balance he can trust and the movements that explain it.
///
/// Lives in `common/` for the same reason as
/// [DriverPayoutRepositoryFacade] — the composer's role strip deletes the
/// non-matching role folder, so a seam the barrel exports, and the response
/// types its signature names, have to survive that strip. Only the concrete
/// `DriverWalletRepository` is driver-only and stays in `driver/`.
///
/// Neither endpoint behind it belongs to an app this SDK depends on:
/// `api.payment.get_wallet_balance` is wallet's, `api.user.get_wallet_history`
/// is users'. paas_driver composes neither wallet_sdk nor a users SDK, so
/// nothing is imported from them — the calls ride base_sdk's universal
/// platform gateway by prefix-free dotted name, exactly as
/// `CourierStatisticsRepository` already reaches delivery's and map's defs.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';

abstract class DriverWalletRepositoryFacade {
  /// The authoritative spendable balance for the signed-in driver.
  ///
  /// A driver who never received funds has no `Wallet` row and reads as
  /// zero; nothing is created by this read. The value MAY be negative and
  /// that is correct — he keeps the physical cash he collects and his
  /// ledger carries the debt.
  Future<ApiResult<num>> getBalance();

  /// The wallet statement, newest first.
  ///
  /// [start] and [limit] are the endpoint's own paging arguments
  /// (`get_wallet_history(start=0, limit=20)`).
  Future<ApiResult<List<WalletMovement>>> getMovements({
    int start,
    int limit,
  });
}
