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
