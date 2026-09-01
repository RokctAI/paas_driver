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

class ProductRequest {
  final String shopId;
  final int page;
  final int? categoryId;
  final List<int>? brands;

  ProductRequest({
    required this.shopId,
    required this.page,
    this.categoryId,
    this.brands,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["shop_id"] = shopId;
    map["lang"] = LocalStorage.getLanguage()?.locale ?? "en";
    if (LocalStorage.getSelectedCurrency() != null) {
      map["currency_id"] = LocalStorage.getSelectedCurrency()?.id;
    }

    map["page"] = page;
    map["status"] = "published";
    map["perPage"] = 6;
    if (brands?.isNotEmpty ?? false) {
      map['brand_ids'] = brands?.map((v) => v).toList();
    }

    return map;
  }

  Map<String, dynamic> toJsonPopular() {
    final map = <String, dynamic>{};
    map["lang"] = LocalStorage.getLanguage()?.locale ?? "en";
    if (LocalStorage.getSelectedCurrency() != null) {
      map["currency_id"] = LocalStorage.getSelectedCurrency()?.id;
    }

    map["page"] = page;
    map["status"] = "published";
    map["perPage"] = 6;
    if (brands?.isNotEmpty ?? false) {
      map['brand_ids'] = brands?.map((v) => v).toList();
    }
    return map;
  }

  Map<String, dynamic> toJsonByCategory() {
    final map = <String, dynamic>{};
    map["shop_id"] = shopId;
    map["lang"] = LocalStorage.getLanguage()?.locale ?? "en";
    if (LocalStorage.getSelectedCurrency() != null) {
      map["currency_id"] = LocalStorage.getSelectedCurrency()?.id;
    }

    map["page"] = page;
    map["status"] = "published";
    map["category_id"] = categoryId;
    map["perPage"] = 6;
    if (brands?.isNotEmpty ?? false) {
      map['brand_ids'] = brands?.map((v) => v).toList();
    }
    return map;
  }
}
