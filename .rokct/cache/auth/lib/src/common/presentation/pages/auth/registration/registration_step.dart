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

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:flutter/widgets.dart';

/// A host-supplied post-registration step — the register flow's counterpart
/// of onboarding_sdk's `OnboardingSlide` ("auth can do what we do with
/// onboarding").
///
/// auth_sdk owns only the core account step (credentials, OTP) and the
/// generic pipeline that runs AFTER it succeeds — sequencing, the progress
/// indicator, the skip affordance. Anything domain-specific (Supacharge's
/// school + grade capture, a future app's whatever) arrives as one of
/// these, declared in the contributing SDK's manifest.json
/// "registration_steps" list and injected by sdk_installer_base.py's
/// update_registration_steps() into the installed shell
/// (lib/presentation/routes/registration_step_pages.dart) — so auth_sdk
/// never learns what a school is, exactly as onboarding_sdk never learned
/// what a grade is.
///
/// The [content] widget reaches the flow through [RegistrationStepScope],
/// so a step can advance the pipeline without auth_sdk exposing internals
/// to host code:
///
/// ```dart
/// RegistrationStep(
///   skippable: true,
///   content: Builder(builder: (context) => MyStep(
///     onDone: () => RegistrationStepScope.of(context).next(),
///   )),
/// )
/// ```
class RegistrationStep {
  /// False keeps the step out of the pipeline entirely — it is not rendered
  /// and does not count toward the progress indicator. Contributors use this
  /// for conditional steps instead of asking auth_sdk for a branch flag.
  final bool visible;

  /// Whether the pipeline scaffold offers a "Skip" affordance for this step.
  /// Defaults to true: a contributed step must never trap a freshly
  /// registered user — the same rule the onboarding slides follow (their
  /// writes are best-effort and the profile offers the fields again later).
  final bool skippable;

  /// The step's UI, owned entirely by the contributing SDK — including its
  /// own translations/copy. auth_sdk renders it and never inspects it.
  final Widget content;

  /// Free-form contributor metadata carried alongside the step (an id, an
  /// analytics tag, anything). Opaque to auth_sdk; readable from the step
  /// itself via [RegistrationStepScope.of(context).data].
  final Map<String, dynamic> data;

  const RegistrationStep({
    required this.content,
    this.visible = true,
    this.skippable = true,
    this.data = const {},
  });
}

/// The flow controls and registration state handed down to a contributed
/// step's [RegistrationStep.content].
///
/// An InheritedWidget rather than a constructor argument so [content] stays
/// a plain `Widget` the contributor can build however it likes — the step
/// asks for the controls only if it needs them (mirrors
/// `OnboardingSlideScope`).
class RegistrationStepScope extends InheritedWidget {
  /// Advance to the next visible step, or finish the pipeline (landing on
  /// the app's normal post-registration destination) when this was the last.
  final VoidCallback next;

  /// This step's [RegistrationStep.data].
  final Map<String, dynamic> data;

  /// Zero-based position among the *visible* steps, and how many there are —
  /// for a step that wants to render its own "step 2 of 3".
  final int index;
  final int total;

  /// The freshly registered account, when the register flow had one to hand
  /// over (online registration returns the created user; offline/phone paths
  /// may not). Steps needing more than this should read the profile through
  /// their own providers — the auth token is already stored by the time any
  /// step renders.
  final ProfileData? account;

  const RegistrationStepScope({
    super.key,
    required this.next,
    required this.data,
    required this.index,
    required this.total,
    required this.account,
    required super.child,
  });

  static RegistrationStepScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RegistrationStepScope>();
    assert(scope != null,
        'RegistrationStepScope.of() called outside a registration step');
    return scope!;
  }

  /// Null-safe lookup for widgets that may render outside the pipeline too
  /// (e.g. a capture widget shared with onboarding or the profile page).
  static RegistrationStepScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RegistrationStepScope>();

  @override
  bool updateShouldNotify(RegistrationStepScope oldWidget) =>
      index != oldWidget.index ||
      total != oldWidget.total ||
      !identical(data, oldWidget.data) ||
      !identical(account, oldWidget.account);
}
