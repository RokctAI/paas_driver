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

  // Filled by scripts/trkeys-gaps (every key the SDK uses now has copy).
  'age_verification': 'Age check',
  'age_verification_is_required_to_order_adults_only_items': 'We need to check your age before you order adults-only items',
  'cash_to_collect_from_recipient': 'Cash to collect from the recipient',
  'default': 'Default',
  'driver_collects_cash_from_recipient': 'The driver collects cash from the recipient',
  'drop_here': 'Drop here',
  'enter_cash_amount_greater_than_zero': 'Enter a cash amount above zero',
  'loads': 'Loads',
  'manager': 'Manager',
  'no_name': 'No name',
  'no_orders': 'No orders',
  'open_orders': 'Open orders',
  'orders_to_accept': 'Orders to accept',
  'payment': 'Payment',
  'payment_cancelled': 'Payment cancelled',
  'pickup_skips_on_a_way': 'Pickup skips "on the way"',
  'start_end': 'Start and end',
  'this_order_includes_an_adults_only_item_please_confirm_your_date_of_birth': 'This order has an adults-only item. Please confirm your date of birth.',
  'view_more': 'View more',
  'waiting_on_you': 'Waiting on you',
  'you_must_be_18_or_older_to_order_adults_only_items': 'You must be 18 or older to order adults-only items',
  'you_saved_with_your_subscription': 'You saved with your subscription',
};
