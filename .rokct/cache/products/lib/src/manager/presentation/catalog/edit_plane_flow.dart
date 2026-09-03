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
import 'package:base_sdk/src/presentation/components/floating_nav/floating_nav_mode.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The approved edit plane behaviour (frames 35b/35d, Ray 2026-08-29
/// 15:41Z): tapping Edit pushes the product form as a REAL route — the push
/// itself is the 12:36Z nav-fold moment (the route covers the home shell's
/// centered nav; the corner back pill is the one affordance left) — and
/// **THE FORM DECLARES 2**: the shipped modal's Details | Stocks tabs
/// unfold into two side-by-side panes. The origin catalog keeps plane 1
/// (12:26Z origin rule) as a compressed, scannable rail. So
///
///  * at three planes it is rail | details | stocks — approved 35b;
///  * at two planes the rail yields entirely: details | stocks;
///  * on a phone the form's claim folds to one plane and the panes fold
///    back into the shipped Details/Stocks segmented tabs — approved 35d.
///
/// All of it is one [PlaneHost] doing what the model promises: the form is
/// the ACTIVE step claiming [PlaneSpan.two], the rail an earlier page that
/// keeps whatever remains. The pill pops the route at every width.
///
/// THE ADD MOMENT rides the same flow (35a's "+ New product", chip 618, and
/// decision-transfer item 2 of section 35: "a multi-tab form modal unfolds
/// into side-by-side panes at plane widths (35b) and folds back to tabs on
/// the phone" — the shipped two-tab CreateProductModal is exactly such a
/// modal). At two or more planes "add" pushes this flow with the CREATE
/// bodies in the panes and no product highlighted on the rail; on a phone
/// the shipped bottom sheet stays (the 12:02Z sheet fork: sheet = phone
/// behaviour). The one thing the create form carries that the edit form
/// does not is the shipped ORDER: stocks can only be saved against a
/// product that exists, so the create modal locks its Stocks tab until the
/// details save — [ProductFormSplit.stocksLocked] is that lock, drawn on
/// the pane instead of the tab.
class ProductEditPlaneFlow extends StatelessWidget {
  /// Builds the compressed origin-catalog rail (plane 1 at three planes).
  final WidgetBuilder railBuilder;

  /// Builds the form surface. Read `Planes.of(context).span` inside: 2 means
  /// side-by-side panes, 1 means the segmented-tabs phone layout.
  final WidgetBuilder formBuilder;

  /// Pops the pushed route (the corner back pill).
  final VoidCallback onBack;

  const ProductEditPlaneFlow({
    super.key,
    required this.railBuilder,
    required this.formBuilder,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return PlaneHost(
      back: FloatingNavBack(
        icon: Remix.arrow_left_s_line,
        label: AppHelpers.getTranslation(TrKeys.back),
        onTap: onBack,
      ),
      stack: [
        PlanePage(name: 'catalog-rail', builder: railBuilder),
        PlanePage(
          name: 'product-edit-form',
          span: PlaneSpan.two,
          builder: formBuilder,
        ),
      ],
    );
  }
}

/// The tabs-become-panes fold (decision-transfer item: every 2+ tab form
/// modal fleet-wide): granted TWO planes it lays the sections side by side
/// on the plane grid; granted ONE it renders the shipped segmented tabs
/// (approved 35d), each section keeping its own save exactly like the
/// shipped tabs saved separately.
class ProductFormSplit extends StatefulWidget {
  /// Section titles, shown as the segmented tabs on one plane and as the
  /// pane headers on two.
  final String detailsTitle;
  final String stocksTitle;

  /// Header line above the panes (wide) — e.g. "Edit product — Bunny Chow".
  final Widget? header;

  /// Small trailing header for the stocks pane (e.g. "3 variants").
  final Widget? stocksHeaderTrailing;

  final WidgetBuilder detailsBuilder;
  final WidgetBuilder stocksBuilder;

  /// The create moment's shipped order: the stocks section is inert until
  /// the details save has created the product (the shipped
  /// CreateProductModal wraps its tab bar in an IgnorePointer for exactly
  /// this). On panes the stocks pane dims under [stocksLockedHint] and
  /// ignores pointers; on one plane the Stocks segment cannot be selected.
  /// When the lock lifts on one plane the form hops to Stocks — the
  /// shipped `onSave` tab hop — so the phone fold behaves as the modal did.
  final bool stocksLocked;

  /// The line drawn over the locked stocks pane (e.g. "Save details
  /// first"). Ignored while [stocksLocked] is false.
  final String? stocksLockedHint;

  const ProductFormSplit({
    super.key,
    required this.detailsTitle,
    required this.stocksTitle,
    required this.detailsBuilder,
    required this.stocksBuilder,
    this.header,
    this.stocksHeaderTrailing,
    this.stocksLocked = false,
    this.stocksLockedHint,
  });

  @override
  State<ProductFormSplit> createState() => _ProductFormSplitState();
}

class _ProductFormSplitState extends State<ProductFormSplit> {
  int _tab = 0;

  @override
  void didUpdateWidget(covariant ProductFormSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shipped create modal animated to its Stocks tab the moment the
    // details save succeeded; the lock lifting is that moment here.
    if (oldWidget.stocksLocked && !widget.stocksLocked && _tab == 0) {
      _tab = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final planes = Planes.maybeOf(context);
    final int span = planes?.span ?? 1;
    if (span >= 2) {
      final double gap = planes?.gap ?? 14;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _pane(
                    title: widget.detailsTitle,
                    child: Builder(builder: widget.detailsBuilder),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _pane(
                    title: widget.stocksTitle,
                    trailing: widget.stocksHeaderTrailing,
                    child: _stocksSection(),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // One plane: the shipped two-tab shape, dark (approved 35d).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.header != null) widget.header!,
        _segmentedTabs(),
        const SizedBox(height: 8),
        Expanded(
          child: _tab == 0
              ? Builder(builder: widget.detailsBuilder)
              : _stocksSection(),
        ),
      ],
    );
  }

  /// The stocks body, inert and dimmed under the hint while locked.
  Widget _stocksSection() {
    final Widget body = Builder(builder: widget.stocksBuilder);
    if (!widget.stocksLocked) return body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.stocksLockedHint != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Remix.lock_line,
                  size: 14,
                  color: AppStyle.textDarkSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.stocksLockedHint!,
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: IgnorePointer(
            ignoring: true,
            child: Opacity(opacity: 0.45, child: body),
          ),
        ),
      ],
    );
  }

  Widget _pane({required String title, Widget? trailing, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: AppStyle.interSemi(size: 12, color: AppStyle.textDarkSecondary),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _segmentedTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _segment(0, widget.detailsTitle),
          _segment(1, widget.stocksTitle),
        ],
      ),
    );
  }

  Widget _segment(int index, String title) {
    final bool active = _tab == index;
    // The shipped create modal's IgnorePointer tab bar: Stocks cannot be
    // selected until the product exists.
    final bool locked = index == 1 && widget.stocksLocked;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => setState(() => _tab = index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // The 35d segmented pill: the active segment is the inverse
            // chip — ink-colored fill, surface-colored label.
            color: active ? AppStyle.textPrimary : null,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            title,
            style: active
                ? AppStyle.interSemi(size: 14, color: AppStyle.surfaceDark)
                : AppStyle.interNormal(
                    size: 14,
                    color: locked
                        ? AppStyle.textDarkFaint
                        : AppStyle.textDarkSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}
