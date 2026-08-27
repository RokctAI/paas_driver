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
