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


class GenerateImageModel {
  GenerateImageModel({this.created, this.data});

  int? created;
  List<Datum>? data;

  GenerateImageModel copyWith({int? created, List<Datum>? data}) =>
      GenerateImageModel(
        created: created ?? this.created,
        data: data ?? this.data,
      );

  factory GenerateImageModel.fromJson(Map<String, dynamic> json) =>
      GenerateImageModel(
        created: json["created"],
        data: json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "created": created,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class Datum {
  Datum({this.url});

  String? url;

  Datum copyWith({String? url}) => Datum(url: url ?? this.url);

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(url: json["url"]);

  Map<String, dynamic> toJson() => {"url": url};
}
