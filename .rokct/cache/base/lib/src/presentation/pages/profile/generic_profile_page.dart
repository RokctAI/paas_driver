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


import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/application/profile/profile_host_capabilities.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_host_scope.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_theme_toggle.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Generic profile page host.
///
/// Identity comes from base_sdk's [profileProvider]; the body is composed
/// from whatever sections the installed SDK set registered on
/// [ProfileSectionRegistry] at bootstrap. Nothing here knows about any
/// feature SDK (ADR-005).
///
/// The host owns the page chrome: the top controls row (page title,
/// SDK-registered actions, theme toggle, the one sign-out button on the
/// screen), the unified header card with its SDK-fillable slots and the
/// in-place flip to the plan back face, the logout confirmation, and
/// section ordering.
///
/// The host degrades by what the shell registered
/// ([ProfileHostCapabilities], read off [profileProvider]'s notifier):
///   * every account facade present — the surface described above,
///     unchanged;
///   * no `UserRepositoryFacade` — ANONYMOUS MODE: the brand ground, the
///     top row without its sign-out, the shell's plan slot (alone in the
///     header card, or no card while unclaimed), the registered sections
///     and the footer without its usage badge. No identity header, no
///     avatar, no edit pencil; nothing on screen says why. One
///     [anonymousModeEvent] per process tells admins over telemetry;
///   * only the shops or gallery facade missing — sections and header
///     slots that `requires` it are omitted, nothing else.
@RoutePage()
class GenericProfilePage extends ConsumerStatefulWidget {
  const GenericProfilePage({super.key});

  /// The identity header card — present in account mode only.
  static const Key accountHeaderKey = Key('generic-profile-account-header');

  /// The anonymous surface's plan-only header card — present in anonymous
  /// mode only, and only while the plan slot is claimed.
  static const Key anonymousHeaderKey =
      Key('generic-profile-anonymous-header');

  /// The telemetry event type sent once per process when the host first
  /// mounts in anonymous mode; its context carries `missing_facades`, the
  /// interface names the shell did not register.
  static const String anonymousModeEvent = 'profile_host_anonymous_mode';

  /// Whether this process already sent [anonymousModeEvent].
  static bool _anonymousModeReported = false;

  /// Forgets that [anonymousModeEvent] was sent, so a test can observe the
  /// once-per-process send again.
  @visibleForTesting
  static void resetAnonymousModeReport() {
    _anonymousModeReported = false;
  }

  @override
  ConsumerState<GenericProfilePage> createState() =>
      _GenericProfilePageState();
}

class _GenericProfilePageState extends ConsumerState<GenericProfilePage> {
  /// Resolved async visibility gates, keyed by section id. A gated section
  /// stays hidden until its gate resolves true.
  final Map<String, bool> _gateResults = {};

  /// Resolved header-slot gates, keyed by slot. A gated slot stays empty
  /// until its gate resolves true — the same contract as section gates.
  final Map<ProfileHeaderSlot, bool> _headerSlotGateResults = {};

  /// Whether the header card currently shows its plan back face (the
  /// in-place flip triggered from the plan row while the planBack slot is
  /// claimed).
  bool _showPlanBack = false;

  /// Which account facades the shell registered — fixed for the page's
  /// lifetime, read off the notifier whose constructor resolved them so
  /// the page and the notifier never disagree about what exists.
  late final ProfileHostCapabilities _capabilities;

