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


// ignore_for_file: file_names

class ParcelCalculateResponse {
  DateTime? timestamp;
  bool? status;
  String? message;
  Data? data;

  ParcelCalculateResponse({
    this.timestamp,
    this.status,
    this.message,
    this.data,
  });

  ParcelCalculateResponse copyWith({
    DateTime? timestamp,
    bool? status,
    String? message,
    Data? data,
  }) =>
      ParcelCalculateResponse(
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory ParcelCalculateResponse.fromJson(Map<String, dynamic> json) =>
      ParcelCalculateResponse(
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.parse(json["timestamp"]),
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp?.toIso8601String(),
        "status": status,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  num? price;
  num? km;

  Data({this.price, this.km});

  Data copyWith({num? price, num? km}) =>
      Data(price: price ?? this.price, km: km ?? this.km);

  factory Data.fromJson(Map<String, dynamic> json) =>
      Data(price: json["price"], km: json["km"]);

  Map<String, dynamic> toJson() => {"price": price, "km": km};
}
