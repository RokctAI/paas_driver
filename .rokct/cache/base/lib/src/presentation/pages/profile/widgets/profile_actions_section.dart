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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/pages/profile/profile_action_item.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// How a [ProfileActionsSection] lays out its group's registered
/// [ProfileActionItem]s. The page-owning SDK picks this per page —
/// contributors never carry layout.
enum ProfileActionLayout {
  /// Square tiles, [ProfileActionsSection.columns] per row (the
  /// marketplace profile's tile-grid look).
  grid,

  /// Full-width settings rows: leading icon, label, chevron (the lms
  /// profile's setting-card look).
  rows,
}

/// Renders one registered action group ([ProfileSectionRegistry.actions])
/// in the layout the page owner picked.
///
/// The SDK that owns a profile page registers an ordinary [ProfileSection]
/// whose builder returns this widget — the host page needs no knowledge of
/// action groups. Contributing SDKs only declare [ProfileActionItem]s into
/// the [group]; this widget owns every layout decision, so a contribution
/// declared for a rows page can never show up grid-shaped (or vice versa).
///
/// Per-item [ProfileActionItem.visible] gates resolve once when this
/// widget mounts, with the same contract as the host's section gates:
/// `false` or a thrown error hides the item. A group with nothing visible
/// renders [SizedBox.shrink].
class ProfileActionsSection extends StatefulWidget {
  /// The page-keyed action group to render (e.g. `'marketplace.customer'`,
  /// `'lms.student'`).
  final String group;

  /// The layout the page owner picked for this page.
  final ProfileActionLayout layout;

  /// Tiles per row in the [ProfileActionLayout.grid] layout. Ignored by
  /// [ProfileActionLayout.rows].
  final int columns;

  const ProfileActionsSection({
    super.key,
    required this.group,
    required this.layout,
    this.columns = 3,
  });

  @override
  State<ProfileActionsSection> createState() => _ProfileActionsSectionState();
}

class _ProfileActionsSectionState extends State<ProfileActionsSection> {
  /// Resolved async visibility gates, keyed by item id. A gated item stays
  /// hidden until its gate resolves true — the section-gate contract.
  final Map<String, bool> _gateResults = {};

  @override
  void initState() {
    super.initState();
    _resolveVisibilityGates();
  }

  Future<void> _resolveVisibilityGates() async {
    for (final item in ProfileSectionRegistry.I.actions(widget.group)) {
      final gate = item.visible;
      if (gate == null) continue;
      var visible = false;
      try {
        visible = await gate();
      } catch (_) {
        visible = false;
      }
      if (!mounted) return;
      setState(() => _gateResults[item.id] = visible);
    }
  }

  bool _isVisible(ProfileActionItem item) =>
      item.visible == null || (_gateResults[item.id] ?? false);

  @override
  Widget build(BuildContext context) {
    final items = ProfileSectionRegistry.I
        .actions(widget.group)
        .where(_isVisible)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    switch (widget.layout) {
      case ProfileActionLayout.grid:
        return _ActionTileGrid(items: items, columns: widget.columns);
      case ProfileActionLayout.rows:
        return Column(
          children: [
            for (final item in items) _ActionRow(item: item),
          ],
        );
    }
  }
}

/// Square-tile grid: [columns] tiles per row, incomplete last row padded
/// with tile-sized spacers so columns stay aligned (the marketplace
/// profile's square-button rows).
class _ActionTileGrid extends StatelessWidget {
  final List<ProfileActionItem> items;
  final int columns;

  const _ActionTileGrid({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    final perRow = columns < 1 ? 1 : columns;
    final rows = <Widget>[];
    for (var start = 0; start < items.length; start += perRow) {
      final end =
          start + perRow > items.length ? items.length : start + perRow;
      final slice = items.sublist(start, end);
      if (rows.isNotEmpty) rows.add(10.verticalSpace);
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in slice) _ActionTile(item: item),
          for (var i = slice.length; i < perRow; i++)
            SizedBox(width: 100.w),
        ],
      ));
    }
    return Column(children: rows);
  }
}

/// One square action tile: rounded card surface, icon (with the optional
/// badge overlaid top-right), centered label — the marketplace
/// `_buildSquareButton` look on base_sdk's mode-resolving card tokens.
class _ActionTile extends StatelessWidget {
  final ProfileActionItem item;

  const _ActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final badge = item.badgeBuilder?.call(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => item.onTap(context),
      child: Container(
        width: 100.w,
        height: 100.w,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppStyle.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 30.r,
                  color: item.accent ?? AppStyle.textPrimary,
                ),
                if (badge != null)
                  Positioned(
                    top: -4.r,
                    right: -8.r,
                    child: badge,
                  ),
              ],
            ),
            8.verticalSpace,
            Text(
              item.label(),
              style: AppStyle.interNormal(
                size: 12.sp,
                color: AppStyle.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// One settings row: leading icon, label, the optional badge, chevron —
/// the lms `LmsSettingCard` look on base_sdk's mode-resolving card
/// tokens.
class _ActionRow extends StatelessWidget {
  final ProfileActionItem item;

  const _ActionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final badge = item.badgeBuilder?.call(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 10.r),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => item.onTap(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 13.r),
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppStyle.strokeDark, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20.sp,
                color: item.accent ?? AppStyle.textPrimary,
              ),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  item.label(),
                  style: AppStyle.interSemi(
                    size: 14.sp,
                    color: AppStyle.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                8.horizontalSpace,
                badge,
              ],
              8.horizontalSpace,
              Icon(
                Remix.arrow_right_s_line,
                size: 20.sp,
                color: AppStyle.textDarkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