  @override
  void initState() {
    super.initState();
    _capabilities = ref.read(profileProvider.notifier).capabilities;
    _reportAnonymousModeOnce();
    // Fill any section slot no SDK claimed at bootstrap with base_sdk's
    // default (currently the base.footer meta row). Runs before the
    // gates resolve so a gated override is honoured.
    ProfileSectionRegistry.I.ensureDefaultSections();
    _resolveVisibilityGates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchUser(context);
    });
  }

  /// Tells admins ONCE per process that this composition hosts the profile
  /// anonymously, and which facades are missing — over the error lane
  /// (ADR-006), never on screen: the anonymous surface is the product for
  /// such a shell, not a fault to explain to the person holding it.
  void _reportAnonymousModeOnce() {
    if (_capabilities.hasAccount) return;
    if (GenericProfilePage._anonymousModeReported) return;
    GenericProfilePage._anonymousModeReported = true;
    unawaited(
      TelemetryClient.I.logError(
        type: GenericProfilePage.anonymousModeEvent,
        context: <String, dynamic>{
          'stage': 'profile',
          'missing_facades': _capabilities.missingFacades,
        },
      ),
    );
  }

  Future<void> _resolveVisibilityGates() async {
    for (final section in ProfileSectionRegistry.I.sections) {
      // A section the composition cannot host is omitted before its gate
      // is consulted, so no gate runs against a missing facade.
      if (!_capabilities.satisfies(section.requires)) continue;
      final gate = section.visible;
      if (gate == null) continue;
      var visible = false;
      try {
        visible = await gate();
      } catch (_) {
        visible = false;
      }
      if (!mounted) return;
      setState(() => _gateResults[section.id] = visible);
    }
    for (final slot in ProfileHeaderSlot.values) {
      final content = ProfileSectionRegistry.I.headerSlot(slot);
      if (content == null) continue;
      if (!_capabilities.satisfies(content.requires)) continue;
      final gate = content.visible;
      if (gate == null) continue;
      var visible = false;
      try {
        visible = await gate();
      } catch (_) {
        visible = false;
      }
      if (!mounted) return;
      setState(() => _headerSlotGateResults[slot] = visible);
    }
  }

  bool _isVisible(ProfileSection section) =>
      _capabilities.satisfies(section.requires) &&
      (section.visible == null || (_gateResults[section.id] ?? false));

  /// The widget filling [slot], or null while the slot is unclaimed or its
  /// gate has not resolved true — null keeps the header exactly as it
  /// renders without slots.
  Widget? _headerSlotWidget(BuildContext context, ProfileHeaderSlot slot) {
    final content = ProfileSectionRegistry.I.headerSlot(slot);
    if (content == null) return null;
    if (!_capabilities.satisfies(content.requires)) return null;
    if (content.visible != null &&
        !(_headerSlotGateResults[slot] ?? false)) {
      return null;
    }
    return content.builder(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    // Rebuild when the theme toggle flips the persisted mode, so every
    // AppStyle mode-resolving getter below re-resolves.
    ref.watch(appProvider.select((s) => s.isDarkMode));
    final registry = ProfileSectionRegistry.I;
    final user = state.userData ?? LocalStorage.getUser();
    final sections = registry.sections.where(_isVisible).toList();
    // Only an account host hydrates: without a UserRepositoryFacade
    // nothing ever fetches, so a stored token must not park the page on
    // the loader for good.
    final hydrating = _capabilities.hasAccount &&
        state.isLoading &&
        user == null &&
        LocalStorage.getToken().isNotEmpty;

    final planBack = _headerSlotWidget(context, ProfileHeaderSlot.planBack);

    // The plan row flips only while a planBack face exists; without one
    // any tap handling belongs to the plan content itself.
    final VoidCallback? onPlanTap = planBack == null
        ? null
        : () => setState(() => _showPlanBack = true);

    // The header card's front face. Account mode: the identity header
    // with every slot, exactly as it always rendered. Anonymous mode: no
    // identity to show, so the shell's plan row alone in the same card
    // chrome — and no card at all while the plan slot is unclaimed.
    final Widget? front;
    if (_capabilities.hasAccount) {
      front = _IdentityHeader(
        key: GenericProfilePage.accountHeaderKey,
        user: user,
        badge: _headerSlotWidget(context, ProfileHeaderSlot.badge),
        stats: _headerSlotWidget(context, ProfileHeaderSlot.stats),
        plan: _headerSlotWidget(context, ProfileHeaderSlot.plan),
        corner: _headerSlotWidget(context, ProfileHeaderSlot.corner),
        onEditProfile: registry.onEditProfile,
        onPlanTap: onPlanTap,
      );
    } else {
      final plan = _headerSlotWidget(context, ProfileHeaderSlot.plan);
      front = plan == null
          ? null
          : _AnonymousHeader(
              key: GenericProfilePage.anonymousHeaderKey,
              plan: plan,
              onPlanTap: onPlanTap,
            );
    }

    final Widget? header = front == null
        ? null
        : planBack == null
            ? front
            : _FlipCard(
                showBack: _showPlanBack,
                front: front,
                back: _PlanBackCard(
                  onFlipBack: () => setState(() => _showPlanBack = false),
                  child: planBack,
                ),
              );

    final topRow = _TopRow(
      title:
          registry.pageTitle ?? AppHelpers.getTranslation(TrKeys.profile),
      actions: registry.topRowActions,
      // Sign-out needs an account to sign out of: in anonymous mode the
      // button stays hidden even where the shell registered onLogout.
      onLogout: registry.onLogout == null || !_capabilities.hasAccount
          ? null
          : () => _confirmLogout(registry.onLogout!),
    );

    // Self-spread (the approved plane proposal, frame 1c, capped by the
    // approved 4c ruling: "will just let profile take two plane max ...
    // let all profiles take only 2 planes even if there is 3"): granted
    // planes by a PlaneHost above, the page spreads its own content
    // across AT MOST TWO of them — balanced columns of the registry's
    // ordered sections, the identity header leading the first. The cap
    // is UNIVERSAL and lives here, in the page itself, so EVERY host of
    // GenericProfilePage (customer, merchant, lms, ...) is bound by it —
    // no PlanePage declaration can spread the profile to three. Declare
    // the profile's PlanePage as PlaneSpan.two (never all) so at a
    // three-plane width the third plane follows normal rules — a bare
    // stage or a flow neighbor. Without a PlaneHost (or on a one-plane
    // screen, where a page's grant is always one) the phone layout
    // renders untouched. Subscribing via Planes.of means the page
    // re-flows on any allocation change — no polling.
    final planes = Planes.maybeOf(context);
    final grantedPlanes = math.min(planes?.span ?? 1, 2);

    // The scope hands the resolved capabilities to everything the page
    // builds — sections, slot content, the footer — see ProfileHostScope.
    return ProfileHostScope(
      capabilities: _capabilities,
      child: Scaffold(
        // Mode-resolving page surface: dark surface in dark mode, the soft
        // light-grey page in light mode — same token every themed page
        // uses. In anonymous mode this brand ground is the whole backdrop.
        backgroundColor: AppStyle.surfaceDark,
        body: hydrating
            ? const Loading()
            : SafeArea(
                child: grantedPlanes >= 2
                    ? _SpreadBody(
                        columns: grantedPlanes,
                        // Column gutters on the host's seam width, so the
                        // page's columns sit exactly on the plane grid.
                        columnGap: planes!.gap,
                        topRow: topRow,
                        header: header,
                        sections: sections,
                      )
                    : ListView(
                        padding: EdgeInsets.all(16.r),
                        children: [
                          topRow,
                          12.verticalSpace,
                          if (header != null) ...[
                            header,
                            16.verticalSpace,
                          ],
                          if (sections.isEmpty)
                            const _EmptySections()
                          else
                            ...sections
                                .map((section) => section.builder(context)),
                        ],
                      ),
              ),
      ),
    );
  }

  void _confirmLogout(void Function(BuildContext context) onLogout) {
    AppHelpers.showAlertDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Remix.logout_box_r_line, size: 48.sp, color: AppStyle.textGrey),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.doYouReallyWantToLogout),
            style: AppStyle.interSemi(size: 16.sp),
            textAlign: TextAlign.center,
          ),
          24.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.yes),
            background: AppStyle.primary,
            textColor: AppStyle.white,
            onPressed: () {
              Navigator.of(context).pop();
              onLogout(context);
            },
          ),
          12.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.cancel),
            background: AppStyle.transparent,
            // Mode-resolving ink, NOT the pinned AppStyle.black: this dialog
            // is a plain Material AlertDialog, so in dark mode it sits on the
            // theme's dark dialog surface (#2B2930) — against which #232B2F
            // is 1.00:1. The outlined Cancel button was invisible: no label,
            // no border, on the sign-out confirmation of every dark host.
            borderColor: AppStyle.textPrimary,
            textColor: AppStyle.textPrimary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// The page's plane-spread layout (frame 1c, capped at TWO columns by
