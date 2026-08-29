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
import '../../../constants/app_constants.dart';
import '../../adaptive/breakpoints.dart';
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
///    When the page passes [FloatingNavTabsMode.back], the pill grows a
///    leading back segment — PopButton's chevron + label + brand dash
///    inside the pill housing, hairline-split from the tabs — which
///    becomes the screen's ONE back affordance (see [FloatingNavBack]:
///    such a page renders no PopButton or AppBar back of its own).
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
    // TABLET-MODE PLACEMENT — tabs mode only. In a tablet-mode window
    // (>= 600 logical px) the tab bar sits where the page, else the app,
    // says: the page's tabletPlacement wins, the composed
    // AppConstants.tabletNavPlacement is the app-wide answer, and the
    // kernel default is bottomCenter — which falls through to the
    // untouched layout below, so a fleet that opts into nothing renders
    // exactly as before. Compact windows never reach this branch, and a
    // controls bar (session/call) never consults placement: controls
    // stay where the thumbs are regardless of window size.
    if (mode is FloatingNavTabsMode &&
        windowSizeOf(context).isAtLeastMedium) {
      final placement =
          mode.tabletPlacement ?? AppConstants.tabletNavPlacement;
      switch (placement) {
        case FloatingNavPlacement.bottomCenter:
          // Today's layout, below, unchanged.
          break;
        case FloatingNavPlacement.hidden:
          // Renders nothing and intercepts nothing — a shrunk box has no
          // hit area, so taps land on whatever the page put there.
          return const SizedBox.shrink();
        case FloatingNavPlacement.railStart:
        case FloatingNavPlacement.railEnd:
          return _tabsRail(mode, placement);
      }
    }
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
          // The leading back segment — PopButton's chevron + label + brand
          // dash moved inside the pill, split from the tabs by a hairline.
          // Rendered only when the page passes [FloatingNavTabsMode.back]
          // (i.e. when it can pop); the page then draws no back button of
          // its own. The bar's one navigation exception — it never carries
          // the active indicator (see FloatingNavBack).
          if (mode.back != null) ...[
            _BackSegment(back: mode.back!),
            // The hairline splits back from the tabs. A back-only pill —
            // empty tabs, no trailing actions: the no-tab-set apps'
            // pushed routes — has nothing to split from, so it draws none.
            if (mode.tabs.isNotEmpty || mode.trailing.isNotEmpty)
              Container(
                width: 1,
                height: 26.r,
                margin: EdgeInsets.symmetric(horizontal: 4.r),
                color: AppStyle.white.withValues(alpha: 0.16),
              ),
          ],
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

  /// Mode 1 in a tablet-mode window that opted into a side rail: the SAME
  /// [BottomNavigatorItem]s (same taps, same scroll-collapse signal, same
  /// indicator choice) in a Column instead of a Row, inside the same
  /// frosted [_Housing] pill turned on its side — so the rail reads as
  /// the bottom bar having moved, not as a different component.
  ///
  /// SELF-ALIGNING BY DESIGN. Existing host sites wrap this widget in
  /// `Align(alignment: Alignment.bottomCenter)` inside a full-size Stack.
  /// That outer Align hands its child LOOSE constraints at the full
  /// available size, so the [Align] returned here — with null width/height
  /// factors — expands to fill them and then places the rail on its own
  /// start/end edge, vertically centered. The outer bottomCenter has
  /// nothing left to position (the child fills the area), so a host does
  /// not need rewriting to opt in — it only needs to give the widget
  /// room (a full-size Stack slot such as `Positioned.fill`, or the
  /// existing full-size Align). [AlignmentDirectional] keeps the rail
  /// RTL-aware: railStart hugs the right edge in a right-to-left app.
  ///
  /// SafeArea keeps the rail off notches and system edges. The keyboard
  /// is deliberately ignored: a vertically-centered rail does not sit in
  /// the keyboard's way, and viewInsets would only make it jump.
  /// The vertical Flexible+FittedBox mirrors [_Housing.fitted]'s
  /// horizontal guard: on a window that is tablet-mode wide but short
  /// (a landscape phone), the rail scales down instead of overflowing.
  Widget _tabsRail(FloatingNavTabsMode mode, FloatingNavPlacement placement) {
    final isScrolling = ref.watch(floatingProvider).isScrolling;
    final rail = _Housing(
      radius: 100.r,
      fitted: false,
      width: 60.r,
      padding: EdgeInsets.symmetric(vertical: 10.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // The same back segment leading the rail, stacked the way the
          // rail's tabs are — chevron over label over the brand dash —
          // with the hairline turned horizontal beneath it.
          if (mode.back != null) ...[
            _BackSegment(back: mode.back!, vertical: true),
            // Same rule as the bottom pill: a back-only rail draws no
            // hairline — there are no tabs to split from.
            if (mode.tabs.isNotEmpty || mode.trailing.isNotEmpty)
              Container(
                height: 1,
                width: 26.r,
                margin: EdgeInsets.symmetric(vertical: 4.r),
                color: AppStyle.white.withValues(alpha: 0.16),
              ),
          ],
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
          // Same rule as the bottom pill: these invoke a mode rather than
          // moving the viewer, so they never carry the active indicator.
          for (final action in mode.trailing)
            _NavActionButton(
              action: action,
              compact: true,
              margin: EdgeInsets.only(top: 8.r),
            ),
        ],
      ),
    );
    return Align(
      alignment: placement == FloatingNavPlacement.railStart
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: 18.w, end: 18.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(fit: BoxFit.scaleDown, child: rail),
              ),
            ],
          ),
        ),
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

