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


class CurrencyData {
  CurrencyData({
    String? id,
    String? symbol,
    String? title,
    num? rate,
    bool? isDefault,
    bool? active,
    String? updatedAt,
    String? position,
  }) {
    _id = id;
    _symbol = symbol;
    _title = title;
    _rate = rate;
    _default = isDefault;
    _active = active;
    _updatedAt = updatedAt;
    _position = position;
  }

  CurrencyData.fromJson(dynamic json) {
    // Currency docname (e.g. "USD"): backend emits `name`, older payloads `id`.
    _id = (json['id'] ?? json['name'])?.toString();
    _symbol = json['symbol'];
    _title = json['title'];
    _rate = json['rate'];
    _default = json['default'];
    _active = json['active'];
    _updatedAt = json['updated_at'];
    _position = json['position'];
  }

  String? _id;
  String? _symbol;
  String? _title;
  num? _rate;
  bool? _default;
  bool? _active;
  String? _updatedAt;
  String? _position;

  CurrencyData copyWith({
    String? id,
    String? symbol,
    String? title,
    num? rate,
    bool? isDefault,
    bool? active,
    String? updatedAt,
    String? position,
  }) =>
      CurrencyData(
        id: id ?? _id,
        symbol: symbol ?? _symbol,
        title: title ?? _title,
        rate: rate ?? _rate,
        isDefault: isDefault ?? _default,
        active: active ?? _active,
        updatedAt: updatedAt ?? _updatedAt,
        position: position ?? _position,
      );

  String? get id => _id;

  String? get symbol => _symbol;

  String? get title => _title;

  num? get rate => _rate;

  bool? get isDefault => _default;

  bool? get active => _active;

  String? get updatedAt => _updatedAt;

  String? get position => _position;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['symbol'] = _symbol;
    map['title'] = _title;
    map['rate'] = _rate;
    map['default'] = _default;
    map['active'] = _active;
    map['updated_at'] = _updatedAt;
    map['position'] = _position;
    return map;
  }
}
