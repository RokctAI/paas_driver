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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/application/weather/weather_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/rain_feedback_system.dart';

/// "Raining?" thumbs-up/down prompt shown when a high-POP rain prediction is
/// active. Ported from pos main's `weather/rain_feedback.dart` (widget half).
///
/// Adaptive change vs pos: the "changed mind?" correction originally opened
/// an AlertDialog. Per Ray ("no popups in small screens") the dialog is only
/// used on large screens; on small screens tapping the edit icon re-shows
/// the inline thumbs row instead, and a thumbs-up there applies the same
/// correction the dialog's "Yes" applied.
class RainFeedbackWidget extends StatefulWidget {
  final WeatherState weatherState;
  final bool showCityName;

  const RainFeedbackWidget({
    super.key,
    required this.weatherState,
    this.showCityName = false,
  });

  @override
  State<RainFeedbackWidget> createState() => _RainFeedbackWidgetState();
}

class _RainFeedbackWidgetState extends State<RainFeedbackWidget> {
  final RainFeedbackSystem _feedbackSystem = RainFeedbackSystem();
  bool _showingAccuracy = false;
  double _accuracy = 0.0;
  bool _showEditIcon = false;
  bool _editingInline = false;

  int _getChanceOfRain() {
    final now = DateTime.now();
    return widget.weatherState.forecast[0]['hour'][now.hour]['chance_of_rain']
        as int;
  }

  int _getDailyWillItRain() {
    final now = DateTime.now();
    return widget.weatherState.forecast[0]['hour'][now.hour]['will_it_rain']
        as int;
  }

  double _getPrecipitation() {
    final now = DateTime.now();
    return (widget.weatherState.forecast[0]['hour'][now.hour]['precip_mm']
            as num)
        .toDouble();
  }

  Future<void> _handleFeedback(bool wasRaining) async {
    if (_editingInline) {
      // Small-screen correction path: same effect as the dialog's answer.
      await _applyCorrection(wasRaining);
      return;
    }

    await _feedbackSystem.saveFeedback(
      pop: _getChanceOfRain(),
      precipMM: _getPrecipitation(),
      dailyWillItRain: _getDailyWillItRain(),
      userConfirmedRain: wasRaining,
    );

    final accuracy = await _feedbackSystem.getAccuracyRate();

    if (!mounted) return;
    setState(() {
      _showingAccuracy = true;
      _accuracy = accuracy;
      _showEditIcon = !wasRaining; // Show edit icon if user says no
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showingAccuracy = false;
          // Optionally keep edit icon visible if it was set to true
        });
      }
    });
  }

  Future<void> _applyCorrection(bool itDidRain) async {
    if (itDidRain) {
      await _feedbackSystem.updateFeedback(
        date: DateTime.now(),
        newUserConfirmedRain: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _editingInline = false;
      _showEditIcon = !itDidRain;
    });

    if (itDidRain) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Feedback updated. Thanks for the correction!',
            style: TextStyle(fontSize: 12.sp),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleEditFeedback() async {
    if (!WeatherSdkConfig.isLargeScreen(context)) {
      // Popup-free path: swap back to the thumbs row inline.
      setState(() {
        _editingInline = true;
        _showEditIcon = false;
      });
      return;
    }

    // Show a dialog to confirm changing feedback (large screens only)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Rain Feedback'),
        content: const Text('Did it rain after your previous "No" response?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _applyCorrection(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Only allow feedback between 6 AM and 10 PM
    if (now.hour < RainFeedbackSystem.feedbackStartHour ||
        now.hour > RainFeedbackSystem.feedbackEndHour) {
      return const SizedBox.shrink();
    }

    final pop = _getChanceOfRain();
    final dailyWillItRain = _getDailyWillItRain();

    // Only show feedback widget if:
    // 1. POP is >= threshold
    // 2. dailyWillItRain is 1
    // 3. Not showing city name
    if (pop < RainFeedbackSystem.popThreshold ||
        dailyWillItRain != 1 ||
        widget.showCityName) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _feedbackSystem.hasGivenFeedbackToday(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final hasGivenFeedback = snapshot.data ?? true;
        if (hasGivenFeedback &&
            !_showingAccuracy &&
            !_showEditIcon &&
            !_editingInline) {
          return const SizedBox.shrink();
        }

        // If showing accuracy
        if (_showingAccuracy) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Accuracy: ${_accuracy.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue.shade700,
                height: 1,
              ),
            ),
          );
        }

        // If showing edit icon after saying no
        if (_showEditIcon) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Changed mind?',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppStyle.textPrimary,
                  height: 1,
                ),
              ),
              SizedBox(width: 8.sp),
              InkWell(
                onTap: _handleEditFeedback,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: EdgeInsets.all(4.sp),
                  child: Icon(
                    Remix.refresh_line,
                    size: 18.sp,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
            ],
          );
        }

        // Default to feedback buttons (also the inline correction row)
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _editingInline ? 'Did it rain?' : 'Raining?',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppStyle.textPrimary,
                height: 1,
              ),
            ),
            SizedBox(width: 8.sp),
            InkWell(
              onTap: () => _handleFeedback(true),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(4.sp),
                child: Icon(
                  Remix.thumb_up_fill,
                  size: 18.sp,
                  color: Colors.green.shade600,
                ),
              ),
            ),
            SizedBox(width: 4.sp),
            InkWell(
              onTap: () => _handleFeedback(false),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(4.sp),
                child: Icon(
                  Remix.thumb_down_fill,
                  size: 18.sp,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
