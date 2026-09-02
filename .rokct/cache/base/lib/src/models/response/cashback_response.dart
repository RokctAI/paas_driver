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


class CashbackResponse {
  CashbackResponse({
    String? timestamp,
    bool? status,
    String? message,
    CashbackData? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  CashbackResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    _data = json['data'] != null ? CashbackData.fromJson(json['data']) : null;
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  CashbackData? _data;

  CashbackResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    CashbackData? data,
  }) =>
      CashbackResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  CashbackData? get data => _data;

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

class CashbackData {
  CashbackData({num? price}) {
    _price = price;
  }

  CashbackData.fromJson(dynamic json) {
    _price = json['price'];
  }

  num? _price;

  CashbackData copyWith({num? price}) => CashbackData(price: price ?? _price);

  num? get price => _price;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['price'] = _price;
    return map;
  }
}
