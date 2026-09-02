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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/infrastructure/services/open_weather_service.dart';
import 'package:weather_sdk/src/common/presentation/widgets/extended_forecast_view.dart';

/// Inline "View More Days" expansion tile that lazily loads the OpenWeather
/// extended forecast. Ported from pos main's
/// `weather/extended_forecast_loader.dart`. Already popup-free, so it is
/// shared verbatim by the large-screen dialog and the small-screen inline
/// card.
class ExtendedForecastLoader extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;

  const ExtendedForecastLoader({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  ConsumerState<ExtendedForecastLoader> createState() =>
      _ExtendedForecastLoaderState();
}

class _ExtendedForecastLoaderState
    extends ConsumerState<ExtendedForecastLoader> {
  bool _isExpanded = false;
  bool _isLoading = false;

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(openWeatherProvider.notifier)
          .loadExtendedForecast(widget.latitude, widget.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load extended forecast',
              style: GoogleFonts.inter(color: AppStyle.cardDark),
            ),
            backgroundColor: AppStyle.textPrimary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openWeatherState = ref.watch(openWeatherProvider);

    return Column(
      children: [
        // View More tile
        ListTile(
          title: Text(
            'View More Days',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppStyle.textPrimary,
            ),
          ),
          trailing: _isLoading
              ? SizedBox(
                  width: 24.sp,
                  height: 24.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppStyle.textPrimary),
                  ),
                )
              : Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppStyle.textPrimary,
                ),
          onTap: () async {
            if (_isLoading) return;

            setState(() {
              _isExpanded = !_isExpanded;
            });

            if (_isExpanded && !openWeatherState.hasValue) {
              await _loadData();
            }
          },
        ),

        // Show extended forecast when expanded
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          const ExtendedForecastView(),
        ],
      ],
    );
  }
}
