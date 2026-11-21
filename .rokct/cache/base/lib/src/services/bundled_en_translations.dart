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

// Bundled English (en) UI strings for the base_sdk keys whose humanized
// fallback is NOT their copy.
//
// Keys are BACKEND translation keys (the values TrKeys constants hold),
// not Dart field names. Served-translation rows from the backend always
// win; these values are the offline/unseeded fallback consulted by
// BundledTranslations before the humanized-key fallback
// (AppHelpers.getTranslation), and the English value TranslationSeeder
// offers the backend for the key instead of the humanized one.
//
// English is otherwise meant to survive through AppHelpers.humanizeTrKey,
// which works for keys named after their copy (`reset_password` ->
// "Reset password") and fails for keys that NAME a string instead of
// spelling it: `maintenance_title` humanizes to the literal
// "Maintenance title", which is what the maintenance page rendered on a
// tenant whose Translation doctype had no `en` row for it. Only such keys
// belong here; a key whose humanized form already reads as its copy gains
// nothing from a row. Locale 'en' is left-to-right.
const Map<String, String> kBaseEnTranslations = {
  // Both of these NAME a string rather than spelling it: humanizing them
  // gives the clipped "Could not reach server" / "Server took too long"
  // instead of copy, which is exactly what this map is for.
  'could_not_reach_server':
      "We couldn't reach the server. Please try again.",
  'server_took_too_long':
      'The server took too long to respond. Please try again.',
  'maintenance_title': 'Under maintenance',
  'maintenance_brief':
      'We are doing some maintenance. Please try again shortly.',
  'update_required_title': 'Update needed',
  'update_required_brief':
      'This version of the app is too old. Please update it to keep going.',
  'update_now': 'Update',
  // Customer subscriptions (loyalty_sdk).
  'payment_overdue_benefits_are_paused':
      'Payment overdue. Your benefits are paused until it goes through.',
  'the_payment_did_not_go_through': "The payment didn't go through.",
  // Profile data-used badge (DataUsageBadge).
  'wi-fi': 'Wi-Fi',
  'data.used.note':
      "Counted on this device from the app's own requests. Your phone's "
      'data screen may show a little more.',
  // Humanizing this misspelt legacy key read "Restauran home" on the
  // driver's active-job sheet (tour 1114b, driver 05-driver_home).
  'restauran_home': 'Shop to customer',
  // Hardcoded UI copy moved to trkeys (Ray, 2026-11-20).
  'check_connection_and_try_again': 'Please check your internet connection and try again.',
  'continue_offline': 'Continue offline',
  'skip_guide': 'Skip guide',
  'current_password': 'Current password',
  'enter_your_current_password': 'Enter your current password.',

  // Filled by scripts/trkeys-gaps (every key the SDK uses now has copy).
  'how_are_you_finding_the_app': 'How are you finding the app?',
  'offline': 'Offline',
  'online': 'Online',
  'rate_this_app': 'Rate this app',
  'rate_us_in_the_store': 'Rate us in the store',
  'send_feedback': 'Send feedback',
  'tell_us_what_we_can_do_better': 'Tell us what we can do better',
  'thanks_for_your_rating': 'Thanks for your rating',
  'this_page_is_not_available_yet': 'This page is not available yet',
};
