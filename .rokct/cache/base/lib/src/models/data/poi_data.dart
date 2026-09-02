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


// infrastructure/models/data/poi_data.dart
import 'package:flutter/material.dart';

class POIData {
  final String name;
  final double latitude;
  final double longitude;
  final Color titleColor;
  final String pin;

  POIData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.titleColor,
    required this.pin,
  });

  @override
  String toString() {
    return 'POIData{name: $name, latitude: $latitude, longitude: $longitude, titleColor: $titleColor, pin: $pin}';
  }
}
