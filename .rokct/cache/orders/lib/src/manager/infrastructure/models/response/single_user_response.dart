import 'package:orders_sdk/src/manager/infrastructure/models/data/user_data.dart';

/// Port of `paas_manager`'s `ProfileResponse` under a name that cannot be
/// confused with base_sdk's profile response: the POS create-customer flow's
/// "one user back" envelope.
class SingleUserResponse {
  SingleUserResponse({UserData? data}) {
    _data = data;
  }

  SingleUserResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }

  UserData? _data;

  SingleUserResponse copyWith({UserData? data}) =>
      SingleUserResponse(data: data ?? _data);

  UserData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
