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
