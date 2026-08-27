// Copyright (c) 2026 RokctAI
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


import 'package:base_sdk/src/models/data/user.dart';

class LoginResponse {
  LoginResponse({
    String? timestamp,
    bool? status,
    String? message,
    UserData? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  LoginResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  UserData? _data;

  LoginResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    UserData? data,
  }) =>
      LoginResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  UserData? get data => _data;

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

class UserData {
  UserData({
    String? accessToken,
    String? refreshToken,
    String? expiresAt,
    String? tokenType,
    UserModel? user,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = expiresAt;
    _tokenType = tokenType;
    _user = user;
  }

  UserData.fromJson(dynamic json) {
    _accessToken = json['access_token'];
    _refreshToken = json['refresh_token'];
    _expiresAt = json['expires_at']?.toString();
    _tokenType = json['token_type'];
    _user = json['user'] != null ? UserModel.fromJson(json['user']) : null;
  }

  String? _accessToken;
  String? _refreshToken;
  String? _expiresAt;
  String? _tokenType;
  UserModel? _user;

  UserData copyWith({
    String? accessToken,
    String? refreshToken,
    String? expiresAt,
    String? tokenType,
    UserModel? user,
  }) =>
      UserData(
        accessToken: accessToken ?? _accessToken,
        refreshToken: refreshToken ?? _refreshToken,
        expiresAt: expiresAt ?? _expiresAt,
        tokenType: tokenType ?? _tokenType,
        user: user ?? _user,
      );

  String? get accessToken => _accessToken;

  /// Single-use rotation token from the login/refresh contract; absent on
  /// flows that mint no refresh contract (Google login, OTP verify).
  String? get refreshToken => _refreshToken;

  /// Server-side access-token expiry (`YYYY-MM-DD HH:MM:SS`, server time).
  String? get expiresAt => _expiresAt;

  String? get tokenType => _tokenType;

  UserModel? get user => _user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['access_token'] = _accessToken;
    map['refresh_token'] = _refreshToken;
    map['expires_at'] = _expiresAt;
    map['token_type'] = _tokenType;
    if (_user != null) {
      map['user'] = _user?.toJson();
    }
    return map;
  }
}
