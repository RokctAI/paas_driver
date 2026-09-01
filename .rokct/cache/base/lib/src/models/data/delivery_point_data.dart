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

DeliveryPointData deliveryPointDataFromJson(String str) =>
    DeliveryPointData.fromJson(json.decode(str));

String deliveryPointDataToJson(DeliveryPointData data) =>
    json.encode(data.toJson());

class DeliveryPointData {
  String? id;
  String? name;
  String? address;
  double? latitude;
  double? longitude;
  String? img;
  double? distance;

  DeliveryPointData({
    this.id,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.img,
    this.distance,
  });

  factory DeliveryPointData.fromJson(Map<String, dynamic> json) =>
      DeliveryPointData(
        id: json["name"],
        name: json["name"],
        address: json["address"],
        latitude: (json["latitude"] as num?)?.toDouble(),
        longitude: (json["longitude"] as num?)?.toDouble(),
        img: json["img"],
        distance: (json["distance"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "address": address,
        "latitude": latitude,
        "longitude": longitude,
        "img": img,
        "distance": distance,
      };
}
