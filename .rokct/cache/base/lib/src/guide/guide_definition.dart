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

/// One coach-mark step: points at a [GuideAnchor] on screen and says what it
/// is for. Steps are shown once; see GuideProgress.
class GuideStep {
  /// Stable identity. Completed-step bookkeeping is keyed on this, so never
  /// reuse an id for a different step.
  final String id;

  /// The anchor id the step points at (the `id` of a GuideAnchor).
  final String anchor;

  final String title;
  final String body;

  const GuideStep({
    required this.id,
    required this.anchor,
    required this.title,
    required this.body,
  });
}

/// An ordered guide. Steps whose anchor is not on screen are skipped for
/// that visit; they are not marked complete, so they still show when the
/// screen they belong to is reached.
class GuideDefinition {
  /// Stable identity of the guide. Its progress is stored under this id.
  final String id;

  final List<GuideStep> steps;

  const GuideDefinition({required this.id, required this.steps});
}