/// the approved 4c ruling): the top controls row spans the full grant,
/// then the page's items — the identity header first, then the
/// registry's ordered sections — flow into [columns] (at most 2)
/// balanced columns in reading order. Balance is by item count,
/// contiguous, so the registry order is preserved down each column and
/// across columns; the header always leads the first. One scroll
/// position for the whole page, exactly like the phone list.
class _SpreadBody extends StatelessWidget {
  final int columns;
  final double columnGap;
  final Widget topRow;

  /// The header card, or null when the page has none (anonymous mode with
  /// the plan slot unclaimed) — the sections then lead the first column.
  final Widget? header;
  final List<ProfileSection> sections;

  const _SpreadBody({
    required this.columns,
    required this.columnGap,
    required this.topRow,
    required this.header,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    // Sections space themselves (ProfileSectionCard carries its own
    // bottom margin); only the header needs the phone layout's 16 under
    // it, so it travels with the header as one item.
    final headerCard = header;
    final items = <Widget>[
      if (headerCard != null)
        Column(children: [headerCard, 16.verticalSpace]),
      if (sections.isEmpty)
        const _EmptySections()
      else
        ...sections.map((section) => section.builder(context)),
    ];

    // Contiguous balanced split: every column gets items.length/columns
    // items, the leftmost columns absorbing the remainder.
    final perColumn = <List<Widget>>[];
    final base = items.length ~/ columns;
    final extra = items.length % columns;
    var next = 0;
    for (var c = 0; c < columns; c++) {
      final take = base + (c < extra ? 1 : 0);
      perColumn.add(items.sublist(next, next + take));
      next += take;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          topRow,
          12.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) SizedBox(width: columnGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: perColumn[c],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The unified header card: the identity row plus the registry's optional
/// header slots ([ProfileHeaderSlot]) — [badge] inline next to the name,
/// [stats] under the identity row behind a hairline divider, the crown-led
/// plan row under that, and [corner] pinned bottom-right. The edit pencil
/// is the card's only action; sign-out lives in the host's top row.
class _IdentityHeader extends StatelessWidget {
  final ProfileData? user;
  final Widget? badge;
  final Widget? stats;
  final Widget? plan;
  final Widget? corner;
  final void Function(BuildContext context)? onEditProfile;
  final VoidCallback? onPlanTap;

  const _IdentityHeader({
    super.key,
    required this.user,
    required this.badge,
    required this.stats,
    required this.plan,
    required this.corner,
    required this.onEditProfile,
    required this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();
    final email = user?.email ?? '';
    final contact = email.isNotEmpty ? email : (user?.phone ?? '');
    final role = user?.role ?? '';

    final identityRow = Row(
        children: [
          _Avatar(user: user),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.isEmpty
                            ? AppHelpers.getTranslation(TrKeys.profile)
                            : name,
                        style: AppStyle.interSemi(
                          size: 18.sp,
                          color: AppStyle.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      8.horizontalSpace,
                      badge!,
                    ],
                  ],
                ),
                if (contact.isNotEmpty) ...[
                  4.verticalSpace,
                  Text(
                    contact,
                    style: AppStyle.interNormal(
                      size: 13.sp,
                      color: AppStyle.textDarkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (role.isNotEmpty) ...[
                  2.verticalSpace,
                  Text(
                    role,
                    style: AppStyle.interNormal(
                      size: 12.sp,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEditProfile != null)
            IconButton(
              onPressed: () => onEditProfile!(context),
              icon: Icon(
                Remix.pencil_line,
                size: 20.sp,
                color: AppStyle.textPrimary,
              ),
            ),
        ],
      );

    // The crown-led plan row: the shared plan glyph (Remix vip_crown_line
    // in the app primary) leads whatever content claimed the plan slot,
    // behind the same hairline divider as the stats row. While a planBack
    // face exists, tapping anywhere on the row flips the card in place.
    final planRow =
        plan == null ? null : _planRow(plan: plan!, onPlanTap: onPlanTap);

    final card = Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          identityRow,
          if (stats != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 12.r),
              padding: EdgeInsets.only(top: 12.r),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppStyle.strokeDark,
                    width: 0.5,
                  ),
                ),
              ),
              child: stats!,
            ),
          if (planRow != null) planRow,
        ],
      ),
    );

    if (corner == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          right: 10.r,
          bottom: 10.r,
          child: corner!,
        ),
      ],
    );
  }
}

