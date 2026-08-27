// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../application/floating/floating_provider.dart';
import '../../theme/app_style.dart';
import '../blur_wrap.dart';
import 'bottom_navigator_item.dart';
import 'floating_nav_mode.dart';

// FloatingNavTab moved to floating_nav_mode.dart when the pill gained modes;
// re-exported so every existing importer of this file still resolves it.
export 'floating_nav_mode.dart';

/// The composer block's raised fill.
///
/// Deliberately dark in BOTH themes — like the tab pill, which has always
/// been a dark housing with white contents whatever the app theme is — so
/// one set of white icons and text reads correctly either way.
///
/// Near-solid rather than the tab pill's 30% wash: this block has to read
/// as a raised object sitting ON the lesson, and a translucent panel over a
/// dark board disappears into it.
Color get _blockFill => Color.alphaBlend(
      AppStyle.white.withOpacity(0.10),
      AppStyle.bottomNavigationBarColor,
    );

/// A resting control on the block: solid and DARKER than the surface it
/// sits on, the way the reference composer's buttons are.
Color get _controlFill => AppStyle.bottomNavigationBarColor;

/// The app's ONE bottom bar — nav_floating.html's recovered spec wired from
/// its three original pieces (none of them new):
///
///  * [BlurWrap] — the blurred, translucent housing that floats with a
///    margin above the bottom edge, never docked flush (paas_customer
///    main_page.dart composition at c273ab26^);
///  * [BottomNavigatorItem] — icon + label + indicator on the active tab
///    only, other tabs icon-only;
///  * `floatingProvider` — the generic scroll-collapse signal
///    ([BottomNavigatorItem.shouldHide] reads exactly this), moved out of
///    marketplace_sdk.
///
/// Hosts place it in a Stack over the page body and hand it a
/// [FloatingNavMode] saying what it should contain right now:
///
///  * [FloatingNavTabsMode] — the root tab bar. The original behaviour,
///    pixel-for-pixel unchanged, right down to the small dash under the
///    active tab ([FloatingNavTabsMode.indicator] lets a host swap the
///    dash for a filled rounded rectangle; saying nothing keeps the dash).
///  * [FloatingNavControlsMode] — controls. With no
///    [FloatingNavControlsMode.input] it stays a pill of round buttons
///    (the shape telephony's call controls want); with one it becomes the
///    composer block: a rounded rectangle with the text field on its own
///    line and the controls arranged beneath it, modelled on the Claude
///    mobile composer.
///
/// The composer is a COLUMN by design, not a row with a field wedged into
/// it. That is what makes the planned "bar grows upward to ask a question"
/// behaviour an extra row in an existing stack rather than a redesign — and
/// the whole surface is already wrapped in an [AnimatedSize], so growing is
/// a height change that animates rather than a new panel appearing.
class FloatingBottomNav extends ConsumerStatefulWidget {
  final FloatingNavMode mode;

  const FloatingBottomNav({super.key, required this.mode});

