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


// Bundled Afrikaans (af) UI strings covering this SDK's manifest.json tr_keys backend keys.
// Keys are BACKEND translation keys (the values TrKeys constants hold),
// not Dart field names. Served-translation rows from the backend always
// win; these values are the offline/unseeded fallback consulted by
// base_sdk's BundledTranslations registry before the humanized-key
// fallback. Generated from the SDK's key set; keep in sync when keys
// change. Locale 'af' is left-to-right.
const Map<String, String> kWeatherAfTranslations = {
  'as.of': 'soos op',
  // Hardcoded UI copy moved to trkeys (Ray, 2026-11-20).
  'weather_update_rain_feedback': 'Werk reënterugvoer by',
  'weather_did_it_rain_after_your_previous_no': 'Het dit gereën ná jou vorige "Nee"-antwoord?',
  'weather_no': 'Nee',
  // Launcher weather (Ray, 2026-11-22).
  'weather_clear': 'Helder',
  'weather_partly_cloudy': 'Gedeeltelik bewolk',
  'weather_cloudy': 'Bewolk',
  'weather_fog': 'Mis',
  'weather_drizzle': 'Motreën',
  'weather_rain': 'Reën',
  'weather_showers': 'Buie',
  'weather_thunder': 'Donderstorms',
  'weather_snow': 'Sneeu',
  'weather_high_short': 'H',
  'weather_low_short': 'L',
  'weather_mon': 'Ma',
  'weather_tue': 'Di',
  'weather_wed': 'Wo',
  'weather_thu': 'Do',
  'weather_fri': 'Vr',
  'weather_sat': 'Sa',
  'weather_sun': 'So',
  'weather_source_met_norway': 'Weerdata: MET Noorweë',
};
