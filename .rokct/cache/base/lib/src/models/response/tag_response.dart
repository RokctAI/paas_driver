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


import 'package:base_sdk/src/models/data/take_data.dart';

class TagResponse {
  TagResponse({
    List<TakeModel>? data,
    // Links? links,
  }) {
    _data = data;
  }

  TagResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(TakeModel.fromJson(v));
      });
    }
  }

  List<TakeModel>? _data;

  List<TakeModel>? get data => _data;
}

class PriceModel {
  PriceModel({
    required this.timestamp,
    required this.status,
    required this.message,
    required this.data,
  });

  DateTime timestamp;
  bool status;
  String message;
  Data data;

  factory PriceModel.fromJson(Map<String, dynamic> json) => PriceModel(
        timestamp:
            DateTime.tryParse(json["timestamp"])?.toLocal() ?? DateTime.now(),
        status: json["status"],
        message: json["message"],
        data: Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp.toIso8601String(),
        "status": status,
        "message": message,
        "data": data.toJson(),
      };
}

class Data {
  Data({required this.min, required this.max});

  double min;
  double max;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        min: double.tryParse(json["min"].toString()) ?? 1,
        max: double.tryParse(json["max"].toString()) ?? 100,
      );

  Map<String, dynamic> toJson() => {"min": min, "max": max};
}
