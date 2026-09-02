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

import '../data/order_data.dart';

class SingleOrderResponse {
  SingleOrderResponse({OrderData? data}) {
    _data = data;
  }

  SingleOrderResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? OrderData.fromJson(json['data']) : null;
  }

  OrderData? _data;

  SingleOrderResponse copyWith({OrderData? data}) =>
      SingleOrderResponse(data: data ?? _data);

  OrderData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
