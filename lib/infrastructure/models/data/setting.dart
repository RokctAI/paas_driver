class SettingsData {
  SettingsData({
    int? id,
    String? key,
    String? value,
    String? createdAt,
    String? updatedAt,
  }) {
    _id = id;
    _key = key;
    _value = value;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  SettingsData.fromJson(dynamic json) {
    _id = json['id'];
    _key = json['key'];
    _value = json['value'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  String? _key;
  String? _value;
  String? _createdAt;
  String? _updatedAt;

  SettingsData copyWith({
    int? id,
    String? key,
    String? value,
    String? createdAt,
    String? updatedAt,
  }) =>
      SettingsData(
        id: id ?? _id,
        key: key ?? _key,
        value: value ?? _value,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
      );

  int? get id => _id;

  String? get key => _key;

  String? get value => _value;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['key'] = _key;
    map['value'] = _value;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }
}