  @override
  ConsumerState<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends ConsumerState<FloatingBottomNav> {
  /// Whether the emoji strip is expanded above the bar. Local to the bar
  /// and never persisted: it closes the moment a reaction is sent, and a
  /// bar that isn't on screen has nothing to remember.
  bool _reactionsOpen = false;

  /// The last emoji this student actually sent, which becomes the
  /// reactions button's face. Reacting again is then a single tap on the
  /// thing they already chose, instead of reopening a picker to select the
  /// same emoji every time. Session-scoped by design — it follows the bar,
  /// and a bar that isn't on screen has nothing to remember.
  String? _lastReaction;

  @override
  void didUpdateWidget(covariant FloatingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Leaving controls mode (or losing the reactions) must not leave an
    // orphaned strip floating over the next screen.
    final mode = widget.mode;
    if (_reactionsOpen &&
        (mode is! FloatingNavControlsMode || mode.reactions.isEmpty)) {
      _reactionsOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    // The composer must ride above the keyboard rather than under it.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    // The tab pill is a small centered island; the composer is a full-width
    // block and wants the narrower margin its reference has.
    final side = mode is FloatingNavControlsMode && mode.input != null
        ? 12.w
        : 20.w;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: side,
          right: side,
          bottom: 18.h + keyboard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The emoji strip rides directly above the bar and pushes
            // nothing else around — it only exists while open.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.bottomCenter,
              child: _reactionsOpen &&
                      mode is FloatingNavControlsMode &&
                      // A risen panel owns the moment; the emoji strip must
                      // not float above it.
                      mode.panel == null
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _ReactionStrip(
                        emojis: mode.reactions,
                        enabled: mode.reactionsEnabled,
                        onReact: (emoji) {
                          setState(() {
                            _reactionsOpen = false;
                            _lastReaction = emoji;
                          });
                          mode.onReaction?.call(emoji);
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // The bar is anchored at the bottom, so growing moves only its
            // TOP edge upward — long enough and eased enough to read as the
            // bar rising, not as a panel blinking into place.
            AnimatedSize(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: switch (mode) {
                FloatingNavTabsMode() => _tabsPill(mode),
                FloatingNavControlsMode() => _controlsSurface(mode),
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mode 1 — untouched: the same [BottomNavigatorItem] row the bar has
  /// always drawn, in the same 100-radius pill, including the
  /// scroll-collapse signal and the active-tab indicator (the host's
  /// choice of dash or rectangle; dash unless it says otherwise).
  Widget _tabsPill(FloatingNavTabsMode mode) {
    final isScrolling = ref.watch(floatingProvider).isScrolling;
    return _Housing(
      radius: 100.r,
      fitted: true,
      height: 60.r,
      padding: EdgeInsets.symmetric(horizontal: 10.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < mode.tabs.length; i++)
            BottomNavigatorItem(
              selectItem: () {
                ref.read(floatingProvider.notifier).changeScrolling(false);
                mode.onSelect(i);
              },
              index: i,
              currentIndex: mode.currentIndex,
              isScrolling: isScrolling,
              selectIcon: mode.tabs[i].selectIcon,
              unSelectIcon: mode.tabs[i].unSelectIcon,
              label: mode.tabs[i].label,
              indicator: mode.indicator,
            ),
          // Not destinations: these invoke a mode rather than moving the
          // viewer, so they never carry the active indicator.
          for (final action in mode.trailing)
            _NavActionButton(action: action, compact: true),
        ],
      ),
    );
  }

  /// Modes 2 and 3. Controls never collapse on scroll: unlike tabs they are
  /// the only way to act on what is on screen, and a session bar that hides
  /// itself mid-lesson strands the student.
  Widget _controlsSurface(FloatingNavControlsMode mode) {
    // Once something has been sent, the button wears that emoji and a tap
    // sends it again; a long press reopens the picker to change it. Until
    // then it is the neutral face and a tap opens the picker.
    final repeat = _lastReaction;
    final reactionsButton = mode.reactions.isEmpty
        ? null
        : _NavActionButton(
            compact: mode.input != null,
            emoji: _reactionsOpen ? null : repeat,
            onLongPress: mode.reactionsEnabled && repeat != null
                ? () => setState(() => _reactionsOpen = !_reactionsOpen)
                : null,
            action: FloatingNavAction(
              icon: _reactionsOpen
                  ? Icons.emoji_emotions
                  : Icons.emoji_emotions_outlined,
              label: mode.reactionsLabel,
              active: _reactionsOpen,
              onTap: !mode.reactionsEnabled
                  ? null
                  : (repeat != null && !_reactionsOpen)
                      ? () => mode.onReaction?.call(repeat)
                      : () => setState(() => _reactionsOpen = !_reactionsOpen),
            ),
          );

    // Nothing to type and nothing risen: the bar stays the round pill of
    // round buttons. This is the shape a call bar wants, so telephony gets
    // it by passing no input.
    if (mode.input == null && mode.panel == null) {
      return _Housing(
        radius: 100.r,
        fitted: true,
        height: 60.r,
        padding: EdgeInsets.symmetric(horizontal: 10.r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (reactionsButton != null) reactionsButton,
            for (final action in mode.leadingActions)
              _NavActionButton(action: action),
            for (final action in mode.actions)
              _NavActionButton(action: action),
          ],
        ),
      );
    }

    // The composer block: whatever has risen on top, then the field on its
    // own line, then the controls — reactions at the leading edge, the
    // session toggles at the trailing edge. ONE raised rounded rectangle
    // that gets taller, not a row of separate clumps and not a second card.
    return _ComposerBlock(
      input: mode.input,
      panel: mode.panel,
      leading: reactionsButton,
      leadingActions: mode.leadingActions,
      target: mode.target,
      actions: mode.actions,
    );
  }
}

/// The shared blurred housing the tab pill and the button-only control
/// pill sit in — same blur, same translucent fill, same float above the
/// bottom edge, so a mode change reads as the SAME bar changing what it
/// offers rather than a different widget appearing.
class _Housing extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final double? height;

  /// These modes scale down on desktop-wide windows instead of
  /// overflowing. The composer is not fitted: it stretches to the
  /// available width, which a [FittedBox] cannot give it.
  final bool fitted;

  const _Housing({
    required this.child,
    required this.radius,
    required this.padding,
    required this.fitted,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final surface = BlurWrap(
      radius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: AppStyle.bottomNavigationBarColor.withOpacity(0.3),
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
        height: height,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (!fitted) return surface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: surface)),
      ],
    );
  }
}

/// The composer block — ONE raised rounded rectangle, modelled on the
/// Claude mobile composer: the text sits directly on the block with the
/// controls in a row beneath it. Deliberately not a text field nested in a
/// second bordered pill inside a panel; that reads as faint boxes inside
/// boxes rather than as one raised object.
///
/// Disabled is shown, never hidden: the text stays put, dimmed and
/// padlocked, and the placeholder is what says so.
class _ComposerBlock extends StatefulWidget {
  final FloatingNavInput? input;
  final Widget? panel;
  final Widget? leading;
  final List<FloatingNavAction> leadingActions;
  final FloatingNavTarget? target;
  final List<FloatingNavAction> actions;

