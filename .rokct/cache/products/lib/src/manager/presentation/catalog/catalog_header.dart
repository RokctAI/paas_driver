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

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// One inner tab of the catalog header: its label and live (loaded) count.
class CatalogTab {
  final String label;
  final int count;

  const CatalogTab({required this.label, required this.count});
}

/// The catalog workspace header (approved frame 35a): the page title, the
/// three inner tabs with counts (Foods / Add-ons / Extras), the amber Stock
/// button (doorway to the 35e quick-adjust) and the "+ New product" action.
///
/// The header lays itself out BY THE PLANES IT HOLDS, never by pixels —
/// the same declaration the catalog flow makes ([Planes.of]):
///
///  * ONE-plane screen (phone): title + the two compact round actions, no
///    inner tabs in the header (the shipped phone layout, 35c).
///  * Catalog granted TWO OR MORE planes (the 35a spread at a three-plane
///    width): the approved single row — title, tabs, Stock, New product.
///  * Catalog granted exactly ONE plane on a multi-plane screen (the
///    two-plane fold with the detail open: catalog | detail): the same
///    elements folded onto two rows — title with the compact actions, the
///    tab pill on its own row beneath. Nothing is dropped; the row simply
///    cannot hold ~370 logical px of title + labelled actions inside a
///    ~330-390 px plane, which is where the "OVERFLOWED BY 234 PIXELS"
///    stripes came from on the tablet store stills.
///
/// The tab pill always sits in a horizontal scroll view: wider translations
/// scroll instead of overflowing, on every tier.
class CatalogHeader extends StatelessWidget {
  final String title;
  final List<CatalogTab> tabs;
  final int activeTab;
  final ValueChanged<int> onSelectTab;

  /// How many loaded products need attention (low + out) — the Stock
  /// button's badge; hidden at zero.
  final int attention;
  final VoidCallback onStock;
  final String stockLabel;
  final VoidCallback onNew;

  /// The labelled create action's text (tracks the active inner tab).
  final String newLabel;

  const CatalogHeader({
    super.key,
    required this.title,
    required this.tabs,
    required this.activeTab,
    required this.onSelectTab,
    required this.attention,
    required this.onStock,
    required this.stockLabel,
    required this.onNew,
    required this.newLabel,
  });

  @override
  Widget build(BuildContext context) {
    final planes = Planes.maybeOf(context);
    final int count = planes?.count ?? 1;
    final int span = planes?.span ?? 1;

    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppStyle.interBold(size: 22, color: AppStyle.textPrimary),
    );
    // On the rows without the tab pill the title takes what the actions
    // leave, start-aligned, so a long translation ellipsizes instead of
    // pushing the actions off the plane.
    final titleBlock = Align(
      alignment: AlignmentDirectional.centerStart,
      child: titleText,
    );

    if (count == 1) {
      // Phone: the shipped one-plane header, untouched.
      return Row(
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 8),
          _StockButton(
            attention: attention,
            label: stockLabel,
            compact: true,
            onTap: onStock,
          ),
          const SizedBox(width: 8),
          _NewButton(label: newLabel, compact: true, onTap: onNew),
        ],
      );
    }

    if (span >= 2) {
      // The approved 35a row: the catalog holds two planes or more.
      return Row(
        children: [
          titleText,
          const SizedBox(width: 12),
          Expanded(child: _tabPill()),
          const SizedBox(width: 8),
          _StockButton(
            attention: attention,
            label: stockLabel,
            compact: false,
            onTap: onStock,
          ),
          const SizedBox(width: 8),
          _NewButton(label: newLabel, compact: false, onTap: onNew),
        ],
      );
    }

    // The two-plane fold: one plane of a multi-plane screen. Same elements,
    // two rows.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 8),
            _StockButton(
              attention: attention,
              label: stockLabel,
              compact: true,
              onTap: onStock,
            ),
            const SizedBox(width: 8),
            _NewButton(label: newLabel, compact: true, onTap: onNew),
          ],
        ),
        const SizedBox(height: 10),
        _tabPill(),
      ],
    );
  }

  /// The three inner tabs with live counts in the approved pill dress,
  /// start-aligned, scrolling sideways when the labels outgrow the row.
  Widget _tabPill() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppStyle.strokeDarkSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _Segment(
                  tab: tabs[i],
                  active: i == activeTab,
                  onTap: () => onSelectTab(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final CatalogTab tab;
  final bool active;
  final VoidCallback onTap;

  const _Segment({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppStyle.textPrimary : null,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.label,
              style: active
                  ? AppStyle.interSemi(size: 13, color: AppStyle.surfaceDark)
                  : AppStyle.interNormal(
                      size: 13,
                      color: AppStyle.textDarkSecondary,
                    ),
            ),
            const SizedBox(width: 5),
            Text(
              '${tab.count}',
              style: AppStyle.interSemi(
                size: 12,
                color: active
                    ? AppStyle.surfaceDark.withValues(alpha: 0.7)
                    : AppStyle.textDarkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The amber Stock button — the doorway to the approved 35e quick-adjust.
class _StockButton extends StatelessWidget {
  final int attention;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  const _StockButton({
    required this.attention,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppStyle.rate),
          ),
          child: Icon(Remix.archive_line, size: 18, color: AppStyle.rate),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.rate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.archive_line, size: 15, color: AppStyle.rate),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppStyle.interSemi(size: 13, color: AppStyle.rate),
            ),
            if (attention > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppStyle.rate,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$attention',
                  style: AppStyle.interSemi(
                    size: 11,
                    color: AppStyle.surfaceDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "+ New product" — the create dispatch of the ACTIVE inner tab.
class _NewButton extends StatelessWidget {
  final String label;
  final bool compact;
  final VoidCallback onTap;

  const _NewButton({
    required this.label,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppStyle.primary,
          ),
          child: Icon(Remix.add_line, size: 20, color: AppStyle.textPrimary),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppStyle.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.add_line, size: 16, color: AppStyle.textPrimary),
            const SizedBox(width: 5),
            Text(
              label,
              style:
                  AppStyle.interSemi(size: 13, color: AppStyle.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
