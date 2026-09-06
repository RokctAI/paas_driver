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

// Bundled English (en) UI strings for the auth_sdk keys whose humanized
// fallback is NOT their copy.
//
// Keys are BACKEND translation keys (the values TrKeys constants hold),
// not Dart field names. Served-translation rows from the backend always
// win; these values are the offline/unseeded fallback consulted by
// base_sdk's BundledTranslations registry before the humanized-key
// fallback (AppHelpers.getTranslation). Registered at boot by this SDK's
// manifest.json boot_hooks entry `auth_en_bundled_translations`.
//
// Why this map exists: base_sdk bundles no `en` map at all, on the
// grounds that English "survives through the humanized-key fallback".
// That holds for keys named after their copy (`reset_password` ->
// "Reset password", `forgot_password` -> "Forgot password") and fails for
// keys that NAME a string instead of spelling it: `reset_password_text`
// humanizes to the literal "Reset password text", which is what every app
// shell's guided tour rendered on the reset-password sheet (demo builds
// take their served map from comms_sdk's MockSettingsRepository, a
// hand-picked handful of rows that never included this key). Only such
// keys belong here; a key whose humanized form already reads as its copy
// gains nothing from a row.
const Map<String, String> kAuthEnTranslations = {
  'reset_password_text':
      'Enter the email address for your account and we will send you a '
          'link to reset your password.',
  'reset_password_phone_text':
      'Enter the phone number for your account and we will send you a '
          'code to reset your password.',
  'reset_password_either_text':
      'Enter the email address or phone number for your account and we '
          'will send you a link or a code to reset your password.',
};
