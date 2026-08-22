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


class AddressInformation {
  AddressInformation({String? address, String? house, String? floor}) {
    _address = address;
    _house = house;
    _floor = floor;
  }

  AddressInformation.fromJson(dynamic json) {
    _address = json?['address'];
    _house = json?['house'];
    _floor = json?['floor'];
  }

  String? _address;
  String? _house;
  String? _floor;

  AddressInformation copyWith({
    String? address,
    String? house,
    String? floor,
  }) =>
      AddressInformation(
        address: address ?? _address,
        house: house ?? _house,
        floor: floor ?? _floor,
      );

  String? get address => _address;

  String? get house => _house;

  String? get floor => _floor;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = _address;
    map['house'] = _house;
    map['floor'] = _floor;
    return map;
  }
}
