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

// compliance-ignore-file: obs-flutter-trace
// Local-only feedback store on shared_preferences: it makes no HTTP calls
// and holds no client. Flagged solely because it lives under
// infrastructure/services/.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Rain-prediction feedback model + local store.
///
/// Ported from pos main's `weather/rain_feedback.dart` (model and
/// [RainFeedbackSystem] halves; the widget half lives in
/// `presentation/widgets/rain_feedback_widget.dart`). pos main also carried a
/// byte-duplicate `rain_feedback_system.dart` with ZERO importers - that dead
/// twin is absorbed here, not ported.
class RainFeedback {
  final DateTime date;
  final int predictedPOP; // Daily chance of rain
  final double precipitationMM; // Precipitation in millimeters
  final int dailyWillItRain; // 1 if rain predicted, 0 if not
  bool userConfirmedRain;
  bool wasEdited; // Track if feedback was edited

  RainFeedback({
    required this.date,
    required this.predictedPOP,
    required this.precipitationMM,
    required this.dailyWillItRain,
    required this.userConfirmedRain,
    this.wasEdited = false,
  });

  bool get wasCorrect {
    // Prediction is correct if:
    // 1. POP >= 80
    // 2. dailyWillItRain is 1 (predicting rain)
    // 3. User confirms rain
    return predictedPOP >= 80 && dailyWillItRain == 1 && userConfirmedRain;
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'predictedPOP': predictedPOP,
        'precipitationMM': precipitationMM,
        'dailyWillItRain': dailyWillItRain,
        'userConfirmedRain': userConfirmedRain,
        'wasEdited': wasEdited,
      };

  factory RainFeedback.fromJson(Map<String, dynamic> json) => RainFeedback(
        date: DateTime.parse(json['date']),
        predictedPOP: json['predictedPOP'] as int,
        precipitationMM: (json['precipitationMM'] as num).toDouble(),
        dailyWillItRain: json['dailyWillItRain'] as int,
        userConfirmedRain: json['userConfirmedRain'] as bool,
        wasEdited: json['wasEdited'] ?? false,
      );

  String get dateString => "${date.year}-${date.month}-${date.day}";
}

class RainFeedbackSystem {
  final String _storageKey = 'rain_feedback';
  static const int popThreshold = 80;
  static const int feedbackStartHour = 6; // 6 AM
  static const int feedbackEndHour = 22; // 10 PM

  Future<void> _clearInvalidFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    // Filter out any entries outside valid hours
    final validFeedback = jsonList
        .map((jsonStr) => RainFeedback.fromJson(jsonDecode(jsonStr)))
        .where(
          (feedback) =>
              feedback.date.hour >= feedbackStartHour &&
              feedback.date.hour <= feedbackEndHour,
        )
        .map((feedback) => jsonEncode(feedback.toJson()))
        .toList();

    // Save only valid feedback
    await prefs.setStringList(_storageKey, validFeedback);
  }

  Future<void> saveFeedback({
    required int pop,
    required double precipMM,
    required int dailyWillItRain,
    required bool userConfirmedRain,
  }) async {
    // Clear invalid feedback before saving
    await _clearInvalidFeedback();

    // Only save if within valid feedback hours
    final now = DateTime.now();
    if (now.hour < feedbackStartHour || now.hour > feedbackEndHour) return;

    final prefs = await SharedPreferences.getInstance();
    final feedbackList = await getFeedbackHistory();

    // Remove any existing feedback for today
    feedbackList.removeWhere(
      (feedback) =>
          feedback.dateString == "${now.year}-${now.month}-${now.day}",
    );

    feedbackList.add(
      RainFeedback(
        date: now,
        predictedPOP: pop,
        precipitationMM: precipMM,
        dailyWillItRain: dailyWillItRain,
        userConfirmedRain: userConfirmedRain,
      ),
    );

    // Keep only last 30 days AND within valid hours
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentValidFeedback = feedbackList
        .where(
          (feedback) =>
              feedback.date.isAfter(thirtyDaysAgo) &&
              feedback.date.hour >= feedbackStartHour &&
              feedback.date.hour <= feedbackEndHour,
        )
        .toList();

    await prefs.setStringList(
      _storageKey,
      recentValidFeedback.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  Future<void> updateFeedback({
    required DateTime date,
    required bool newUserConfirmedRain,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    final updatedJsonList = jsonList.map((jsonStr) {
      final feedback = RainFeedback.fromJson(jsonDecode(jsonStr));

      // Find the feedback for the specific date
      if (feedback.dateString == "${date.year}-${date.month}-${date.day}") {
        feedback.userConfirmedRain = newUserConfirmedRain;
        feedback.wasEdited = true;
      }

      return jsonEncode(feedback.toJson());
    }).toList();

    await prefs.setStringList(_storageKey, updatedJsonList);
  }

  Future<List<RainFeedback>> getFeedbackHistory() async {
    // Clear invalid feedback before retrieving
    await _clearInvalidFeedback();

    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    return jsonList
        .map((jsonStr) => RainFeedback.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  Future<double> getAccuracyRate() async {
    // Clear invalid feedback before calculating
    await _clearInvalidFeedback();

    final feedbackList = await getFeedbackHistory();
    if (feedbackList.isEmpty) return 0.0;

    final correctPredictions =
        feedbackList.where((feedback) => feedback.wasCorrect).length;

    return (correctPredictions / feedbackList.length) * 100;
  }

  Future<bool> hasGivenFeedbackToday() async {
    // Clear invalid feedback before checking
    await _clearInvalidFeedback();

    final now = DateTime.now();
    // Only check for feedback within valid hours
    if (now.hour < feedbackStartHour || now.hour > feedbackEndHour) {
      return true;
    }

    final feedbackList = await getFeedbackHistory();

    return feedbackList.any(
      (feedback) =>
          feedback.dateString == "${now.year}-${now.month}-${now.day}",
    );
  }
}
