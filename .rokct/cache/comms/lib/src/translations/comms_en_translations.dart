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


// Bundled English (en) UI strings for the translation keys this SDK uses.
// Keys are BACKEND translation keys (the values TrKeys constants hold).
// Served backend rows always win; this map is the offline/unseeded fallback
// consulted by base_sdk's BundledTranslations before the humanized key.
const Map<String, String> kCommsEnTranslations = {
  'new_notifications': 'New notifications',
  'you_have_unseen_notifications': 'You have notifications you haven\'t seen',
};
