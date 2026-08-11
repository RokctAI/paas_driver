import 'package:base_sdk/src/models/data/location.dart';

class AddressData {
  AddressData({
    int? id,
    String? title,
    String? address,
    LocationModel? location,
    bool? isDefault,
    bool? active,
  }) {
    _id = id;
    _title = title;
    _address = address;
    _location = location;
    _default = isDefault;
    _active = active;
  }

  AddressData.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    // _address = json['address'];
    // _location = json['location'] != null
    //     ? LocationModel.fromJson(json['location'])
    //     : null;
    _default = json['default'];
    _active = json['active'];
  }

  int? _id;
  String? _title;
  String? _address;
  LocationModel? _location;
  bool? _default;
  bool? _active;

  AddressData copyWith({
    int? id,
    String? title,
    String? address,
    LocationModel? location,
    bool? isDefault,
    bool? active,
  }) =>
      AddressData(
        id: id ?? _id,
        title: title ?? _title,
        address: address ?? _address,
        location: location ?? _location,
        isDefault: isDefault ?? _default,
        active: active ?? _active,
      );

  int? get id => _id;

  String? get title => _title;

  String? get address => _address;

  LocationModel? get location => _location;

  bool? get isDefault => _default;

  bool? get active => _active;

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
    return map;
  }
}
