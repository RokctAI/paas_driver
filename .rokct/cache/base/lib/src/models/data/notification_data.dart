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


class NotificationsModel {
  NotificationsModel({
    this.id,
    this.payload,
    this.active,
    this.createdAt,
    this.updatedAt,
    this.type,
  });

  int? id;
  List<String?>? payload;
  bool? active;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? type;

  factory NotificationsModel.fromJson(Map<String, dynamic> json) {
    return NotificationsModel(
      id: json["id"],
      payload: json["payload"] == null
          ? []
          : json["payload"] == null
              ? []
              : List<String?>.from(json["payload"]!.map((x) => x)),
      active: (json["notification"] != null
                  ? json["notification"]["active"] ?? 0
                  : 0) ==
              0
          ? false
          : true,
      createdAt: DateTime.tryParse(json["created_at"])?.toLocal(),
      updatedAt: DateTime.tryParse(json["updated_at"])?.toLocal(),
      type: json["type"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "payload": payload == null
            ? []
            : payload == null
                ? []
                : List<dynamic>.from(payload!.map((x) => x)),
        "active": active,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "type": type,
      };
}
