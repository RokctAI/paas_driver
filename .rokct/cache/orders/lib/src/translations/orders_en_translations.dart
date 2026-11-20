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

/// English fallbacks for orders_sdk tr_keys whose legacy wire key humanizes
/// badly. Registered at boot (manifest boot_hooks); a backend-served row
/// still wins, this map only stands in before the humanized-key fallback.
///
/// `spproximate_preparation_time: ` keeps the typo the translation store
/// already uses as its key (see manifest `_comment_tr_keys`); without a row
/// the humanizer showed "Spproximate preparation time:" on the POS
/// shipping step.
const Map<String, String> kOrdersEnTranslations = {
  'spproximate_preparation_time: ': 'Approximate preparation time: ',
  // Hardcoded UI copy moved to trkeys (Ray, 2026-11-20).
  'orders_insufficient_wallet_balance': 'Insufficient Wallet Balance',
  'orders_top_up_create': 'Top Up & Create',
  'orders_track_order': 'Track order',
  'orders_call_driver': 'Call driver',
  'orders_order_placed': 'Order placed',
  'orders_preparing_your_order': 'Preparing your order',
  'orders_arriving_now': 'Arriving now',
  'orders_on_the_way': 'On the way',
  'orders_rate_order': 'Rate order',
  'orders_order_cancelled': 'Order cancelled',
  'orders_get_help': 'Get help',
};
