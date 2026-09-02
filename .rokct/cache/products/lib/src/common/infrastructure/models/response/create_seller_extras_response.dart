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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';

class CreateSellerExtrasResponse {
  CreateSellerExtrasResponse({SellerExtras? data}) {
    _data = data;
  }

  CreateSellerExtrasResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? SellerExtras.fromJson(json['data']) : null;
  }

  SellerExtras? _data;

  CreateSellerExtrasResponse copyWith({SellerExtras? data}) =>
      CreateSellerExtrasResponse(data: data ?? _data);

  SellerExtras? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
