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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

class SingleSellerProductResponse {
  SingleSellerProductResponse({SellerProductData? data}) {
    _data = data;
  }

  SingleSellerProductResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? SellerProductData.fromJson(json['data']) : null;
  }

  SellerProductData? _data;

  SingleSellerProductResponse copyWith({SellerProductData? data}) =>
      SingleSellerProductResponse(data: data ?? _data);

  SellerProductData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
