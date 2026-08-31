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

  const ProductFormSplit({
    super.key,
    required this.detailsTitle,
    required this.stocksTitle,
    required this.detailsBuilder,
    required this.stocksBuilder,
    this.header,
    this.stocksHeaderTrailing,
  });

  @override
  State<ProductFormSplit> createState() => _ProductFormSplitState();
}

class _ProductFormSplitState extends State<ProductFormSplit> {
  int _tab = 0;

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
                    child: Builder(builder: widget.stocksBuilder),
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
          child: Builder(
            builder: _tab == 0 ? widget.detailsBuilder : widget.stocksBuilder,
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
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = index),
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
                : AppStyle.interNormal(size: 14, color: AppStyle.textDarkSecondary),
          ),
        ),
      ),
    );
  }
}
