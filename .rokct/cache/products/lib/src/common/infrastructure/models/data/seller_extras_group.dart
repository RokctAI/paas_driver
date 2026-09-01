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
import 'package:base_sdk/src/models/data/translation.dart';

class SellerExtrasGroup {
  SellerExtrasGroup({
    String? id,
    String? shopId,
    String? type,
    bool? isChecked,
    Translation? translation,
    List<SellerExtras>? fetchedExtras,
    List<SellerExtras>? extraValues,
  }) {
    _id = id;
    _shopId = shopId;
    _type = type;
    _isChecked = isChecked;
    _translation = translation;
    _fetchedExtras = fetchedExtras;
    _extraValues = extraValues;
  }

  SellerExtrasGroup.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _type = json['type'];
    _shopId = json['shop_id']?.toString();
    _isChecked = false;
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    _fetchedExtras = [];
    if (json['extra_values'] != null) {
      _extraValues = [];
      json['extra_values'].forEach((v) {
        _extraValues?.add(SellerExtras.fromJson(v));
      });
    }
  }

  String? _id;
  String? _shopId;
  String? _type;
  bool? _isChecked;
  Translation? _translation;
  List<SellerExtras>? _fetchedExtras;
  List<SellerExtras>? _extraValues;

  SellerExtrasGroup copyWith({
    String? id,
    String? shopId,
    String? type,
    bool? isChecked,
    Translation? translation,
    List<SellerExtras>? fetchedExtras,
    List<SellerExtras>? extraValues,
  }) =>
      SellerExtrasGroup(
        id: id ?? _id,
        shopId: shopId ?? _shopId,
        type: type ?? _type,
        isChecked: isChecked ?? _isChecked,
        translation: translation ?? _translation,
        fetchedExtras: fetchedExtras ?? _fetchedExtras,
        extraValues: extraValues ?? _extraValues,
      );

  String? get id => _id;

  String? get shopId => _shopId;

  String? get type => _type;

  bool? get isChecked => _isChecked;

  Translation? get translation => _translation;

  List<SellerExtras>? get fetchedExtras => _fetchedExtras;

  List<SellerExtras>? get extraValues => _extraValues;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['shop_id'] = _shopId;
    map['type'] = _type;
    if (_translation != null) {
      map['translation'] = _translation?.toJson();
    }
    if (_extraValues != null) {
      map['extra_values'] = _extraValues?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
