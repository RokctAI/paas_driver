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


import 'package:flutter/widgets.dart';

/// WHAT THE FLOATING PILL IS CURRENTLY SHOWING.
///
/// The pill has one look and one owner (base_sdk), but three jobs:
///
///  1. the root tab bar — [FloatingNavTabsMode], the original and default;
///  2. in-session controls while a lesson plays (reactions / mic / video /
///     chat) — [FloatingNavControlsMode], supplied by lms_sdk;
///  3. call controls once telephony_sdk has screens — the SAME
///     [FloatingNavControlsMode] with a different action list (more,
///     video, speaker, mute, and a red hang-up).
///
/// Case 3 is why this is a mode object rather than a pile of optional
/// parameters: telephony hands over a list of buttons and gets the app's
/// bar, without importing lms_sdk, without a second widget, and without
/// this component learning what a lesson or a call is (ADR-005 — the pill
/// renders what it is given and reports taps back; meaning lives in the
/// feature SDK).
///
/// The mode is PASSED DOWN by whichever page is on screen, exactly like
/// [FloatingNavTabsMode.currentIndex] already is. Deliberately not stored
/// in a provider: a stored mode has to be restored on every exit path
/// (back button, system back, a route replaced out from under the page),
/// and any missed path leaves the tab bar stuck showing mic-and-reactions
/// on the schedule. Passing it down cannot get stuck — the page that isn't
/// on screen isn't drawing a bar.
sealed class FloatingNavMode {
  const FloatingNavMode();
}

/// One tab of the pill in [FloatingNavTabsMode].
class FloatingNavTab {
  final IconData selectIcon;
  final IconData unSelectIcon;
  final String label;

  const FloatingNavTab({
    required this.selectIcon,
    required this.unSelectIcon,
    required this.label,
  });
}

/// Mode 1 — the root tab bar. Unchanged behaviour: icon + label + the
/// filled indicator on the active tab, every other tab icon-only, whole
/// row collapsing while the page scrolls.
class FloatingNavTabsMode extends FloatingNavMode {
  final List<FloatingNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Controls pinned to the trailing edge that are NOT destinations.
  ///
  /// A search button is the motivating case: tapping it should turn the bar
  /// into a search surface, not navigate anywhere. Such a control must
  /// never take the active indicator — the indicator answers "where am I",
  /// and invoking a mode does not move the viewer. Modelling it as a tab
  /// would light the wrong one, which is the exact failure the Add-student
  /// page had to be fixed for.
  ///
  /// The page swaps the mode it passes in response. Nothing is stored here,
  /// so leaving the page cannot strand the bar in the invoked mode.
  final List<FloatingNavAction> trailing;

  const FloatingNavTabsMode({
    required this.tabs,
    required this.currentIndex,
    required this.onSelect,
    this.trailing = const [],
  });
}

/// One pressable control in [FloatingNavControlsMode].
///
/// A control is a plain description — an icon, a translated label, and what
/// to do. The three visual states it can carry are the ones a session or
/// call bar actually needs:
///
///  * [active] — the thing is ON (mic live, camera on, speaker routed).
///    Fills with the brand colour, the same "on" language the rest of the
///    app uses.
///  * [locked] — the control EXISTS but is switched off for this session
///    (chat disabled by the tutor). Shown dimmed with a small padlock
///    rather than hidden, so a student can see the feature is there and
///    off, instead of wondering where it went.
///  * [danger] — the destructive one (hang up). Red fill, and the only
///    control that ever gets it.
class FloatingNavAction {
  final IconData icon;

  /// Already translated by the caller — base_sdk owns no copy.
  /// Used for the accessibility label and the long-press tooltip; the bar
  /// does not print text under the icons (four labelled buttons crowd a
  /// phone-width pill, and unlike tabs these are verbs, not destinations).
  final String label;

  final bool active;
  final bool locked;
  final bool danger;

  /// Small red count bubble (unread chat). 0 hides it.
  final int badgeCount;

  /// Null — or [locked] — renders the control unpressable.
  final VoidCallback? onTap;

  const FloatingNavAction({
    required this.icon,
    required this.label,
    this.active = false,
    this.locked = false,
    this.danger = false,
    this.badgeCount = 0,
    this.onTap,
  });

  bool get enabled => onTap != null && !locked;
}

/// The text field a controls-mode bar can carry, modelled on the Claude
/// mobile composer: a rounded-rectangle input as the bar's primary element,
/// with the round controls arranged around it.
///
/// Disabled is a FIRST-CLASS state, not an absence. When [enabled] is false
/// the field stays exactly where it was, dimmed, with a padlock and a
/// [placeholder] the caller sets to say so ("Chat disabled"). A student can
/// see the feature exists and is switched off for this session, instead of
/// hunting for something that vanished — the same reasoning as
/// [FloatingNavAction.locked], applied to the composer.
class FloatingNavInput {
  /// Already translated by the caller — base_sdk owns no copy. This is the
  /// text that carries the disabled state when [enabled] is false.
  final String placeholder;

  final bool enabled;

