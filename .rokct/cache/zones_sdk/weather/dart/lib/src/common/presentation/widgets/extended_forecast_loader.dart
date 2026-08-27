// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
