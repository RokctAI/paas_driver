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


import 'package:base_sdk/src/models/data/profile_data.dart';

class VerifyPhoneResponse {
  VerifyPhoneResponse({
    String? timestamp,
    bool? status,
    String? message,
    VerifyData? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  VerifyPhoneResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? VerifyData.fromJson(json['data']) : null;
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  VerifyData? _data;

  VerifyPhoneResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    VerifyData? data,
  }) =>
      VerifyPhoneResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  VerifyData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['timestamp'] = _timestamp;
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class VerifyData {
  VerifyData({String? token, ProfileData? user}) {
    _token = token;
    _user = user;
  }

  VerifyData.fromJson(dynamic json) {
    _token = json['token'];
    _user = json['user'] != null ? ProfileData.fromJson(json['user']) : null;
  }

  String? _token;
  ProfileData? _user;

  VerifyData copyWith({String? token, ProfileData? user}) =>
      VerifyData(token: token ?? _token, user: user ?? _user);

  String? get token => _token;

  ProfileData? get user => _user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    if (_user != null) {
      map['user'] = _user?.toJson();
    }
    return map;
  }
}
