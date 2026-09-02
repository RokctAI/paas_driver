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

  String? id;
  String? type;
  bool? active;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<String?>? payload;

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        id: (json["id"] ?? json["name"])?.toString(),
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
