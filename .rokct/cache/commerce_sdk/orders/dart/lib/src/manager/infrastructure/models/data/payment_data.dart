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

class PaymentData {
  PaymentData({
    String? id,
    String? tag,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) {
    _id = id;
    _tag = tag;
    _active = active;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  PaymentData.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _tag = json['tag'];
    _active = json['active'].runtimeType == int
        ? (json['active'] != 0)
        : json['active'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  String? _id;
  String? _tag;
  bool? _active;
  String? _createdAt;
  String? _updatedAt;

  PaymentData copyWith({
    String? id,
    String? tag,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) =>
      PaymentData(
        id: id ?? _id,
        tag: tag ?? _tag,
        active: active ?? _active,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
      );

  String? get id => _id;

  String? get tag => _tag;

  bool? get active => _active;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['tag'] = _tag;
    map['active'] = _active;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }
}
