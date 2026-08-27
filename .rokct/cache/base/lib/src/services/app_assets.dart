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
