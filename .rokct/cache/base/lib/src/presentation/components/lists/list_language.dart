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

// THE STANDARD LIST LANGUAGE (approved design strip section 38, Ray
// 2026-08-30 12:23Z: "33 list language = STANDARD for all lists").
//
// Section 33's approved list mode (33a/33b — the manager orders board's
// phone shape) is the treatment EVERY list screen in the manager app
// gets. Section 38 renders it on three shipped, undesigned list screens
// (order history, notifications, sync issues) and Ray's approval of
// 38a-38d approves the LANGUAGE, not just those screens.
//
// The language is four elements. They live here, in the shared kernel,
// because their consumers sit in three different feature SDKs across two
// repos and feature SDKs may only import `base_sdk` (ADR-005):
//
//   700  the list-header COUNT PILL — the standard slot on every list
//        ("247 orders", "3 unread", "5 parked")
//   362  the FILTER TAB BAR — colour-coded tabs, each with its count pill
//   363  the ACTIVE TAB treatment — tinted fill + colour border
//   356  VIEW MORE - +N paging at the foot of the list
//
// Section 33's own board keeps its private copies typed on BoardStatus;
// this is the same treatment expressed over a plain, SDK-neutral tab
// model so any list can wear it.

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// One tab of the standard list language's filter row (chip 362).
///
/// [count] renders in the tab's own count pill; a null count draws the
/// tab without one (a filter that has no meaningful total).
@immutable
class ListFilterTab {
  /// Already-translated label.
  final String label;

  /// The tab's colour — its count pill's fill and, when active, its
  /// tinted background and border (chip 363).
  final Color color;

  /// Total behind this tab, shown in the tab's count pill.
  final int? count;

  /// Light tab colours need dark pill text to stay legible (the 33a
  /// rule for Cooking / On-the-way).
  final bool darkPillText;

  const ListFilterTab({
    required this.label,
    required this.color,
    this.count,
    this.darkPillText = false,
  });
}

/// The colour-coded tab row with count pills (chips 362 + 363), scrolling
/// sideways so a long status axis never squeezes.
class ListFilterTabBar extends StatelessWidget {
  final List<ListFilterTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  /// Row height and side padding — the 33b metrics by default.
  final double height;
  final EdgeInsetsGeometry padding;

  const ListFilterTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onSelect,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        padding: padding,
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _ListFilterTabChip(
              tab: tabs[i],
              isActive: i == activeIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _ListFilterTabChip extends StatelessWidget {
  final ListFilterTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _ListFilterTabChip({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            // 363: the active tab is a tinted fill in its own colour with
            // a matching border; the rest sit on the card surface.
            color: isActive
                ? tab.color.withValues(alpha: 0.16)
                : AppStyle.cardDark,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isActive ? tab.color : AppStyle.strokeDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tab.label,
                style: isActive
                    ? AppStyle.interSemi(size: 12, color: AppStyle.textPrimary)
                    : AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.textDarkSecondary,
                      ),
              ),
              if (tab.count != null) ...[
                const SizedBox(width: 7),
                ListTabCountPill(
                  count: tab.count!,
                  color: tab.color,
                  darkText: tab.darkPillText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The solid per-tab count pill inside a [ListFilterTabBar] chip — the
/// board column pill of 33a, carried into the tab row of 33b.
class ListTabCountPill extends StatelessWidget {
  final int count;
  final Color color;
  final bool darkText;

  const ListTabCountPill({
    super.key,
    required this.count,
    required this.color,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: AppStyle.interBold(
          size: 11.5,
          color: darkText ? const Color(0xFF161616) : const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

/// The list-header COUNT PILL (chip 700) — the standard slot on every
/// list screen: an outlined pill beside the title carrying the list's
/// own total in words ("247 orders", "3 unread", "5 parked").
class ListCountPill extends StatelessWidget {
  /// Already-composed label, count included.
  final String label;

  /// Emphasised pill (a needs-attention total) borrows the colour for
  /// its border and text; null keeps the neutral stroke.
  final Color? color;

  const ListCountPill({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color ?? AppStyle.strokeDark),
      ),
      child: Text(
        label,
        style: AppStyle.interNormal(
          size: 11,
          color: color ?? AppStyle.textDarkSecondary,
        ),
      ),
    );
  }
}

/// A header ROUND UTILITY (the 33a bell / date-chip disc), the standard
/// header action shape of the list language: a 38pt circle on the card
/// surface, its border lit when the utility is engaged.
class ListRoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// Lights the border (an engaged filter, per 33a's date chip).
  final bool active;

  /// Accessibility/tooltip label — already translated.
  final String? tooltip;

  const ListRoundAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppStyle.primary : AppStyle.strokeDark,
          ),
        ),
        child: Icon(icon, size: 17, color: AppStyle.textDarkSecondary),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// The standard list HEADER: title, the count pill (700) beside it, and
/// the round utilities at the end (33a's header, generalised).
class ListScreenHeader extends StatelessWidget {
  /// Already-translated screen title.
  final String title;

  /// The count pill (700). Null on a list with no meaningful total.
  final Widget? countPill;

  /// Round utilities and header actions, in order, at the END side.
  final List<Widget> actions;

  /// A quiet line under the title (38c's needs-attention hint, chip 711).
  final String? hint;

  final bool compact;

  const ListScreenHeader({
    super.key,
    required this.title,
    this.countPill,
    this.actions = const [],
    this.hint,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double sidePadding = compact ? 16 : 20;
    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interBold(
                size: compact ? 20 : 23,
                color: AppStyle.textPrimary,
              ),
            ),
          ),
          if (countPill != null) ...[const SizedBox(width: 10), countPill!],
          const Spacer(),
          if (hint != null)
            Flexible(
              child: Text(
                hint!,
                maxLines: 2,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interNormal(
                  size: 11,
                  color: AppStyle.textDarkFaint,
                ),
              ),
            ),
          for (final action in actions) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}

/// VIEW MORE - +N (chip 356): the language's paging foot. Rendered only
/// when [moreCount] is positive; the caller pages its own source.
class ListViewMore extends StatelessWidget {
  final int moreCount;
  final VoidCallback onTap;

  /// Already-translated "View more".
  final String label;

  /// The phone fold (38d) stops the button short of the bottom-END
  /// corner so the back pill owns that corner.
  final EdgeInsetsGeometry margin;

  const ListViewMore({
    super.key,
    required this.moreCount,
    required this.onTap,
    required this.label,
    this.margin = const EdgeInsets.fromLTRB(6, 0, 6, 8),
  });

  @override
  Widget build(BuildContext context) {
    if (moreCount <= 0) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 34,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Center(
          child: Text(
            '$label  ·  +$moreCount',
            style: AppStyle.interSemi(
              size: 11.5,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
