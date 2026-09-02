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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';

/// Named `Seller*` because base_sdk already has a `CategoriesPaginateResponse`
/// over a different `CategoryData` (measured 27.9% similar).
class SellerCategoriesPaginateResponse {
  SellerCategoriesPaginateResponse({List<SellerCategoryData>? data}) {
    _data = data;
  }

  /// Frappe returns whitelisted payloads under `message`; the legacy shape used
  /// `data`. Accept either.
  SellerCategoriesPaginateResponse.fromJson(dynamic json) {
    final dynamic payload =
        (json is Map) ? (json['message'] ?? json['data']) : json;
    final dynamic rows =
        (payload is Map) ? (payload['data'] ?? payload) : payload;
    if (rows is List) {
      _data = rows
          .map((v) =>
              SellerCategoryData.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    }
  }

  List<SellerCategoryData>? _data;

  SellerCategoriesPaginateResponse copyWith({List<SellerCategoryData>? data}) =>
      SellerCategoriesPaginateResponse(data: data ?? _data);

  List<SellerCategoryData>? get data => _data;

  Map<String, dynamic> toJson() => {
        if (_data != null) 'data': _data?.map((v) => v.toJson()).toList(),
      };
}
