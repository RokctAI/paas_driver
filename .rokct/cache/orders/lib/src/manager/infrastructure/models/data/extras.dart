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

import 'package:orders_sdk/src/manager/infrastructure/models/data/order_json_ext.dart';

import 'group.dart';

class Extras {
  Extras({
    String? id,
    String? extraGroupId,
    String? value,
    Group? group,
    StockPivot? pivot,
    bool? active,
  }) {
    _id = id;
    _extraGroupId = extraGroupId;
    _value = value;
    _group = group;
    _pivot = pivot;
    _active = active;
  }

  Extras.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _extraGroupId = json['extra_group_id']?.toString();
    _value = json['value'];
    _group = json['group'] != null ? Group.fromJson(json['group']) : null;
    _pivot = json['pivot'] != null ? StockPivot.fromJson(json['pivot']) : null;
    _active = json['active']?.toString().toBool();
  }

  String? _id;
  String? _extraGroupId;
  String? _value;
  Group? _group;
  StockPivot? _pivot;
  bool? _active;

  Extras copyWith({
    String? id,
    String? extraGroupId,
    String? value,
    Group? group,
    StockPivot? pivot,
    bool? active,
  }) =>
      Extras(
        id: id ?? _id,
        extraGroupId: extraGroupId ?? _extraGroupId,
        value: value ?? _value,
        group: group ?? _group,
        pivot: pivot ?? _pivot,
        active: active ?? _active,
      );

  String? get id => _id;

  String? get extraGroupId => _extraGroupId;

  String? get value => _value;

  Group? get group => _group;

  StockPivot? get pivot => _pivot;

  bool? get active => _active;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['extra_group_id'] = _extraGroupId;
    map['value'] = _value;
    if (_group != null) {
      map['group'] = _group?.toJson();
    }
    if (_pivot != null) {
      map['pivot'] = _pivot?.toJson();
    }
    map['active'] = _active;
    return map;
  }
}

class StockPivot {
  StockPivot({String? stockId, String? extraValueId}) {
    _stockId = stockId;
    _extraValueId = extraValueId;
  }

  StockPivot.fromJson(dynamic json) {
    _stockId = json['stock_id']?.toString();
    _extraValueId = json['extra_value_id']?.toString();
  }

  String? _stockId;
  String? _extraValueId;

  StockPivot copyWith({String? stockId, String? extraValueId}) => StockPivot(
        stockId: stockId ?? _stockId,
        extraValueId: extraValueId ?? _extraValueId,
      );

  String? get stockId => _stockId;

  String? get extraValueId => _extraValueId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['stock_id'] = _stockId;
    map['extra_value_id'] = _extraValueId;
    return map;
  }
}
