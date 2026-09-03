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

import 'package:flutter/foundation.dart';

/// The shop a manager wallet pane stands on (design strip frame 49l).
///
/// The host that mounts [ManagerWalletPane] — the merchants restaurant /
/// shop page, where the approved hub renders `BaseWalletCard` — passes
/// this so the pane knows which shop it is drawn for. It keys the pane's
/// provider (one wallet slice per shop), labels the pane, and rides
/// telemetry on every failure.
///
/// IT IS NOT SENT ON THE WIRE, and that is deliberate. The payout call the
/// pane makes, wallet's `api.payout.request_payout`, is USER-scoped: it
/// reads the session user (`pay/wallet/frappe/src/tenant/api/payout.py:350`)
/// and debits that user's wallet. Whether a shop withdraws to the shop's
/// own account or to the manager's personal one is the question frame 49l
/// left open for Ray. This scope sits at the seam so that when he rules,
/// the host that mounts the pane does not change — only what the pane does
/// with the scope does.
@immutable
class ManagerWalletScope {
  const ManagerWalletScope({required this.shopId, this.shopName});

  /// The shop's identifier as the host holds it (the merchants `Shop` row).
  final String shopId;

  /// Display name, when the host has one. Labels only.
  final String? shopName;

  @override
  bool operator ==(Object other) =>
      other is ManagerWalletScope &&
      other.shopId == shopId &&
      other.shopName == shopName;

  @override
  int get hashCode => Object.hash(shopId, shopName);

  @override
  String toString() => 'ManagerWalletScope($shopId, $shopName)';
}
