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


/// Asset-key constants for the composed app.
///
/// Base keeps ONLY the constants its own shared pages (or 2+ SDKs) use —
/// today that is the brand logo, referenced by auth's login page and the
/// marketplace home. Everything else is SDK-owned: an SDK declares its
/// constants under `asset_keys` in its manifest and the installer injects
/// them between the markers below at compose time (the exact tr_keys
/// model), while the FILES arrive via the SDK's own `installs` template
/// entries. The pre-split marketplace constants (card logos, shop
/// banners, food imagery) lived here for the generic marketplace template
/// heritage; the ones still shipped now belong to the marketplace SDK.
class AppAssets {
  AppAssets._();

  static const String _pngPath = 'assets/images';
  static const String _svgPath = 'assets/svg';

  static const String pngLogo = '$_pngPath/logo.png';

  // Menu glyph used by base's shared tab-bar components
  // (categories_tab_bar, tab_bar_loading); the file ships with the host app.
  static const String svgMenu = '$_svgPath/menu.svg';

  // @sdk-asset-keys-start
  static const String pngMyLocation = 'assets/image/my_location.png';
  static const String svgBalance = 'assets/svg/balance.svg';
  // @sdk-asset-keys-end
}
