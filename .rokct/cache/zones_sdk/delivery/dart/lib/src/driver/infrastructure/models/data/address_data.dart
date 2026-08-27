// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

// LocalLocationData is inlined below: the host kept it in its own file, but
// base_sdk's LocalLocation parses string coordinates only and no other
// delivery file needs the type.
class LocalLocationData {
  LocalLocationData({double? latitude, double? longitude}) {
    _latitude = latitude;
    _longitude = longitude;
  }

  LocalLocationData.fromJson(dynamic json) {
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (lat != null) {
      if (lat is String) {
        _latitude = double.tryParse(lat);
      }
    }
    if (lon != null) {
      if (lon is String) {
        _longitude = double.tryParse(lon);
      }
    }
  }

  double? _latitude;
  double? _longitude;

  LocalLocationData copyWith({double? latitude, double? longitude}) =>
      LocalLocationData(
        latitude: latitude ?? _latitude,
        longitude: longitude ?? _longitude,
      );

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['latitude'] = _latitude;
    map['longitude'] = _longitude;
    return map;
  }
}

class AddressData {
  AddressData({
    int? id,
    String? title,
    String? address,
    LocalLocationData? location,
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
    // _address = json['address'];
    // _location = json['location'] != null
    //     ? LocalLocationData.fromJson(json['location'])
    //     : null;
    _default = json['default'];
    _active = json['active'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  String? _title;
  String? _address;
  LocalLocationData? _location;
  bool? _default;
  bool? _active;
  String? _createdAt;
  String? _updatedAt;

  AddressData copyWith({
    int? id,
    String? title,
    String? address,
    LocalLocationData? location,
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

  LocalLocationData? get location => _location;

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
