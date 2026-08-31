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


class LanguagesResponse {
  LanguagesResponse({
    String? timestamp,
    bool? status,
    String? message,
    List<LanguageData>? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  LanguagesResponse.fromJson(dynamic json) {
    // Two shapes reach here. The `api_response` envelope wraps its rows
    // under `data` ({timestamp,status,message,data:[...]}), while a
    // Frappe `get_list` endpoint — `api.language.get_languages` is one —
    // answers with the row list ITSELF and no envelope around it. Treat
    // a top-level list as the data rather than subscripting it with a
    // String (which throws `type 'String' is not a subtype of type
    // 'int' of 'index'`).
    if (json is List) {
      _data = [];
      for (final v in json) {
        _data?.add(LanguageData.fromJson(v));
      }
      return;
    }
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(LanguageData.fromJson(v));
      });
    }
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  List<LanguageData>? _data;

  LanguagesResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    List<LanguageData>? data,
  }) =>
      LanguagesResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  List<LanguageData>? get data => _data;

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

class LanguageData {
  LanguageData({
    String? id,
    String? title,
    String? locale,
    bool? backward,
    bool? isDefault,
    bool? active,
    String? img,
  }) {
    _id = id;
    _title = title;
    _locale = locale;
    _backward = backward;
    _default = isDefault;
    _active = active;
    _img = img;
  }

  LanguageData.fromJson(dynamic json) {
    // Language docname: backend emits `name`, older payloads `id`.
    _id = (json['id'] ?? json['name'])?.toString();
    _title = json['title']?.toString();
    _locale = json['locale']?.toString();
    _backward = _asBool(json['backward']);
    _default = _asBool(json['default']);
    _active = _asBool(json['active']);
    _img = json['img']?.toString();
  }

  /// Frappe `Check` fields (`backward`, `default`, `active` on PaaS
  /// Language) come back over JSON as the ints 1/0, not as booleans —
  /// assigning one straight to a `bool?` throws `type 'int' is not a
  /// subtype of type 'bool?'`. Accept ints, the strings a form post can
  /// produce, and real booleans alike; anything else stays null.
  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalised = value.trim().toLowerCase();
      if (normalised.isEmpty) return null;
      return normalised == '1' || normalised == 'true' || normalised == 'yes';
    }
    return null;
  }

  String? _id;
  String? _title;
  String? _locale;
  bool? _backward;
  bool? _default;
  bool? _active;
  String? _img;

  LanguageData copyWith({
    String? id,
    String? title,
    String? locale,
    bool? backward,
    bool? isDefault,
    bool? active,
    String? img,
  }) =>
      LanguageData(
        id: id ?? _id,
        title: title ?? _title,
        locale: locale ?? _locale,
        backward: backward ?? _backward,
        isDefault: isDefault ?? _default,
        active: active ?? _active,
        img: img ?? _img,
      );

  String? get id => _id;

  String? get title => _title;

  String? get locale => _locale;

  bool? get backward => _backward;

  bool? get isDefault => _default;

  bool? get active => _active;

  String? get img => _img;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['locale'] = _locale;
    map['backward'] = _backward;
    map['default'] = _default;
    map['active'] = _active;
    map['img'] = _img;
    return map;
  }
}