/// The crown-led plan row — the [ProfileHeaderSlot.plan] seam: the shared
/// plan glyph (Remix vip_crown_line in the app primary) leads whatever
/// content claimed the slot, and while a planBack face exists tapping
/// anywhere on the row flips the card ([onPlanTap]). [divided] draws the
/// same hairline divider as the stats row above it — always inside the
/// identity header, where the row follows the identity or stats row; the
/// anonymous card leads with the row and draws none.
Widget _planRow({
  required Widget plan,
  required VoidCallback? onPlanTap,
  bool divided = true,
}) {
  Widget row = Container(
    width: double.infinity,
    margin: divided ? EdgeInsets.only(top: 12.r) : null,
    padding: divided ? EdgeInsets.only(top: 12.r) : null,
    decoration: divided
        ? BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppStyle.strokeDark,
                width: 0.5,
              ),
            ),
          )
        : null,
    child: Row(
      children: [
        Icon(
          Remix.vip_crown_line,
          size: 16.sp,
          color: AppStyle.primary,
        ),
        8.horizontalSpace,
        Expanded(child: plan),
      ],
    ),
  );
  if (onPlanTap != null) {
    row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPlanTap,
      child: row,
    );
  }
  return row;
}

/// The anonymous surface's header: the shell's plan row alone, in the
/// identity header's card chrome — no avatar, name, contact, edit pencil,
/// badge, stats or corner, because there is no account behind them.
/// Rendered only while the plan slot is claimed; otherwise the anonymous
/// page has no header card and its sections lead.
class _AnonymousHeader extends StatelessWidget {
  final Widget plan;
  final VoidCallback? onPlanTap;

