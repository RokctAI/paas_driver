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


class MultiGalleryUploadResponse {
  DateTime? timestamp;
  bool? status;
  String? message;
  MultiGalleryUploadData? data;

  MultiGalleryUploadResponse({
    this.timestamp,
    this.status,
    this.message,
    this.data,
  });

  MultiGalleryUploadResponse copyWith({
    DateTime? timestamp,
    bool? status,
    String? message,
    MultiGalleryUploadData? data,
  }) =>
      MultiGalleryUploadResponse(
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory MultiGalleryUploadResponse.fromJson(Map<String, dynamic> json) =>
      MultiGalleryUploadResponse(
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : MultiGalleryUploadData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp?.toIso8601String(),
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class MultiGalleryUploadData {
  List<String>? title;
  String? type;

  MultiGalleryUploadData({this.title, this.type});

  MultiGalleryUploadData copyWith({List<String>? title, String? type}) =>
      MultiGalleryUploadData(
        title: title ?? this.title,
        type: type ?? this.type,
      );

  factory MultiGalleryUploadData.fromJson(Map<String, dynamic> json) =>
      MultiGalleryUploadData(
        title: json["title"] == null
            ? []
            : List<String>.from(json["title"]!.map((x) => x)),
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "title": title == null ? [] : List<dynamic>.from(title!.map((x) => x)),
        "type": type,
      };
}
