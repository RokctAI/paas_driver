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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';

class SellerUnitsPaginateResponse {
  SellerUnitsPaginateResponse({List<SellerUnitData>? data}) {
    _data = data;
  }

  SellerUnitsPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SellerUnitData.fromJson(v));
      });
    }
  }

  List<SellerUnitData>? _data;

  SellerUnitsPaginateResponse copyWith({List<SellerUnitData>? data}) =>
      SellerUnitsPaginateResponse(data: data ?? _data);

  List<SellerUnitData>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
