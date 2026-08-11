import '../data/user_data.dart';

class UsersPaginateResponse {
  UsersPaginateResponse({List<UserData>? data}) {
    _data = data;
  }

  UsersPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(UserData.fromJson(v));
      });
    }
  }

  List<UserData>? _data;

  UsersPaginateResponse copyWith({List<UserData>? data}) =>
      UsersPaginateResponse(data: data ?? _data);

  List<UserData>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
