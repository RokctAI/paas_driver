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
