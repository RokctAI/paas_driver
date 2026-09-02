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


class MobileTranslationsResponse {
  MobileTranslationsResponse({
    String? timestamp,
    bool? status,
    String? message,
    Map<String, dynamic>? data,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _data = data;
  }

  MobileTranslationsResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    _data = json['data'];
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  Map<String, dynamic>? _data;

  MobileTranslationsResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    Map<String, dynamic>? data,
  }) =>
      MobileTranslationsResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        data: data ?? _data,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  Map<String, dynamic>? get data => _data;
}
