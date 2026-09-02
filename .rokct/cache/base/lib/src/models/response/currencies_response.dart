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


import 'package:base_sdk/src/models/data/currency_data.dart';

class CurrenciesResponse {
  CurrenciesResponse({
    String? timestamp,
    bool? status,
    String? message,
    List<CurrencyData>? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  CurrenciesResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(CurrencyData.fromJson(v));
      });
    }
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  List<CurrencyData>? _data;

  CurrenciesResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    List<CurrencyData>? data,
  }) =>
      CurrenciesResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  List<CurrencyData>? get data => _data;

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
