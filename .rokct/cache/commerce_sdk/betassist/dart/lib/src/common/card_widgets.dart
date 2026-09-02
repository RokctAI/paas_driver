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
import 'models.dart';

// Palette mapping specifically customizable inside B2B SDK
class SDKColors {
  final Color background;
  final Color surface;
  final Color accent;
  final Color alert;
  final Color textPrimary;
  final Color textSecondary;

  const SDKColors({
    this.background = const Color(0xFF0A0E12),
    this.surface = const Color(0xFF141A22),
    this.accent = const Color(0xFF00E676),
    this.alert = const Color(0xFFFF3D00),
    this.textPrimary = Colors.white,
    this.textSecondary = const Color(0xFF90A4AE),
  });
}

// AR Floating Card: Front View
class ARCardFront extends StatelessWidget {
  final SoccerMatch match;
  final bool isFav;
  final SDKColors colors;

  const ARCardFront({
    super.key,
    required this.match,
    required this.isFav,
    this.colors = const SDKColors(),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surface.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isFav ? colors.alert : colors.accent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(match.league, style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(match.teamALogo, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(match.teamA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Text("VS", style: TextStyle(fontSize: 20, color: colors.textSecondary, fontWeight: FontWeight.bold)),
                Column(
                  children: [
                    Text(match.teamBLogo, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(match.teamB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text("AI PREDICTION CONFIDENCE", style: TextStyle(fontSize: 10, color: colors.textSecondary, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text("${match.confidenceScore.toStringAsFixed(0)}%", 
                 style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: isFav ? colors.alert : colors.accent)),
            const SizedBox(height: 24),
            Icon(Icons.touch_app, color: colors.textSecondary),
            const SizedBox(height: 4),
            Text("TAP CARD TO FLIP ANALYSIS", style: TextStyle(fontSize: 10, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// AR Floating Card: Back View
class ARCardBack extends StatelessWidget {
  final SoccerMatch match;
  final bool isFav;
  final bool isFollowing;
  final double recommendedStake;
  final VoidCallback onPlaceBet;
  final bool showBetting;
  final SDKColors colors;

  const ARCardBack({
    super.key,
    required this.match,
    required this.isFav,
    required this.isFollowing,
    required this.recommendedStake,
    required this.onPlaceBet,
    this.showBetting = true,
    this.colors = const SDKColors(),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surface.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isFav && showBetting ? colors.alert : colors.accent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("LIVE ALIGNMENT REPORT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.accent)),
                if (isFav && showBetting)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: colors.alert, borderRadius: BorderRadius.circular(4)),
                    child: const Text("BIAS DANGER", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text("STRENGTHS:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text(match.whyWin, style: const TextStyle(fontSize: 11, color: Colors.white)),
            const SizedBox(height: 12),
            Text("VULNERABILITIES:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
            const SizedBox(height: 4),
            Text(match.whyLose, style: const TextStyle(fontSize: 11, color: Colors.white)),
            const SizedBox(height: 16),

            if (!showBetting) ...[
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insights, color: colors.accent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "AI Match Analysis Mode",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else if (isFav) ...[
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.alert.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.alert.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, color: colors.alert, size: 28),
                      const SizedBox(height: 8),
                      Text("Betting Blocked", style: TextStyle(fontWeight: FontWeight.bold, color: colors.alert, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text(
                        "This is your favorite team. Under discipline rules, betting on this match is fully prohibited to eliminate personal bias.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!isFollowing) ...[
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      const SizedBox(height: 8),
                      const Text("Unfollowed Match", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text(
                        "You must actively follow either team in the dashboard to unlock placing bets on this match.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recommended Risk Stake:"),
                  Text("R ${recommendedStake.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: colors.accent)),
                ],
              ),
              const SizedBox(height: 8),
              Text("Calculated via the 2% monthly budget rule limit.", style: TextStyle(fontSize: 10, color: colors.textSecondary)),
              const Spacer(),
              ElevatedButton(
                onPressed: onPlaceBet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("PLACE DISCIPLINED BET NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
