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

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// The one place a freshly-known wallet balance is written back onto the
/// cached profile.
///
/// Every driver money surface reads `LocalStorage.getUser()?.wallet?.price`
/// — the profile page's readout
/// (`zones/delivery/dart/templates/pages/driver/profile/profile_page.dart`),
/// the income page's wallet row, and the withdraw sheet's available card.
/// When the server tells us the balance (the post-hold balance a payout
/// answers, or the authoritative read the wallet plane makes), writing it
/// here is what makes all of them agree at once instead of one screen
/// showing money that has already left.
///
/// Best-effort by design: a storage failure must never turn a good server
/// answer into an on-screen error. The next profile fetch corrects it.
abstract class WalletBalanceCache {
  WalletBalanceCache._();

  static Future<void> mirror(num? balance) async {
    if (balance == null) return;
    try {
      final ProfileData? user = LocalStorage.getUser();
      final wallet = user?.wallet;
      if (user == null || wallet == null) return;
      await LocalStorage.setUser(
        user.copyWith(wallet: wallet.copyWith(price: balance)),
      );
    } catch (_) {
      // Cache-only convenience.
    }
  }

  /// What the driver's screens are currently showing. Null-safe: a profile
  /// with no wallet row reads as zero, exactly as the income page does.
  static num get cached => LocalStorage.getUser()?.wallet?.price ?? 0;
}
