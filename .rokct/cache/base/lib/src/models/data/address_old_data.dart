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


import 'package:base_sdk/src/models/data/location.dart';

class AddressData {
  AddressData({
    int? id,
    String? title,
    String? address,
    LocationModel? location,
    bool? isDefault,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) {
    _id = id;
    _title = title;
    _address = address;
    _location = location;
    _default = isDefault;
    _active = active;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  AddressData.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _address = json['address'];
    _location = json['location'] != null
        ? LocationModel.fromJson(json['location'])
        : null;
    _default = json['default'];
    _active = json['active'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  String? _title;
  String? _address;
  LocationModel? _location;
  bool? _default;
  bool? _active;
  String? _createdAt;
  String? _updatedAt;

  AddressData copyWith({
    int? id,
    String? title,
    String? address,
    LocationModel? location,
    bool? isDefault,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) =>
      AddressData(
        id: id ?? _id,
        title: title ?? _title,
        address: address ?? _address,
        location: location ?? _location,
        isDefault: isDefault ?? _default,
        active: active ?? _active,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
      );

  int? get id => _id;

  String? get title => _title;

  String? get address => _address;

  LocationModel? get location => _location;

  /// Convenience accessors delegating to [location]. The courier vertical
  /// (delivery_sdk's moved-verbatim paas_driver pages) reads the selected
  /// address's coordinates directly — the legacy host stored a bare LatLng
  /// where base stores an [AddressData] — so these keep those call sites
  /// working against the shared model. Nullable and purely derived; the
  /// JSON shape (location: {latitude, longitude}) is unchanged.
  double? get latitude => _location?.latitude;

  double? get longitude => _location?.longitude;

  bool? get isDefault => _default;

  bool? get active => _active;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['address'] = _address;
    if (_location != null) {
      map['location'] = _location?.toJson();
    }
    map['default'] = _default;
    map['active'] = _active;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }
}
