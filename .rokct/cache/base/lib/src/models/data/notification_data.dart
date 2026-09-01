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
