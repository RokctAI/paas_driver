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


class GlobalSettingsResponse {
  GlobalSettingsResponse({
    String? timestamp,
    bool? status,
    String? message,
    List<SettingsData>? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  GlobalSettingsResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SettingsData.fromJson(v));
      });
    }
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  List<SettingsData>? _data;

  GlobalSettingsResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    List<SettingsData>? data,
  }) =>
      GlobalSettingsResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  List<SettingsData>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['timestamp'] = _timestamp;
    map['status'] = _status;
    map['message'] = _message;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

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
