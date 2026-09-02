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

// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
// For license information, please see license.txt

import '../models/money.dart';

/// Read-only view of the user's in-app wallet balance.
///
/// **Why this exists, and why it is not `WalletRepositoryFacade`.** ADR-005
/// forbids forex_sdk from importing `wallet_sdk`, but the more specific
/// reason is the shape of the thing on the other side. `WalletRepositoryFacade`
/// bundles several methods that move money:
/// `sendWalletToPhone(...)`, `sendWalletByCode(...)` and `walletTopUp(...)`.
/// Depending on it would put money-moving writes inside the reach of every
/// screen in this SDK, for the sake of reading one number.
///
/// **Forex reads the wallet and never writes to it.** Subscriptions are paid
/// through the payments/subscriptions flow, not from here; trading capital
/// lives at the broker, not in the wallet. There is no forex feature that
/// legitimately debits or credits a wallet, so there is no method here that
/// can. This interface is one method wide by design, and widening it is a
/// decision somebody has to make deliberately rather than inherit.
///
/// **Safe default on failure.** `null`. A wallet balance that could not be
/// read is unknown, and the UI must render it as unknown — never as zero. A
/// zero balance is a claim about the user's money; an unread balance is a
/// claim about the network. Screens that show a derived consequence from a
/// balance (the risk picker) must show the formula and an em dash rather
/// than compute a consequence from a fabricated figure.
abstract class ForexWalletBalanceSource {
  /// The current wallet balance, with its currency, or null when it cannot
  /// be determined.
  ///
  /// Never throws for an ordinary failure — returning null is the contract,
  /// so that a caller cannot forget the try/catch and end up rendering an
  /// error where a dash belongs.
  Future<Money?> currentBalance();
}
