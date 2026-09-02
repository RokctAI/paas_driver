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

// Bundled English (en) UI strings covering this SDK's manifest.json tr_keys
// backend keys. Keys are BACKEND translation keys (the values TrKeys
// constants hold), not Dart field names. Served-translation rows from the
// backend always win; these values are the offline/unseeded fallback
// consulted by base_sdk's BundledTranslations registry before the
// humanized-key fallback. English needs a bundled map here (weather's af
// precedent, applied to en) because the approved section-39 copy carries
// punctuation and casing the humanized-key fallback cannot reproduce
// ("Where this shop delivers — one shape, drawn on the map"; a lowercase
// "points" after a leading count).
const Map<String, String> kZonesEnTranslations = {
  'drawing': 'Drawing',
  'points': 'points',
  'points.placed': 'points placed',
  'shape.not.closed.yet': 'Shape not closed yet',
  'km2': 'km²',
  'covered': 'covered',
  'where.this.shop.delivers':
      'Where this shop delivers — one shape, drawn on the map',
  'tap.the.map.to.add.a.point.new.points.extend.the.shape':
      'Tap the map to add a point; new points extend the shape.',
  'tap.the.map.to.add.a.point.save.unlocks.at.4':
      'Tap the map to add a point — Save unlocks at 4.',
  'undo.last.point': 'Undo last point',
  'save.delivery.zone': 'Save delivery zone',
  '1.more.point.to.close.the.shape': '1 more point to close the shape',
  '2.more.points.to.close.the.shape': '2 more points to close the shape',
  '3.more.points.to.close.the.shape': '3 more points to close the shape',
};
