// Copyright (c) 2026 RokctAI
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

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/components/buttons/second_button.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';

import 'registration_step.dart';

/// Entry points the register flow (and the installed shell) use to run the
/// contributed-steps pipeline. Static, like `AppRoutes.I` — the register
/// notifier lives in auth_sdk and cannot see the host-composed step list,
/// so it navigates to the shell route BY PATH ('/registration-steps',
/// declared in auth_sdk's own manifest "routes") and hands the fresh
/// account over through [lastRegisteredUser]. Path navigation is the one
/// sanctioned bridge that needs neither a host import (ADR-005) nor a new
/// method on base_sdk's fixed AppRoutes interface.
class RegistrationFlow {
  RegistrationFlow._();

  /// The account created by the just-completed registration, when the flow
  /// had one to hand over. Written by [completeRegistration], read by
  /// [RegistrationStepsPage] and exposed to each step via
  /// [RegistrationStepScope.account]. Cleared when the pipeline finishes.
  static ProfileData? lastRegisteredUser;

  /// Registration succeeded: run the contributed steps, then land wherever
  /// registration used to land. Replaces the five hand-written
  /// `isDemo ? replaceUiTypeRoute : goHome` completion sites — with no
  /// contributed steps the shell falls straight through to
  /// [defaultLanding], so apps without contributions behave as before.
  static void completeRegistration(BuildContext context, {ProfileData? user}) {
    lastRegisteredUser = user;
    // Replaces the top page like the old goHome/replaceUiTypeRoute did, so
    // the register modal sheets above it are dismissed the same way.
    context.router.replaceNamed('/registration-steps');
  }

  /// The app's normal post-registration destination — exactly the branch
  /// every completion site used before the pipeline existed.
  static void defaultLanding(BuildContext context) {
    if (AppConstants.isDemo) {
      AppRoutes.I.replaceUiTypeRoute(context);
    } else {
      AppHelpers.goHome(context);
    }
  }
}

/// What the installed shell hands the pipeline: the composed step list and
/// where to go when it finishes (mirrors onboarding_sdk's `IntroDeps`).
class RegistrationStepsDeps {
  final List<RegistrationStep> steps;

  /// Called once, after the last step (or immediately when no visible steps
  /// were contributed). The shell's default is [RegistrationFlow.defaultLanding],
  /// optionally preceded by SDK-injected completion logic (manifest
  /// "integrations" targeting the shell's @registration-complete-hook).
  final void Function(BuildContext context) onComplete;

  const RegistrationStepsDeps({
    this.steps = const [],
    this.onComplete = RegistrationFlow.defaultLanding,
  });
}

/// The contributed-steps pipeline page: sequences the visible
/// [RegistrationStep]s one at a time on the same branded dark surface the
/// onboarding shell uses (a soft brand glow, the step's card anchored low),
/// with a progress indicator and a per-step "Skip" pill when the step
/// allows it. Each step's content is wrapped in a [RegistrationStepScope]
/// carrying the flow controls and the freshly registered account.
///
/// Stateful so the visible-step list is resolved ONCE — a contributed
/// step's widgets may hold their own state across rebuilds.
class RegistrationStepsPage extends StatefulWidget {
  final RegistrationStepsDeps deps;

  const RegistrationStepsPage({super.key, this.deps = const RegistrationStepsDeps()});

  @override
  State<RegistrationStepsPage> createState() => _RegistrationStepsPageState();
}

class _RegistrationStepsPageState extends State<RegistrationStepsPage> {
  late final List<RegistrationStep> _steps =
      widget.deps.steps.where((s) => s.visible).toList(growable: false);
  late final ProfileData? _account = RegistrationFlow.lastRegisteredUser;
  int _index = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    if (_steps.isEmpty) {
      // No contributions in this composition: fall straight through to the
      // normal landing, exactly the pre-pipeline behavior.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _complete();
      });
    }
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    RegistrationFlow.lastRegisteredUser = null;
    widget.deps.onComplete(context);
  }

  void _next() {
    if (_index + 1 < _steps.length) {
      setState(() => _index++);
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      // One frame while the post-frame callback lands.
      return Scaffold(
        backgroundColor: AppStyle.surfaceDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final step = _steps[_index];
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: Stack(
        children: [
          // Brand glow — same treatment as the onboarding scaffold, so the
          // two capture flows read as one product.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    AppStyle.primary.withOpacity(0.14),
                    AppStyle.surfaceDark.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      if (_steps.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '${_index + 1}/${_steps.length}',
                            style: AppStyle.interNormal(
                              size: 12,
                              color: AppStyle.textDarkSecondary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (step.skippable)
                        // Same pill affordance login and onboarding use for
                        // Skip; skipping advances without the step's write.
                        SecondButton(
                          onTap: _next,
                          title: AppHelpers.getTranslation(TrKeys.skip),
                          bgColor: AppStyle.primary,
                          titleColor: AppStyle.white,
                          titleSize: 12,
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: RegistrationStepScope(
                        next: _next,
                        data: step.data,
                        index: _index,
                        total: _steps.length,
                        account: _account,
                        child: step.content,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