/// The pill's leading back segment ([FloatingNavTabsMode.back]).
///
/// `PopButton`'s exact visual DNA — the chevron, the 12sp white label,
/// the 4x24 brand-primary dash rounded on top — relocated INTO the pill
/// housing, on the same 45.h row rhythm as [BottomNavigatorItem] so the
/// pill keeps one height. [vertical] is the tablet-mode side rail's
/// stacking: the same three elements in a column on the rail's own
/// 45.h x 60.w item footprint, chevron over label over dash, matching how
/// the rail's active tab already stacks.
///
/// Tapping runs [FloatingNavBack.onTap], else `Navigator.maybePop`. A
/// page that passes back draws no other back affordance (no floating
/// `PopButton`, no AppBar leading), so one back exists per screen.
class _BackSegment extends StatelessWidget {
  final FloatingNavBack back;

  /// The tablet-mode side rail's stacking. False — the bottom pill — is
  /// the row layout the design frames show.
  final bool vertical;

  const _BackSegment({required this.back, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    // The dash is PopButton's: always brand-primary — this segment is not
    // a tab, never carries the active indicator, and the dash here is
    // identity, not selection.
    final dash = Container(
      height: 4.h,
      width: 24.w,
      decoration: BoxDecoration(
        color: AppStyle.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(100.r),
          topRight: Radius.circular(100.r),
        ),
      ),
    );

    final Widget body;
    if (vertical) {
      // The rail: chevron over label over dash, mirroring the rail's
      // active-tab stack (same FittedBox guard against short windows).
      body = SizedBox(
        height: 45.h,
        width: 60.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(back.icon, size: 24.r, color: AppStyle.white),
                    Text(
                      back.label,
                      style: TextStyle(
                        color: AppStyle.white,
                        fontSize: 9.sp,
                        // Same fallback guard as BottomNavigatorItem: the
                        // pill can float with no Material ancestor, and
                        // the debug underline must never apply.
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            dash,
          ],
        ),
      );
    } else {
      // The bottom pill: PopButton's own row — chevron beside the
      // label-over-dash stack.
      body = SizedBox(
        height: 45.h,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(back.icon, size: 20.r, color: AppStyle.white),
            SizedBox(width: 4.w),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  back.label,
                  style: TextStyle(
                    color: AppStyle.white,
                    fontSize: 12.sp,
                    // Same fallback guard as BottomNavigatorItem (the pill
                    // can float with no Material ancestor).
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 3.h),
                dash,
              ],
            ),
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      label: back.label,
      child: GestureDetector(
        onTap: back.onTap ?? () => Navigator.maybePop(context),
        child: Container(
          // Transparent but painted, so the whole segment is tappable.
          // The vertical rail adds no side padding: its 60.w footprint
          // already fills the rail housing, exactly like the tabs.
          color: AppStyle.transparent,
          padding: vertical
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: 10.w),
          child: body,
        ),
      ),
    );
  }
}

/// The back segment alone, in the pill's own housing — for hosts that
/// place the screen's ONE back affordance themselves instead of showing
/// the full floating nav (a `PlaneHost` plane layout parks it at the
/// bottom-START corner per the approved ruling: "back button should
/// always be at a corner"). Deliberately carries NO SafeArea, margin, or
/// alignment — placement belongs to the caller; the pill is only the
/// approved look: the same blurred housing, the same back segment, the
/// same 60-radius row rhythm as the tab pill's back. The
/// one-back-per-screen rule from [FloatingNavBack] applies unchanged.
class FloatingBackPill extends StatelessWidget {
  final FloatingNavBack back;

  const FloatingBackPill({super.key, required this.back});

  @override
  Widget build(BuildContext context) {
    return _Housing(
      radius: 100.r,
      fitted: false,
      height: 60.r,
      padding: EdgeInsets.symmetric(horizontal: 10.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_BackSegment(back: back)],
      ),
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

  /// Set by the tablet-mode side rail — the pill turned on its side keeps
  /// a fixed cross-axis width the way the bottom pill keeps a fixed
  /// [height]. Null everywhere else, exactly as before.
  final double? width;

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
    this.width,
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
        width: width,
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

  /// Overrides [compact]'s default leading-edge gap. The tablet-mode
  /// side rail stacks its controls vertically, so its gap is above the
  /// button, not beside it. Null keeps the row spacing exactly as it was.
  final EdgeInsetsGeometry? margin;

  const _NavActionButton({
    required this.action,
    this.compact = false,
    this.emoji,
    this.onLongPress,
    this.margin,
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
                padding: margin ?? EdgeInsets.only(left: 8.r),
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
