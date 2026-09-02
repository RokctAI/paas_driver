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
