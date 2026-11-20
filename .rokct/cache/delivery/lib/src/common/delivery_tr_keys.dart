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

/// Wire keys for the strings delivery_sdk introduces. lib/ analyzes against raw
/// base_sdk, where the composer-injected TrKeys constants from manifest.json
/// `tr_keys` do not exist, so SDK code references them through this class
/// (booking_sdk / polaris_sdk precedent). The SAME keys are in manifest.json.
abstract final class DeliveryTrKeys {

  // Hardcoded UI copy moved to trkeys (Ray, 2026-11-20).
  static const String deliveryNavigate = 'delivery_navigate';
  static const String deliveryOnlineWaitingForOrders = 'delivery_online_waiting_for_orders';
}