  /// Fired on the keyboard's send action, or the send button, with the
  /// trimmed text; the field clears itself afterwards.
  final ValueChanged<String>? onSubmit;

  /// Fired when the field takes or loses focus.
  ///
  /// This is how the conversation opens — there is deliberately NO button
  /// here that launches a separate chat surface. A bar that hands off to a
  /// full-screen panel is just a shortcut to the thing it was supposed to
  /// replace; the composer IS the chat, and its transcript belongs in the
  /// card that rises behind this bar.
  final ValueChanged<bool>? onFocusChanged;

  const FloatingNavInput({
    required this.placeholder,
    this.enabled = true,
    this.onSubmit,
    this.onFocusChanged,
  });
}

/// What the bar is currently pointed AT.
///
/// The reference is the model chip in the Claude composer: a small pill on
/// the control row naming the current target, tapped to change it. The bar
/// renders the chip and reports the tap; the picker belongs to the feature
/// SDK, because only it knows what the choices are.
///
/// This is what lets one bar serve very different jobs without new widgets.
/// A lesson points chat at the assistant or at a tutor who is in the
/// session; a marketplace search points at products or at shops; a
/// productivity bar points at task, todo or project. Every one of them
/// needs the same three things: name what it is pointed at, allow that to
/// be changed, and decide which is the default.
class FloatingNavTarget {
  /// Already translated by the caller — base_sdk owns no copy.
  final String label;

  final IconData? icon;

  /// Opens the caller's own picker. Null renders the chip inert, which is
  /// how a single-choice surface states what it is pointed at without
  /// implying it can be changed.
  final VoidCallback? onTap;

  const FloatingNavTarget({required this.label, this.icon, this.onTap});
}

/// Modes 2 and 3 — the bar as controls rather than destinations.
///
/// This mode describes a SURFACE, not a fixed row, which is what lets one
/// component serve both a call bar and a lesson session bar:
///
///  * actions only ([input] null) — the bar stays the round pill of round
///    buttons, which is exactly the shape telephony's call controls want;
///  * actions + [input] — the bar becomes a rounded rectangle carrying the
///    composer, with the controls arranged around it.
///
/// It is deliberately a variable-height surface rather than a fixed bar, so
/// the planned "the bar grows upward to ask a question" behaviour is a
/// matter of giving this mode more to show — not a redesign. The growth is
/// a slot the feature SDK fills; base_sdk still knows nothing about lessons
/// or calls (ADR-005).
///
/// [reactions] is independent of the actions: when non-empty the bar grows
/// its own reactions button at the head of the row, which opens the emoji
/// strip just above the surface. That keeps the bar uncrowded on a phone,
/// and costs telephony nothing — a call passes no reactions and gets no
/// button.
class FloatingNavControlsMode extends FloatingNavMode {
  /// Controls at the TRAILING edge (right, in a left-to-right layout) —
  /// the session toggles in a lesson, the call controls in telephony.
  final List<FloatingNavAction> actions;

  /// Controls at the LEADING edge (left), where the reference composer
  /// puts its "+".
  ///
  /// A separate list rather than a hard-coded slot: the leading position
  /// used to belong to reactions alone, which meant any other SDK's
  /// primary action — a tasks app's "new task", a marketplace filter —
  /// landed on the right, away from where that pattern puts it. Reactions
  /// still lead when present; these follow.
  final List<FloatingNavAction> leadingActions;

  /// The composer. Null keeps the bar a row of round buttons.
  final FloatingNavInput? input;

  /// What the bar is pointed at, shown as a chip on the control row
  /// between the leading controls and the trailing ones.
  final FloatingNavTarget? target;

  /// Emoji offered by the reactions button. Empty = no reactions button.
  final List<String> reactions;

  final ValueChanged<String>? onReaction;

  /// False dims the reactions button and its emoji (rate-limited, or a
  /// quick-check is on screen and owns the student's attention).
  final bool reactionsEnabled;

  /// Translated label for the reactions button (accessibility + tooltip).
  final String reactionsLabel;

  /// Content the bar has GROWN UPWARD to show, above its composer.
  ///
  /// There is no second card. The bar is one surface that gets taller: the
  /// panel takes the top of the same block, the composer and controls ride
  /// up with it, and the whole thing keeps one frosted material and one
  /// edge. Two stacked cards were tried and read as a doubled border in
  /// every state rather than as depth.
  ///
  /// A slot, not a screen: the feature SDK passes its own content in, so
  /// base_sdk hosts a lesson's quick check without knowing what one is, and
  /// nobody has to build a second question UI to put it here (ADR-005).
  ///
  /// While it is set, the composer and controls beneath dim and stop
  /// responding — they stay visible so the surface still reads as one
  /// object that grew, but the panel owns the moment.
  final Widget? panel;

  const FloatingNavControlsMode({
    required this.actions,
    this.leadingActions = const [],
    this.input,
    this.target,
    this.reactions = const [],
    this.onReaction,
    this.reactionsEnabled = true,
    this.reactionsLabel = '',
    this.panel,
  });
}
