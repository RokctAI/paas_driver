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
};
