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


import 'package:base_sdk/src/models/data/parcel_order.dart';

import 'package:base_sdk/src/models/data/meta.dart';

class ParcelPaginateResponse {
  ParcelPaginateResponse({List<ParcelOrder>? data, Meta? meta}) {
    _data = data;
    _meta = meta;
  }

  ParcelPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(ParcelOrder.fromJson(v));
      });
    }
    _meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  List<ParcelOrder>? _data;
  Meta? _meta;

  ParcelPaginateResponse copyWith({List<ParcelOrder>? data, Meta? meta}) =>
      ParcelPaginateResponse(data: data ?? _data, meta: meta ?? _meta);

  List<ParcelOrder>? get data => _data;

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
