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



import 'package:base_sdk/src/models/data/meta.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

class SellerProductsPaginateResponse {
  SellerProductsPaginateResponse({List<SellerProductData>? data, Meta? meta}) {
    _data = data;
    _meta = meta;
  }

  SellerProductsPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SellerProductData.fromJson(v));
      });
    }
    _meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  List<SellerProductData>? _data;
  Meta? _meta;

  SellerProductsPaginateResponse copyWith({List<SellerProductData>? data, Meta? meta}) =>
      SellerProductsPaginateResponse(data: data ?? _data, meta: meta ?? _meta);

  List<SellerProductData>? get data => _data;

  Meta? get meta => _meta;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    if (_meta != null) {
      map['meta'] = _meta?.toJson();
    }
    return map;
  }
}
