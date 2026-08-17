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
