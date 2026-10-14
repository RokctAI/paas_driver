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
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// One tappable row in a [GlanceCard] — an icon, a line of text, and an
/// optional action. Purely presentational: what the row means (a door
/// countdown, a launcher notification, a task reminder) is entirely up to
/// whichever feature SDK builds the list.
class GlanceCardItem {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  /// Optional avatar (shop logo, tutor portrait, etc.) shown in place of
  /// [icon] for rows that have a real image to show — e.g. an active-order
  /// tracker row. Rows with no avatar fall back to the plain icon, exactly
  /// as before.
  final Widget? avatar;

  /// Row shows a small trailing X when set — for notices that should
  /// persist until the student clears them (a missed session, say) rather
  /// than disappear on their own. Deliberately separate from [onTap] so
  /// tapping the row body and dismissing it are two different actions.
  final VoidCallback? onDismiss;

  /// Optional per-row text style. Absent = the shell's default 13px text,
  /// exactly as before; secondary notice lines (e.g. the active-order
  /// card's weather line) pass a muted style instead.
  final TextStyle? textStyle;

  const GlanceCardItem({
    required this.icon,
    required this.text,
    this.onTap,
    this.avatar,
    this.onDismiss,
    this.textStyle,
  });
}

/// Generic, presentation-only "glance" shell shared by every feature SDK
/// that wants a dismissible-when-quiet summary card at the top of a screen
/// (lms_sdk's session-schedule glance, launch_sdk's home-screen glance,
/// and whatever comes next).
///
/// No business logic lives here (ADR-005: base_sdk is the only cross-SDK-safe
/// dependency) — each consumer decides what counts as "urgent enough to show"
/// and hands this widget the resulting [items]. The shell only owns layout,
/// chrome, and the collapse-to-nothing-when-empty behavior: an empty [items]
/// list renders [SizedBox.shrink], exactly like both prior from-scratch
/// implementations did independently.
class GlanceCard extends StatelessWidget {
  final List<GlanceCardItem> items;

  /// Optional small header label above the item list (the retired core_sdk
  /// widget always showed "Glance"; lms_sdk's version never has one — both
  /// are valid, so this defaults to absent rather than assuming either).
  final String? title;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlanceCard({
    super.key,
    required this.items,
    this.title,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 16,
  });

  /// The row's text style with the current mode's [ink] filled in where the
  /// caller left the colour open. Kept out of [build] so the "caller wins"
  /// rule is stated once.
  static TextStyle _rowStyle(GlanceCardItem item, Color ink) {
    final TextStyle style = item.textStyle ?? const TextStyle(fontSize: 13);
    return style.color == null ? style.copyWith(color: ink) : style;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // The shell's own styling lookup, and deliberately a BuildContext one
    // (Ray, 2026-09-19: "glance doesnt change test immediately untill you
    // come back if you switched theme mode").
    //
    // This card used to resolve nothing from the context: its chrome came
    // from AppStyle's statics and its rows' ink was left to whatever
    // ambient DefaultTextStyle a host happened to provide. Neither is a
    // dependency, so a theme-mode change scheduled no rebuild of this
    // element at all - the card kept the previous mode's styling until
    // something else rebuilt it, i.e. until the page was built again from
    // scratch on the way back into the launcher. Reading the inherited
    // theme here is what fixes that: the element now depends on it, so the
    // mode change itself rebuilds this card wherever it is mounted, and the
    // ink is named from AppStyle's ink seam for the mode the theme reports
    // rather than inherited by accident.
    final Color ink = AppStyle.inkFor(Theme.of(context).brightness);

    final accent = iconColor ?? AppStyle.primary;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyle.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppStyle.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: item.onTap,
                      child: Row(
                        children: [
                          item.avatar ??
                              Icon(item.icon, size: 18, color: accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              // A per-row style that names its own colour
                              // (the active-order card's muted weather
                              // line) keeps it; one that doesn't, and the
                              // default 13px row, take the mode's ink.
                              style: _rowStyle(item, ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.onDismiss != null)
                    InkWell(
                      onTap: item.onDismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Remix.close_line, size: 16, color: accent),
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
