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
import 'package:base_sdk/src/models/data/product_data.dart';

class ProductsPaginateResponse {
  ProductsPaginateResponse({
    List<ProductData>? data,
    // Links? links,
    Meta? meta,
  }) {
    _data = data;
    // _links = links;
    _meta = meta;
  }

  ProductsPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(ProductData.fromJson(v));
      });
    }
    // _links = json['links'] != null ? Links.fromJson(json['links']) : null;
    _meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  List<ProductData>? _data;
  // Links? _links;
  Meta? _meta;

  ProductsPaginateResponse copyWith({
    List<ProductData>? data,
    // Links? links,
    Meta? meta,
  }) =>
      ProductsPaginateResponse(
        data: data ?? _data,
        // links: links ?? _links,
        meta: meta ?? _meta,
      );

  List<ProductData>? get data => _data;

  // Links? get links => _links;

  Meta? get meta => _meta;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    // if (_links != null) {
    //   map['links'] = _links?.toJson();
    // }
    if (_meta != null) {
      map['meta'] = _meta?.toJson();
    }
    return map;
  }
}
