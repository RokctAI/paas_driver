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

import 'extras.dart';
import 'package:base_sdk/src/models/data/translation.dart';

class Group {
  Group({
    int? id,
    int? shopId,
    String? type,
    bool? isChecked,
    Translation? translation,
    List<Extras>? fetchedExtras,
    List<Extras>? extraValues,
  }) {
    _id = id;
    _shopId = shopId;
    _type = type;
    _isChecked = isChecked;
    _translation = translation;
    _fetchedExtras = fetchedExtras;
    _extraValues = extraValues;
  }

  Group.fromJson(dynamic json) {
    _id = json['id'];
    _type = json['type'];
    _shopId = json['shop_id'];
    _isChecked = false;
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    _fetchedExtras = [];
    if (json['extra_values'] != null) {
      _extraValues = [];
      json['extra_values'].forEach((v) {
        _extraValues?.add(Extras.fromJson(v));
      });
    }
  }

  int? _id;
  int? _shopId;
  String? _type;
  bool? _isChecked;
  Translation? _translation;
  List<Extras>? _fetchedExtras;
  List<Extras>? _extraValues;

  Group copyWith({
    int? id,
    int? shopId,
    String? type,
    bool? isChecked,
    Translation? translation,
    List<Extras>? fetchedExtras,
    List<Extras>? extraValues,
  }) =>
      Group(
        id: id ?? _id,
        shopId: shopId ?? _shopId,
        type: type ?? _type,
        isChecked: isChecked ?? _isChecked,
        translation: translation ?? _translation,
        fetchedExtras: fetchedExtras ?? _fetchedExtras,
        extraValues: extraValues ?? _extraValues,
      );

  int? get id => _id;

  int? get shopId => _shopId;

  String? get type => _type;

  bool? get isChecked => _isChecked;

  Translation? get translation => _translation;

  List<Extras>? get fetchedExtras => _fetchedExtras;

  List<Extras>? get extraValues => _extraValues;

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
