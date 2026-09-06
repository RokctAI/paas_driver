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
  'maintenance_title': 'Under maintenance',
  'maintenance_brief':
      'We are doing some maintenance. Please try again shortly.',
};
