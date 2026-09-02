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

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Offline payment confirmation for the POS till (the checkout's
/// "offline inversion", approved strip section 11, frames 11e/11f).
///
/// When the till has no connectivity the customer still pays the pay-link
/// on their own phone (their phone is online); their payment-success
/// screen shows a 6-digit code the cashier types into the till, and the
/// till verifies it LOCALLY — zero server contact — because both sides
/// derive the code from the same order facts and shared secret:
///
///   code = last 6 decimal digits of the unsigned 32-bit integer formed by
///          the LEADING 4 bytes (big-endian) of
///          sha256("orderId|amount2dp|shopId|sharedSecret")
///
/// Widened from the retired Spazafy 5-digit helper (a 6th digit cuts the
/// guess odds tenfold; patterned on the LMS accountability-partner code /
/// wallet send-by-code idiom already in the fleet). Deterministic and
/// locally verifiable by construction; the amount is normalised to two
/// decimals so both sides hash the identical string. The sale itself still
/// syncs when the till is back online — this code only confirms payment at
/// the counter.
///
/// The shared secret is per shop, known to the backend and cached on the
/// till (the shop uuid today — the checkout passes it; a dedicated rotating
/// secret is the documented follow-up in the backend contract).
class PosPayVerification {
  PosPayVerification._();

  /// Derives the 6-digit confirmation code for an order.
  static String code({
    required String orderId,
    required num amount,
    required String shopId,
    required String sharedSecret,
  }) {
    final material =
        '$orderId|${amount.toStringAsFixed(2)}|$shopId|$sharedSecret';
    final digest = sha256.convert(utf8.encode(material)).bytes;
    final leading = (digest[0] << 24) |
        (digest[1] << 16) |
        (digest[2] << 8) |
        digest[3];
    return (leading % 1000000).toString().padLeft(6, '0');
  }

  /// Verifies a typed code against the order facts. Constant-time
  /// comparison — a 6-digit space is small enough that even a timing
  /// oracle would matter at the counter.
  static bool verify({
    required String enteredCode,
    required String orderId,
    required num amount,
    required String shopId,
    required String sharedSecret,
  }) {
    final expected = code(
      orderId: orderId,
      amount: amount,
      shopId: shopId,
      sharedSecret: sharedSecret,
    );
    if (enteredCode.length != expected.length) return false;
    var mismatch = 0;
    for (var i = 0; i < expected.length; i++) {
      mismatch |= enteredCode.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return mismatch == 0;
  }
}
