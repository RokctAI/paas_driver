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

// Bundled Afrikaans (af) UI strings for this SDK's manifest.json tr_keys
// (backend keys). Backend-served rows always win; this is the offline/
// unseeded fallback consulted by base_sdk's BundledTranslations registry.
const Map<String, String> kOrdersAfTranslations = {
  // Hardcoded UI copy moved to trkeys (Ray, 2026-11-20).
  'orders_insufficient_wallet_balance': 'Onvoldoende beursiesaldo',
  'orders_top_up_create': 'Laai op en skep',
  'orders_track_order': 'Volg bestelling',
  'orders_call_driver': 'Bel bestuurder',
  'orders_order_placed': 'Bestelling geplaas',
  'orders_preparing_your_order': 'Ons berei jou bestelling voor',
  'orders_arriving_now': 'Kom nou aan',
  'orders_on_the_way': 'Op pad',
  'orders_rate_order': 'Gradeer bestelling',
  'orders_order_cancelled': 'Bestelling gekanselleer',
  'orders_get_help': 'Kry hulp',

  // Filled by scripts/trkeys-gaps (every key the SDK uses now has copy).
  'age_verification': 'Ouderdomstoets',
  'age_verification_is_required_to_order_adults_only_items': 'Ons moet jou ouderdom nagaan voordat jy items net vir volwassenes bestel',
  'cash_to_collect_from_recipient': 'Kontant om by die ontvanger te kry',
  'default': 'Verstek',
  'driver_collects_cash_from_recipient': 'Die bestuurder kry kontant by die ontvanger',
  'drop_here': 'Laai hier af',
  'enter_cash_amount_greater_than_zero': 'Tik \'n kontantbedrag bo nul in',
  'loads': 'Vragte',
  'manager': 'Bestuurder',
  'no_name': 'Geen naam nie',
  'no_orders': 'Geen bestellings nie',
  'open_orders': 'Oop bestellings',
  'orders_to_accept': 'Bestellings om te aanvaar',
  'payment': 'Betaling',
  'payment_cancelled': 'Betaling gekanselleer',
  'pickup_skips_on_a_way': 'Afhaal slaan "op pad" oor',
  'start_end': 'Begin en einde',
  'this_order_includes_an_adults_only_item_please_confirm_your_date_of_birth': 'Hierdie bestelling het \'n item net vir volwassenes. Bevestig asseblief jou geboortedatum.',
  'view_more': 'Sien meer',
  'waiting_on_you': 'Wag op jou',
  'you_must_be_18_or_older_to_order_adults_only_items': 'Jy moet 18 of ouer wees om items net vir volwassenes te bestel',
  'you_saved_with_your_subscription': 'Jy het met jou intekening gespaar',
};
