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


import 'package:base_sdk/src/models/data/product_data.dart';

class SingleProductResponse {
  SingleProductResponse({
    String? timestamp,
    bool? status,
    String? message,
    ProductData? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  SingleProductResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? ProductData.fromJson(json['data']) : null;
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  ProductData? _data;

  SingleProductResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    ProductData? data,
  }) =>
      SingleProductResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  ProductData? get data => _data;

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
