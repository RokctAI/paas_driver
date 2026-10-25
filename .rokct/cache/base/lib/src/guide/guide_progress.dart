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

import 'guide_definition.dart';

/// The persisted state of one guide. Pure data and pure transitions: no
/// storage, no widgets, so the rules below are unit-testable on their own.
///
/// Rules:
///  * On by default; a fresh record is enabled with nothing completed.
///  * A step is shown at most once. Completing or skipping it adds its id to
///    [completed], and a completed step is never shown again.
///  * Turning the guide OFF keeps [completed] and only clears [enabled].
///  * Turning it back ON resumes from [completed] when the guide is not yet
///    finished. When it IS finished, turning it ON starts a clean record, as
///    if the guide had never been used.
class GuideProgress {
  /// Whether the guide is switched on. Off keeps progress; see [setEnabled].
  final bool enabled;

  /// Ids of the steps already shown and dismissed.
  final Set<String> completed;

  const GuideProgress({this.enabled = true, this.completed = const {}});

  /// The state of a guide the person has never touched.
  const GuideProgress.fresh() : this();

  /// True once every step of [definition] has been completed or skipped.
  bool isFinished(GuideDefinition definition) =>
      definition.steps.every((s) => completed.contains(s.id));

  /// Marks one step as seen. Returns this record unchanged when the id is
  /// already completed.
  GuideProgress markComplete(String stepId) => completed.contains(stepId)
      ? this
      : GuideProgress(enabled: enabled, completed: {...completed, stepId});

  /// Skips the rest of the guide: every step counts as seen.
  GuideProgress dismissAll(GuideDefinition definition) => GuideProgress(
        enabled: enabled,
        completed: {...completed, for (final s in definition.steps) s.id},
      );

  /// Switches the guide on or off.
  ///
  /// Switching ON a finished guide starts it over from a fresh record. A
  /// guide that is not finished keeps its completed steps and resumes.
  /// Switching OFF keeps the record intact.
  GuideProgress setEnabled(bool on, GuideDefinition definition) {
    if (on && isFinished(definition)) return const GuideProgress.fresh();
    return GuideProgress(enabled: on, completed: completed);
  }

  /// The step to show next, or null when the guide is off or nothing is left.
  ///
  /// [isOnScreen] says whether an anchor is currently laid out. Steps whose
  /// anchor is not on screen are passed over WITHOUT being marked complete,
  /// so they are still shown when their screen is reached.
  GuideStep? nextStep(
    GuideDefinition definition, {
    bool Function(String anchor)? isOnScreen,
  }) {
    if (!enabled) return null;
    for (final step in definition.steps) {
      if (completed.contains(step.id)) continue;
      if (isOnScreen != null && !isOnScreen(step.anchor)) continue;
      return step;
    }
    return null;
  }

  /// Storage shape. Versioned so a future change can be read safely.
  Map<String, dynamic> toJson() => {
        'version': 1,
        'enabled': enabled,
        'completed': completed.toList(),
      };

  /// Null for anything that is not a record this class wrote. A corrupt or
  /// foreign blob starts the guide fresh instead of throwing.
  static GuideProgress? fromJson(Object? json) {
    if (json is! Map) return null;
    if (json['version'] != 1) return null;
    final enabled = json['enabled'];
    final completed = json['completed'];
    if (enabled is! bool) return null;
    return GuideProgress(
      enabled: enabled,
      completed: completed is List
          ? completed.map((e) => e.toString()).toSet()
          : const {},
    );
  }
}
