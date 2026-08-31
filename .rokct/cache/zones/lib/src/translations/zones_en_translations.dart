// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
