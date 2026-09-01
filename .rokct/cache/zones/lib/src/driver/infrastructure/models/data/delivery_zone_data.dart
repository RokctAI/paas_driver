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

class DeliveryZoneData {
  int? id;
  List<List<double>>? address;

  DeliveryZoneData({
    this.id,
    this.address,
  });

  DeliveryZoneData copyWith({
    int? id,
    List<List<double>>? address,
  }) =>
      DeliveryZoneData(
        id: id ?? this.id,
        address: address ?? this.address,
      );

  factory DeliveryZoneData.fromJson(Map<String, dynamic> json) =>
      DeliveryZoneData(
        id: json["id"],
        address: json["address"] == null
            ? []
            : List<List<double>>.from(json["address"]!
                .map((x) => List<double>.from(x.map((x) => x?.toDouble())))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "address": address == null
            ? []
            : List<dynamic>.from(
                address!.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}
