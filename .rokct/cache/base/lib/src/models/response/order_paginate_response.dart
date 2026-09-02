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


import 'package:base_sdk/src/models/data/order_active_model.dart';

import 'package:base_sdk/src/models/data/meta.dart';

class OrderPaginateResponse {
  OrderPaginateResponse({List<OrderActiveModel>? data, Meta? meta}) {
    _data = data;
    _meta = meta;
  }

  OrderPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(OrderActiveModel.fromJsonWithoutData(v));
      });
    }
    _meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  List<OrderActiveModel>? _data;
  Meta? _meta;

  OrderPaginateResponse copyWith({List<OrderActiveModel>? data, Meta? meta}) =>
      OrderPaginateResponse(data: data ?? _data, meta: meta ?? _meta);

  List<OrderActiveModel>? get data => _data;

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
