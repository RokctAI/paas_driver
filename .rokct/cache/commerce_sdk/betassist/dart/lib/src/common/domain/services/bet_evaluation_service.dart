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
// Pure domain logic: this service performs no HTTP calls (it evaluates
// responsible-gambling rules in memory). It is flagged only by the
// 'service' path heuristic; there is no request to trace.
import '../../models.dart';

class BetEvaluationResult {
  final bool isBlocked;
  final bool showWarning;
  final String? warningMessage;
  final double recommendedStake;

  BetEvaluationResult({
    required this.isBlocked,
    required this.showWarning,
    this.warningMessage,
    this.recommendedStake = 0.0,
  });
}

class BetEvaluationService {
  BetEvaluationService._();

  /// Evaluates responsible gambling rules for a given soccer match.
  /// 
  /// - Prevents emotional betting by blocking/warning on favorite teams.
  /// - Enforces the 2% monthly budget stake rule scaled by AI confidence score.
  static BetEvaluationResult evaluate({
    required SoccerMatch match,
    required String? favoriteLocalTeam,
    required String? favoriteIntlTeam,
    required double monthlyBudget,
  }) {
    final isLocalFavMatch = favoriteLocalTeam != null && 
        (match.teamA.toLowerCase() == favoriteLocalTeam.toLowerCase() || 
         match.teamB.toLowerCase() == favoriteLocalTeam.toLowerCase());
         
    final isIntlFavMatch = favoriteIntlTeam != null && 
        (match.teamA.toLowerCase() == favoriteIntlTeam.toLowerCase() || 
         match.teamB.toLowerCase() == favoriteIntlTeam.toLowerCase());

    // 1. Check for Favorite Team Bias
    if (isLocalFavMatch || isIntlFavMatch) {
      final favTeam = isLocalFavMatch ? favoriteLocalTeam! : favoriteIntlTeam!;
      final predictedWinner = match.predictedWinner;
      final isFavPredictedToWin = predictedWinner.toLowerCase() == favTeam.toLowerCase();

      if (isFavPredictedToWin) {
        return BetEvaluationResult(
          isBlocked: false,
          showWarning: true,
          warningMessage: "Emotional Bias Alert: You are evaluating your favorite team ($favTeam). Proceed with extreme caution.",
          recommendedStake: 0.0, // UI should hide standard placement buttons or advise skipping
        );
      } else {
        return BetEvaluationResult(
          isBlocked: true,
          showWarning: true,
          warningMessage: "Emotional Block: Analysis predicts $predictedWinner wins against your favorite team ($favTeam). Betting is disabled to protect bankroll.",
          recommendedStake: 0.0,
        );
      }
    }

    // 2. Objective Match: Calculate stakes based on the 2% Rule
    // Max Stake = 2% of Monthly Budget
    final double maxStake = monthlyBudget * 0.02;

    // Stake scales linearly with AI confidence score (e.g. 80% confidence yields 80% of max stake)
    final double confidenceFactor = (match.confidenceScore / 100).clamp(0.0, 1.0);
    final double recommendedStake = maxStake * confidenceFactor;

    return BetEvaluationResult(
      isBlocked: false,
      showWarning: false,
      recommendedStake: double.parse(recommendedStake.toStringAsFixed(2)),
    );
  }
}
