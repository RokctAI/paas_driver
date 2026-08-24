// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:products_sdk/src/common/infrastructure/models/data/seller_json_ext.dart';

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

class SellerExtras {
  SellerExtras({
    String? id,
    String? extraGroupId,
    String? value,
    SellerExtrasGroup? group,
    SellerStockPivot? pivot,
    bool? active,
  }) {
    _id = id;
    _extraGroupId = extraGroupId;
    _value = value;
    _group = group;
    _pivot = pivot;
    _active = active;
  }

  SellerExtras.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _extraGroupId = json['extra_group_id']?.toString();
    _value = json['value'];
    _group = json['group'] != null ? SellerExtrasGroup.fromJson(json['group']) : null;
    _pivot = json['pivot'] != null ? SellerStockPivot.fromJson(json['pivot']) : null;
    _active = json['active']?.toString().toBool();
  }

  String? _id;
  String? _extraGroupId;
  String? _value;
  SellerExtrasGroup? _group;
  SellerStockPivot? _pivot;
  bool? _active;

  SellerExtras copyWith({
    String? id,
    String? extraGroupId,
    String? value,
    SellerExtrasGroup? group,
    SellerStockPivot? pivot,
    bool? active,
  }) =>
      SellerExtras(
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

  SellerExtrasGroup? get group => _group;

  SellerStockPivot? get pivot => _pivot;

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

class SellerStockPivot {
  SellerStockPivot({String? stockId, String? extraValueId}) {
    _stockId = stockId;
    _extraValueId = extraValueId;
  }

  SellerStockPivot.fromJson(dynamic json) {
    _stockId = json['stock_id']?.toString();
    _extraValueId = json['extra_value_id']?.toString();
  }

  String? _stockId;
  String? _extraValueId;

  SellerStockPivot copyWith({String? stockId, String? extraValueId}) => SellerStockPivot(
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
