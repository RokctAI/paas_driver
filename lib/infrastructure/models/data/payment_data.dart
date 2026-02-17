class PaymentData {
  PaymentData({
    int? id,
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
    _id = json['id'];
    _tag = json['tag'];
    _active = json['active'].runtimeType == int
        ? (json['active'] != 0)
        : json['active'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  String? _tag;
  bool? _active;
  String? _createdAt;
  String? _updatedAt;

  PaymentData copyWith({
    int? id,
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

  int? get id => _id;

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
