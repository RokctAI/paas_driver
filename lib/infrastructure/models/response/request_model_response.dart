import 'dart:convert';

import '../data/request_model_data.dart';
import 'parcel_response.dart';

RequestModelResponse requestModelResponseFromJson(String str) => RequestModelResponse.fromJson(json.decode(str));

String requestModelResponseToJson(RequestModelResponse data) => json.encode(data.toJson());

class RequestModelResponse {
  List<RequestModelData>? data;
  Links? links;
  Meta? meta;

  RequestModelResponse({
    this.data,
    this.links,
    this.meta,
  });

  RequestModelResponse copyWith({
    List<RequestModelData>? data,
    Links? links,
    Meta? meta,
  }) =>
      RequestModelResponse(
        data: data ?? this.data,
        links: links ?? this.links,
        meta: meta ?? this.meta,
      );

  factory RequestModelResponse.fromJson(Map<String, dynamic> json) => RequestModelResponse(
    data: json["data"] == null ? [] : List<RequestModelData>.from(json["data"]!.map((x) => RequestModelData.fromJson(x))),
    links: json["links"] == null ? null : Links.fromJson(json["links"]),
    meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "links": links?.toJson(),
    "meta": meta?.toJson(),
  };
}





