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


class BannerTextCache {
  static final Map<String, String> _buttonTexts = {};

  static void storeButtonText(String? bannerId, String? buttonText) {
    if (bannerId != null && buttonText != null) {
      // print("CACHE DEBUG: Storing '$buttonText' for banner ID: $bannerId");
      _buttonTexts[bannerId] = buttonText;
      // print("CACHE DEBUG: Cache contents: $_buttonTexts");
    }
  }

  static String? getButtonText(String? bannerId) {
    if (bannerId == null) return null;
    String? result = _buttonTexts[bannerId];
    // print("CACHE DEBUG: Retrieved '${result}' for banner ID: $bannerId");
    return result;
  }
}
