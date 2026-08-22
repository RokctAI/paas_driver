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

import 'package:base_sdk/src/models/data/translation.dart';

class UnitData {
UnitData({
int? id,
bool? active,
String? position,
Translation? translation,
List<String>? locales,
}) {
_id = id;
_active = active;
_position = position;
_translation = translation;
_locales = locales;
}

UnitData.fromJson(dynamic json) {
_id = json['id'];
_active = json['active'];
_position = json['position'];
_translation = json['translation'] != null
? Translation.fromJson(json['translation'])
    : null;
_locales = json['locales'] != null ? json['locales'].cast<String>() : [];
}

int? _id;
bool? _active;
String? _position;
Translation? _translation;
List<String>? _locales;

UnitData copyWith({
int? id,
bool? active,
String? position,
Translation? translation,
List<String>? locales,
}) =>
UnitData(
id: id ?? _id,
active: active ?? _active,
position: position ?? _position,
translation: translation ?? _translation,
locales: locales ?? _locales,
);

int? get id => _id;

bool? get active => _active;

String? get position => _position;

Translation? get translation => _translation;

List<String>? get locales => _locales;

Map<String, dynamic> toJson() {
final map = <String, dynamic>{};
map['id'] = _id;
map['active'] = _active;
map['position'] = _position;
if (_translation != null) {
map['translation'] = _translation?.toJson();
}
map['locales'] = _locales;
return map;
}
}