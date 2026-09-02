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


import 'package:base_sdk/src/services/local_storage.dart';

class OnlyShopRequest {
  final String? lan;
  OnlyShopRequest({this.lan});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["lang"] = LocalStorage.getLanguage()?.locale ?? "en";
    if (LocalStorage.getSelectedCurrency() != null)
      map["currency_id"] = LocalStorage.getSelectedCurrency()?.id;
    return map;
  }
}
