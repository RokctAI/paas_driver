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


import 'package:base_sdk/src/models/data/translation.dart';

class PaymentData {
  PaymentData({
    String? id,
    String? tag,
    int? input,
    bool? sandbox,
    bool? active,
    String? createdAt,
    String? updatedAt,
    Translation? translation,
  }) {
    _id = id;
    _tag = tag;
    _input = input;
    _sandbox = sandbox;
    _active = active;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _translation = translation;
  }

  PaymentData.fromJson(dynamic json) {
    _id = json['id']?.toString();
    _tag = json['tag'];
    _input = json['input'];
    _sandbox = json['sandbox'];
    _active = json['active'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
  }

  String? _id;
  String? _tag;
  int? _input;
  bool? _sandbox;
  bool? _active;
  String? _createdAt;
  String? _updatedAt;
  Translation? _translation;

  PaymentData copyWith({
    String? id,
    String? tag,
    int? input,
    bool? sandbox,
    bool? active,
    String? createdAt,
    String? updatedAt,
    Translation? translation,
  }) =>
      PaymentData(
        id: id ?? _id,
        tag: tag ?? _tag,
        input: input ?? _input,
        sandbox: sandbox ?? _sandbox,
        active: active ?? _active,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        translation: translation ?? _translation,
      );

  String? get id => _id;

  String? get tag => _tag;

  int? get input => _input;

  bool? get sandbox => _sandbox;

  bool? get active => _active;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Translation? get translation => _translation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['tag'] = _tag;
    map['input'] = _input;
    map['sandbox'] = _sandbox;
    map['active'] = _active;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_translation != null) {
      map['translation'] = _translation?.toJson();
    }
    return map;
  }
}
