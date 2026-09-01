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

import 'package:base_sdk/src/models/data/translation.dart';

class UnitData {
UnitData({
String? id,
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
_id = (json['id'] ?? json['name'])?.toString();
_active = json['active'];
_position = json['position'];
_translation = json['translation'] != null
? Translation.fromJson(json['translation'])
    : null;
_locales = json['locales'] != null ? json['locales'].cast<String>() : [];
}

String? _id;
bool? _active;
String? _position;
Translation? _translation;
List<String>? _locales;

UnitData copyWith({
String? id,
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

String? get id => _id;

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