  const _ComposerBlock({
    required this.actions,
    this.leadingActions = const [],
    this.target,
    this.input,
    this.panel,
    this.leading,
  });

  @override
  State<_ComposerBlock> createState() => _ComposerBlockState();
}

class _ComposerBlockState extends State<_ComposerBlock> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _focus.addListener(
      () => widget.input?.onFocusChanged?.call(_focus.hasFocus),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.input?.onSubmit?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    final panel = widget.panel;
    final enabled =
        input != null && input.enabled && input.onSubmit != null;
    // Frosted glass, like the tab pill and like a video call's controls:
    // the board, video or photo behind stays visible through it. That is
    // the whole point of the material, so the fill stays translucent and a
    // heavier blur does the work.
    //
    // The hairline edge is what makes that safe: over a black board a
    // translucent panel has no silhouette at all, and the block stopped
    // reading as raised. The border gives it one on ANY background, so the
    // frost never costs legibility.
    return BlurWrap(
      radius: BorderRadius.circular(26.r),
      blur: 22,
      child: Container(
        decoration: BoxDecoration(
          color: _blockFill.withOpacity(0.55),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: AppStyle.white.withOpacity(0.10)),
        ),
        padding: EdgeInsets.fromLTRB(16.r, 14.r, 16.r, 12.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // What the bar has grown to show occupies the top of the SAME
            // block. There is no second card behind: the block itself gets
            // taller and the composer below simply rides up with it, so the
            // frosted material and its single edge are never duplicated.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: panel == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: panel,
                    ),
            ),
            // Visible but out of play while something has risen: the
            // composer and controls stay exactly where they were, so the
            // surface reads as one object that grew, faded back hard
            // because the risen content owns the moment.
            IgnorePointer(
              ignoring: panel != null,
              child: Opacity(
                opacity: panel != null ? 0.26 : 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (input != null && !input.enabled)
                          Padding(
                            padding: EdgeInsets.only(right: 8.r),
                            child: Icon(
                              Icons.lock_outline,
                              size: 17.r,
                              color: AppStyle.white.withOpacity(0.42),
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            enabled: enabled,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submit(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppStyle.white,
                            ),
                            cursorColor: AppStyle.primary,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: input?.placeholder ?? '',
                              hintStyle: TextStyle(
                                fontSize: 15.sp,
                                color: AppStyle.white.withOpacity(0.45),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        if (widget.leading != null) widget.leading!,
                        if (widget.target != null) ...[
                          SizedBox(width: 8.r),
                          _TargetChip(target: widget.target!),
                        ],
                        for (final action in widget.leadingActions)
                          _NavActionButton(action: action, compact: true),
                        const Spacer(),
                        for (final action in widget.actions)
                          _NavActionButton(action: action, compact: true),
                        // Send joins the control row rather than sitting
                        // inside the text, so the block keeps clean lines.
                        if (enabled && _hasText)
                          _NavActionButton(
                            compact: true,
                            action: FloatingNavAction(
                              icon: Icons.arrow_upward_rounded,
                              label: input.placeholder,
                              active: true,
                              onTap: _submit,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The target chip — a small pill naming what the bar is pointed at.
/// Deliberately a pill among circles: it carries a word rather than a
/// symbol, and it changes what the surface is FOR rather than performing
/// an action.
class _TargetChip extends StatelessWidget {
  final FloatingNavTarget target;

  const _TargetChip({required this.target});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: target.onTap != null,
      label: target.label,
      child: Material(
        color: _controlFill,
        borderRadius: BorderRadius.circular(100.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(100.r),
          onTap: target.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 9.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (target.icon != null) ...[
                  Icon(target.icon, size: 15.r, color: AppStyle.white),
                  SizedBox(width: 5.r),
                ],
                Text(
                  target.label,
                  style: TextStyle(fontSize: 12.sp, color: AppStyle.white),
                ),
                if (target.onTap != null) ...[
                  SizedBox(width: 3.r),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 15.r,
                    color: AppStyle.white.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One round control. [compact] is the composer's tighter spacing — in the
/// button-only pill each control keeps a tab's footprint so the bar holds
/// its rhythm when it swaps modes.
class _NavActionButton extends StatelessWidget {
  final FloatingNavAction action;
  final bool compact;

  /// Renders this emoji in place of [FloatingNavAction.icon] — the
  /// reactions button wearing whatever was last sent.
  final String? emoji;

  final VoidCallback? onLongPress;

  const _NavActionButton({
    required this.action,
    this.compact = false,
    this.emoji,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = action.enabled;
    final Color fill;
    if (action.danger) {
      fill = AppStyle.red;
    } else if (action.active) {
      fill = AppStyle.primary;
    } else {
      // Solid and a step DARKER than the block it sits on, the way the
      // reference composer's buttons are — an outlined translucent circle
      // disappears against a dark surface.
      fill = compact ? _controlFill : AppStyle.white.withOpacity(0.12);
    }

    final button = Material(
      color: fill,
      shape: action.danger || action.active || compact
          ? const CircleBorder()
          : CircleBorder(
              side: BorderSide(color: AppStyle.white.withOpacity(0.22)),
            ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? action.onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: Padding(
          padding: EdgeInsets.all(9.r),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (emoji != null)
                SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: Center(
                    child: Text(emoji!, style: TextStyle(fontSize: 17.sp)),
                  ),
                )
              else
                Icon(
                  action.icon,
                  size: 22.r,
                  color: enabled
                      ? AppStyle.white
                      : AppStyle.white.withOpacity(0.38),
                ),
              // Locked: the control is visibly present and visibly off, so
              // a student can see the feature exists rather than hunt for a
              // button that was removed.
              if (action.locked)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyle.bottomNavigationBarColor,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 10.r,
                      color: AppStyle.white.withOpacity(0.7),
                    ),
                  ),
                ),
              if (action.badgeCount > 0 && !action.locked)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyle.red,
                    ),
                    child: Text(
                      '${action.badgeCount}',
                      style: TextStyle(
                        fontSize: 9.sp,
                        height: 1,
                        color: AppStyle.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      child: Tooltip(
        message: action.label,
        child: compact
            ? Padding(
                padding: EdgeInsets.only(left: 8.r),
                child: button,
              )
            : SizedBox(width: 60.w, child: Center(child: button)),
      ),
    );
  }
}

/// The emoji strip the reactions button opens — its own small pill, same
/// blur and housing as the bar it sits on, sized to its contents.
class _ReactionStrip extends StatelessWidget {
  final List<String> emojis;
  final bool enabled;
  final ValueChanged<String> onReact;

  const _ReactionStrip({
    required this.emojis,
    required this.enabled,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: BlurWrap(
        radius: BorderRadius.circular(100.r),
        child: Container(
          decoration: BoxDecoration(
            color: AppStyle.bottomNavigationBarColor.withOpacity(0.3),
            borderRadius: BorderRadius.all(Radius.circular(100.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 6.r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final emoji in emojis)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? () => onReact(emoji) : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.r,
                      vertical: 4.r,
                    ),
                    child: Opacity(
                      opacity: enabled ? 1 : 0.35,
                      child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
