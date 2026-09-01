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


class GalleryUploadResponse {
  GalleryUploadResponse({
    String? timestamp,
    bool? status,
    String? message,
    ImageData? imageData,
  }) {
    _timestamp = timestamp;
    _status = status;
    _message = message;
    _imageData = imageData;
  }

  GalleryUploadResponse.fromJson(dynamic json) {
    _timestamp = json['timestamp'];
    _status = json['status'];
    _message = json['message'];
    _imageData = json['data'] != null ? ImageData.fromJson(json['data']) : null;
  }

  String? _timestamp;
  bool? _status;
  String? _message;
  ImageData? _imageData;

  GalleryUploadResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    ImageData? imageData,
  }) =>
      GalleryUploadResponse(
        timestamp: timestamp ?? _timestamp,
        status: status ?? _status,
        message: message ?? _message,
        imageData: imageData ?? _imageData,
      );

  String? get timestamp => _timestamp;

  bool? get status => _status;

  String? get message => _message;

  ImageData? get imageData => _imageData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['timestamp'] = _timestamp;
    map['status'] = _status;
    map['message'] = _message;
    if (_imageData != null) {
      map['data'] = _imageData?.toJson();
    }
    return map;
  }
}

class ImageData {
  ImageData({String? title, String? type}) {
    _title = title;
    _type = type;
  }

  ImageData.fromJson(dynamic json) {
    _title = json['title'];
    _type = json['type'];
  }

  String? _title;
  String? _type;

  ImageData copyWith({String? title, String? type}) =>
      ImageData(title: title ?? _title, type: type ?? _type);

  String? get title => _title;

  String? get type => _type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = _title;
    map['type'] = _type;
    return map;
  }
}
