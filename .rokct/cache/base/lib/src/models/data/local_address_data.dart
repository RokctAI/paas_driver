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


import 'package:base_sdk/src/models/data/local_location.dart';

class LocalAddressData {
  LocalAddressData({
    int? id,
    String? title,
    String? address,
    LocalLocation? location,
    bool? isDefault,
    bool? isSelected,
  }) {
    _id = id;
    _title = title;
    _address = address;
    _location = location;
    _default = isDefault;
    _isSelected = isSelected;
  }

  LocalAddressData.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _address = json['address'];
    _location = json['location'] != null
        ? LocalLocation.fromJson(json['location'])
        : null;
    _default = json['default'];
    _isSelected = json['selected'];
  }

  int? _id;
  String? _title;
  String? _address;
  LocalLocation? _location;
  bool? _default;
  bool? _isSelected;

  LocalAddressData copyWith({
    int? id,
    String? title,
    String? address,
    LocalLocation? location,
    bool? isDefault,
    bool? isSelected,
  }) =>
      LocalAddressData(
        id: id ?? _id,
        title: title ?? _title,
        address: address ?? _address,
        location: location ?? _location,
        isDefault: isDefault ?? _default,
        isSelected: isSelected ?? _isSelected,
      );

  int? get id => _id;

  String? get title => _title;

  String? get address => _address;

  LocalLocation? get location => _location;

  bool? get isDefault => _default;

  bool? get isSelected => _isSelected;

  Map<String, dynamic> toJson() => {
        'address': _address,
        'location': '${_location?.latitude},${_location?.longitude}',
        'active': 1,
        if (_title?.isNotEmpty ?? false) 'title': _title,
        'default': (_isSelected ?? false) ? 1 : 0,
      };

  @override
  String toString() {
    return 'LocalAddressData(title - $title})';
  }
}
