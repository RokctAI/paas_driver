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
