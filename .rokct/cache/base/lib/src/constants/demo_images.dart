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

/// Imagery for the demo (`--dart-define=IS_DEMO=true`) seed data.
///
/// Every mock repository across the SDKs used to point its image fields at a
/// public placeholder host. That host is a network dependency the demo build
/// does not otherwise have — a demo build talks to no backend at all — so the
/// image widgets fell through to their error state and every seeded shop,
/// product, category, brand and banner rendered as a broken-image glyph. The
/// guided tour captures that verbatim, which is how the placeholders reached
/// the published store screenshots.
///
/// These are `data:image/svg+xml` URIs instead: they carry their own pixels,
/// so they render identically offline, in CI, and on a device with no route
/// to the internet, and they stay crisp at any size the cards ask for.
/// [AppHelpers.isInlineImage] routes them past the network layer in
/// `CustomNetworkImage` and `CommonImage`.
///
/// Deliberately abstract (soft gradients and shapes, no logos, no stock
/// photography): the seed data must look plausible in a screenshot without
/// implying a real merchant or brand.
abstract class DemoImages {
  DemoImages._();

  /// Wide shop/banner artwork — warm charcoal-to-amber, used for shop
  /// backgrounds and the store cover strip.
  static const String shopCover = 'data:image/svg+xml;utf8,'
      '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" '
      'viewBox="0 0 600 400">'
      '<defs><linearGradient id="c" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0" stop-color="#2A1D14"/>'
      '<stop offset="0.55" stop-color="#8A3F12"/>'
      '<stop offset="1" stop-color="#F2911F"/>'
      '</linearGradient></defs>'
      '<rect width="600" height="400" fill="url(#c)"/>'
      '<circle cx="126" cy="300" r="150" fill="#FFFFFF" opacity="0.06"/>'
      '<circle cx="470" cy="96" r="110" fill="#FFFFFF" opacity="0.08"/>'
      '<path d="M0 320 C 160 250 360 330 600 240 L600 400 L0 400 Z" '
      'fill="#1B120C" opacity="0.35"/>'
      '</svg>';

  /// Square shop/brand mark — a soft amber tile with a plate-like ring.
  static const String shopMark = 'data:image/svg+xml;utf8,'
      '<svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" '
      'viewBox="0 0 180 180">'
      '<defs><linearGradient id="m" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0" stop-color="#F7A93B"/>'
      '<stop offset="1" stop-color="#E1620C"/>'
      '</linearGradient></defs>'
      '<rect width="180" height="180" rx="42" fill="url(#m)"/>'
      '<circle cx="90" cy="90" r="46" fill="none" stroke="#FFFFFF" '
      'stroke-width="10" opacity="0.85"/>'
      '<circle cx="90" cy="90" r="18" fill="#FFFFFF" opacity="0.85"/>'
      '</svg>';

  /// Product artwork — cool plum-to-rose, so a product tile never reads as a
  /// duplicate of the shop tile beside it.
  static const String product = 'data:image/svg+xml;utf8,'
      '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" '
      'viewBox="0 0 300 300">'
      '<defs><linearGradient id="p" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0" stop-color="#3B2233"/>'
      '<stop offset="1" stop-color="#C4573F"/>'
      '</linearGradient></defs>'
      '<rect width="300" height="300" fill="url(#p)"/>'
      '<circle cx="150" cy="164" r="86" fill="#FFFFFF" opacity="0.10"/>'
      '<circle cx="150" cy="164" r="52" fill="#FFFFFF" opacity="0.12"/>'
      '<rect x="52" y="44" width="196" height="14" rx="7" fill="#FFFFFF" '
      'opacity="0.12"/>'
      '</svg>';

  /// Category artwork — deep green, the third of the three demo hues.
  static const String category = 'data:image/svg+xml;utf8,'
      '<svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" '
      'viewBox="0 0 180 180">'
      '<defs><linearGradient id="k" x1="0" y1="1" x2="1" y2="0">'
      '<stop offset="0" stop-color="#173B2E"/>'
      '<stop offset="1" stop-color="#4C9A6B"/>'
      '</linearGradient></defs>'
      '<rect width="180" height="180" rx="36" fill="url(#k)"/>'
      '<path d="M40 128 C 70 74 110 74 140 52 L140 128 Z" fill="#FFFFFF" '
      'opacity="0.16"/>'
      '<circle cx="60" cy="56" r="18" fill="#FFFFFF" opacity="0.20"/>'
      '</svg>';

  /// Promotional banner artwork — wide, high-contrast, sits behind the
  /// campaign copy on the home carousel.
  static const String promoBanner = 'data:image/svg+xml;utf8,'
      '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="400" '
      'viewBox="0 0 800 400">'
      '<defs><linearGradient id="b" x1="0" y1="0" x2="1" y2="0">'
      '<stop offset="0" stop-color="#12100E"/>'
      '<stop offset="0.6" stop-color="#7A2E0B"/>'
      '<stop offset="1" stop-color="#FFA62B"/>'
      '</linearGradient></defs>'
      '<rect width="800" height="400" fill="url(#b)"/>'
      '<circle cx="640" cy="200" r="150" fill="#FFFFFF" opacity="0.10"/>'
      '<circle cx="640" cy="200" r="96" fill="#FFFFFF" opacity="0.10"/>'
      '<rect x="0" y="330" width="800" height="70" fill="#0B0A09" '
      'opacity="0.30"/>'
      '</svg>';

  /// Account avatar — the demo account's initials on the same amber
  /// gradient as [shopMark], so the profile header, the edit-profile sheet
  /// and the drawer render the one avatar every demo sign-in lands on.
  /// Owned here so the auth and users demo repositories share a single
  /// literal instead of each carrying its own copy (ADR-005 forbids one
  /// importing the other).
  static const String avatar = 'data:image/svg+xml;utf8,'
      '<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" '
      'viewBox="0 0 160 160">'
      '<defs><linearGradient id="a" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0" stop-color="#F7A93B"/>'
      '<stop offset="1" stop-color="#E1620C"/>'
      '</linearGradient></defs>'
      '<circle cx="80" cy="80" r="80" fill="url(#a)"/>'
      '<text x="80" y="101" text-anchor="middle" '
      'font-family="Helvetica, Arial, sans-serif" font-size="60" '
      'font-weight="600" fill="#FFFFFF">TM</text>'
      '</svg>';
}
