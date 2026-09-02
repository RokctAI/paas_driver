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

class SoccerMatch {
  final String id;
  final String teamA;
  final String teamB;
  final String teamALogo;
  final String teamBLogo;
  final DateTime kickoffTime;
  final String league;
  final String status;
  final String score;
  final double confidenceScore;
  final String predictedWinner;
  final String whyWin;
  final String whyLose;

  SoccerMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.teamALogo,
    required this.teamBLogo,
    required this.kickoffTime,
    required this.league,
    required this.status,
    required this.score,
    required this.confidenceScore,
    required this.predictedWinner,
    required this.whyWin,
    required this.whyLose,
  });
}
