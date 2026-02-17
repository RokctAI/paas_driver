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
