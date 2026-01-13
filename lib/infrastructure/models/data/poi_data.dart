// infrastructure/models/data/poi_data.dart
import 'package:flutter/material.dart';

class POIData {
  final String name;
  final double latitude;
  final double longitude;
  final Color titleColor;

  POIData({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.titleColor,
  });

  @override
  String toString() {
    return 'POIData{name: $name, latitude: $latitude, longitude: $longitude, titleColor: $titleColor}';
  }
}
