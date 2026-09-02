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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/request_model_data.dart';
// Links from the legacy parcel_response wrapper was never read by any
// consumer (only .data is), so the field was dropped in the move; Meta
// comes from base.
import 'package:base_sdk/src/models/data/meta.dart';

RequestModelResponse requestModelResponseFromJson(String str) =>
    RequestModelResponse.fromJson(json.decode(str));

String requestModelResponseToJson(RequestModelResponse data) =>
    json.encode(data.toJson());

class RequestModelResponse {
  List<RequestModelData>? data;
  Meta? meta;

  RequestModelResponse({
    this.data,
    this.meta,
  });

  RequestModelResponse copyWith({
    List<RequestModelData>? data,
    Meta? meta,
  }) =>
      RequestModelResponse(
        data: data ?? this.data,
        meta: meta ?? this.meta,
      );

  factory RequestModelResponse.fromJson(Map<String, dynamic> json) =>
      RequestModelResponse(
        data: json["data"] == null
            ? []
            : List<RequestModelData>.from(
                json["data"]!.map((x) => RequestModelData.fromJson(x))),
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "meta": meta?.toJson(),
      };
}
