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
import 'package:onboarding_sdk/onboarding_sdk.dart';
import 'widgets/team_selector.dart';
import 'widgets/budget_selector.dart';

class BetAssistOnboardingFlow {
  BetAssistOnboardingFlow._();

  static List<IntroSlide> getSlides({
    required ValueChanged<String> onLocalTeamSelected,
    required ValueChanged<String> onIntlTeamSelected,
    required ValueChanged<double> onBudgetSelected,
    double currentBudget = 1000,
  }) {
    return [
      IntroSlide(
        title: "Support Your Local Team",
        description: "Select your favorite local PSL team to activate bias locks.",
        customContent: TeamSelectorWidget(
          title: "Select Local Favorite",
          teams: const [
            "Orlando Pirates",
            "Kaizer Chiefs",
            "Mamelodi Sundowns",
            "SuperSport United",
            "Cape Town City",
            "AmaZulu FC",
          ],
          onTeamSelected: onLocalTeamSelected,
        ),
      ),
      IntroSlide(
        title: "Support Your International Team",
        description: "Select your favorite European league team to activate bias locks.",
        customContent: TeamSelectorWidget(
          title: "Select International Favorite",
          teams: const [
            "Manchester City",
            "Arsenal",
            "Liverpool",
            "Real Madrid",
            "Barcelona",
            "Bayern Munich",
          ],
          onTeamSelected: onIntlTeamSelected,
        ),
      ),
      IntroSlide(
        title: "Set Your Limits",
        description: "Enforce monthly stakes guidelines automatically.",
        customContent: BudgetSelectorWidget(
          initialBudget: currentBudget,
          onBudgetSelected: onBudgetSelected,
        ),
      ),
    ];
  }
}
