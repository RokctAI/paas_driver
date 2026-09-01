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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_icon_mapper.dart';

/// Ported from pos main's `weather/weather_icon.dart`
/// (`AppConstants.weatherIcon` -> [WeatherSdkConfig.useNetworkIcons]).
class WeatherIcon extends StatelessWidget {
  final Map<String, dynamic> condition;
  final double size;
  final Color? color;
  final bool isNight;

  const WeatherIcon({
    super.key,
    required this.condition,
    required this.size,
    this.color,
    this.isNight = false,
  });

  IconData _getLocalIcon() {
    try {
      final conditionCode = condition['code'] as int?;
      if (conditionCode == null) return Remix.cloud_fill;

      return WeatherIconMapper.getRemixIcon(conditionCode, isNight: isNight);
    } catch (e) {
      debugPrint('Error getting local weather icon: $e');
      return Remix.cloud_fill;
    }
  }

  Widget _buildNetworkIcon(String iconUrl) {
    return CachedNetworkImage(
      imageUrl: iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) {
        debugPrint('Error loading weather icon: $error');
        return _buildLocalIcon();
      },
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          _buildLoadingIndicator(downloadProgress.progress),
    );
  }

  Widget _buildLocalIcon() {
    return Icon(_getLocalIcon(),
        size: size, color: color ?? AppStyle.textPrimary);
  }

  Widget _buildLoadingIndicator(double? progress) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
          color: color ?? AppStyle.textPrimary,
        ),
      ),
    );
  }

  String? _getIconUrl() {
    try {
      final iconPath = condition['icon'] as String?;
      if (iconPath == null || iconPath.isEmpty) return null;

      // Ensure URL starts with https://
      if (!iconPath.startsWith('http')) {
        return 'https:$iconPath';
      }
      return iconPath;
    } catch (e) {
      debugPrint('Error getting weather icon URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Early return if condition is null or empty
    if (condition.isEmpty) {
      return _buildLocalIcon();
    }

    // Use local icons if network icons are disabled
    if (!WeatherSdkConfig.useNetworkIcons) {
      return _buildLocalIcon();
    }

    // Get icon URL
    final iconUrl = _getIconUrl();
    if (iconUrl == null) {
      return _buildLocalIcon();
    }

    return _buildNetworkIcon(iconUrl);
  }
}
