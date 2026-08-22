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


import 'dart:convert';

NotificationsListModel? notificationsListModelFromJson(dynamic str) =>
    NotificationsListModel.fromJson(str);

String notificationsListModelToJson(NotificationsListModel? data) =>
    json.encode(data!.toJson());

class NotificationsListModel {
  NotificationsListModel({this.data});

  List<NotificationData>? data;

  factory NotificationsListModel.fromJson(Map<String, dynamic> json) =>
      NotificationsListModel(
        data: json["data"] == null
            ? []
            : List<NotificationData>.from(
                json["data"]!.map((x) => NotificationData.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class NotificationData {
  NotificationData({
    this.id,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.payload,
    this.active,
  });

  int? id;
  String? type;
  bool? active;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<String?>? payload;

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        id: json["id"],
        type: json["type"],
        createdAt: DateTime.tryParse(json["created_at"])?.toLocal(),
        updatedAt: DateTime.tryParse(json["updated_at"])?.toLocal(),
        active: false,
        payload: json["payload"] == null
            ? []
            : json["payload"] == null
                ? []
                : List<String?>.from(json["payload"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "payload": payload == null
            ? []
            : payload == null
                ? []
                : List<dynamic>.from(payload!.map((x) => x)),
      };
}
