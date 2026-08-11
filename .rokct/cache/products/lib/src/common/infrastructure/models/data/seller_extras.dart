import 'package:products_sdk/src/common/infrastructure/models/data/seller_json_ext.dart';

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

class SellerExtras {
  SellerExtras({
    int? id,
    int? extraGroupId,
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
    _id = json['id'];
    _extraGroupId = json['extra_group_id'];
    _value = json['value'];
    _group = json['group'] != null ? SellerExtrasGroup.fromJson(json['group']) : null;
    _pivot = json['pivot'] != null ? SellerStockPivot.fromJson(json['pivot']) : null;
    _active = json['active']?.toString().toBool();
  }

  int? _id;
  int? _extraGroupId;
  String? _value;
  SellerExtrasGroup? _group;
  SellerStockPivot? _pivot;
  bool? _active;

  SellerExtras copyWith({
    int? id,
    int? extraGroupId,
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

  int? get id => _id;

  int? get extraGroupId => _extraGroupId;

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
  SellerStockPivot({int? stockId, int? extraValueId}) {
    _stockId = stockId;
    _extraValueId = extraValueId;
  }

  SellerStockPivot.fromJson(dynamic json) {
    _stockId = json['stock_id'];
    _extraValueId = json['extra_value_id'];
  }

  int? _stockId;
  int? _extraValueId;

  SellerStockPivot copyWith({int? stockId, int? extraValueId}) => SellerStockPivot(
        stockId: stockId ?? _stockId,
        extraValueId: extraValueId ?? _extraValueId,
      );

  int? get stockId => _stockId;

  int? get extraValueId => _extraValueId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['stock_id'] = _stockId;
    map['extra_value_id'] = _extraValueId;
    return map;
  }
}
