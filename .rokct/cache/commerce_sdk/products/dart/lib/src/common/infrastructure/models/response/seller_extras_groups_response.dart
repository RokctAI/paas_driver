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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

class SellerExtrasGroupsResponse {
  SellerExtrasGroupsResponse({List<SellerExtrasGroup>? data}) {
    _data = data;
  }

  SellerExtrasGroupsResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SellerExtrasGroup.fromJson(v));
      });
    }
  }

  List<SellerExtrasGroup>? _data;

  SellerExtrasGroupsResponse copyWith({List<SellerExtrasGroup>? data}) =>
      SellerExtrasGroupsResponse(data: data ?? _data);

  List<SellerExtrasGroup>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