  const _AnonymousHeader({
    super.key,
    required this.plan,
    required this.onPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: _planRow(plan: plan, onPlanTap: onPlanTap, divided: false),
    );
  }
}

/// The host-owned top controls row: page title left, SDK-registered
/// actions, the theme toggle pill, and the screen's single sign-out — an
/// icon-only round red button behind the shared logout confirmation.
class _TopRow extends StatelessWidget {
  final String title;
  final List<ProfileTopRowAction> actions;
  final VoidCallback? onLogout;

  const _TopRow({
    required this.title,
    required this.actions,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppStyle.interSemi(
              size: 18.sp,
              color: AppStyle.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final action in actions) action.builder(context),
        8.horizontalSpace,
        const ProfileThemeToggle(),
        if (onLogout != null) ...[
          12.horizontalSpace,
          _SignOutButton(onTap: onLogout!),
        ],
      ],
    );
  }
}

/// Icon-only round red sign-out button — Remix logout_circle_r_line on the
/// shared red, one per screen, in the top row only.
class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34.r,
        height: 34.r,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppStyle.red,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Remix.logout_circle_r_line,
          size: 18.sp,
          color: AppStyle.white,
        ),
      ),
    );
  }
}

/// In-place Y-axis flip between the header card's front and back faces —
/// no navigation, same slot in the list.
class _FlipCard extends StatelessWidget {
  final bool showBack;
  final Widget front;
  final Widget back;

  const _FlipCard({
    required this.showBack,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: showBack ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        final angle = t * math.pi;
        final pastMidpoint = angle > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: pastMidpoint
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}

/// The header card's back face: the planBack slot's content in the same
/// card chrome, tap anywhere to flip back.
class _PlanBackCard extends StatelessWidget {
  final VoidCallback onFlipBack;
  final Widget child;

  const _PlanBackCard({required this.onFlipBack, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onFlipBack,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            12.verticalSpace,
            Center(
              child: Text(
                AppHelpers.getTranslation(TrKeys.tapAnywhereToFlipBack),
                style: AppStyle.interNormal(
                  size: 10.sp,
                  color: AppStyle.textDarkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ProfileData? user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final img = user?.img ?? '';
    if (img.isNotEmpty) {
      return CustomNetworkImage(
        url: img,
        width: 56.r,
        height: 56.r,
        radius: 28.r,
        profile: true,
      );
    }
    final source =
        '${user?.firstname ?? ''}${user?.lastname ?? ''}${user?.email ?? ''}';
    final initial = source.isEmpty ? '?' : source[0].toUpperCase();
    return Container(
      width: 56.r,
      height: 56.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppStyle.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppStyle.interSemi(size: 22.sp, color: AppStyle.white),
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 64.r),
      child: Column(
        children: [
          Icon(
            Remix.list_settings_line,
            size: 56.sp,
            color: AppStyle.textDarkSecondary,
          ),
          16.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.noData),
            style: AppStyle.interNormal(
              size: 14.sp,
              color: AppStyle.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
