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

// The standard list language's PLANE SHAPE (approved design strip
// section 38, Ray 2026-08-30 12:23Z).
//
// Every list screen in the manager app now wears the same plane
// behaviour, drawn on frames 38a/38b/38c/38d:
//
//   * the LIST DECLARES 2 planes — enough for two plane-aligned columns
//     of cards or rows; at a two-plane fold (38c) it fills the screen
//     exactly, and at three planes the leftover plane TRAILS BARE at the
//     end (38b, Ray 10:47Z) rather than the list stretching;
//   * a tapped row's DETAIL is a pushed page with the DEFAULT one-plane
//     claim, so it lands in the LAST plane (38a's "sheet fork", Ray
//     12:02Z — at plane widths the shipped bottom sheet becomes a PANE);
//   * because a pushed page holds a plane, the nav folds to the corner
//     BACK PILL at the bottom-END (chip 347, the 12:36Z two-state nav
//     rule); Back pops the detail pane and the list re-spreads;
//   * on a one-plane (phone) screen the mechanism disappears by
//     construction (38d) — the list is the whole screen and details open
//     as the shipped bottom sheet.

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Hosts a list screen and its optional pushed detail pane in the plane
/// model, per section 38.
///
/// [detailBuilder] null means "no detail is open" — the list holds its
/// declared planes alone and no back pill is drawn (the flow is at its
/// root). Supplying one pushes the pane into the LAST plane.
class ListPlaneFlow extends StatelessWidget {
  /// The list itself (the flow's root).
  final WidgetBuilder listBuilder;

  /// The pushed detail pane, or null while nothing is open.
  final WidgetBuilder? detailBuilder;

  /// Stable identity of the open detail, so the pane keeps its state
  /// while the allocation re-flows and is rebuilt when a DIFFERENT row
  /// is tapped.
  final String? detailName;

  /// Pops the detail pane — wired to the corner back pill.
  final VoidCallback onCloseDetail;

  /// The list's own claim. Section 38 lists declare TWO.
  final PlaneSpan listSpan;

  /// Back-pill glyph; the caller passes its own icon pack's arrow.
  final IconData backIcon;

  const ListPlaneFlow({
    super.key,
    required this.listBuilder,
    required this.onCloseDetail,
    required this.backIcon,
    this.detailBuilder,
    this.detailName,
    this.listSpan = PlaneSpan.two,
  });

  @override
  Widget build(BuildContext context) {
    return PlaneHost(
      back: FloatingNavBack(
        icon: backIcon,
        label: AppHelpers.getTranslation(TrKeys.back),
        onTap: onCloseDetail,
      ),
      stack: [
        PlanePage(
          name: 'list',
          span: listSpan,
          builder: listBuilder,
        ),
        if (detailBuilder != null)
          PlanePage(
            // Default claim — exactly one plane, the LAST one.
            name: 'list-detail-${detailName ?? ''}',
            builder: detailBuilder!,
          ),
      ],
    );
  }
}

/// The list body's PLANE-ALIGNED COLUMNS (38a "the cards flow in two
/// plane-aligned columns", 38b "two plane-aligned row columns").
///
/// A list granted more than one plane does not stretch its rows to the
/// full width — more space means MORE DETAIL, never a stretched phone
/// layout. Instead it lays its children out in exactly [Planes.span]
/// columns that sit on the plane grid, dealing them round-robin so
/// reading order runs across the row. On one plane it degrades to a
/// single column, which is the phone list (38d).
class ListPlaneColumns extends StatelessWidget {
  final List<Widget> children;

  /// Optional foot (the View-more button) spanning the full width under
  /// the columns.
  final Widget? footer;

  const ListPlaneColumns({super.key, required this.children, this.footer});

  /// How many columns this subtree gets: its granted plane span, or one
  /// when there is no [PlaneHost] above (an ordinary phone route).
  static int columnsOf(BuildContext context) =>
      Planes.maybeOf(context)?.span ?? 1;

  @override
  Widget build(BuildContext context) {
    final planes = Planes.maybeOf(context);
    final int columns = planes?.span ?? 1;
    final double gap = planes?.gap ?? 14;
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...children, if (footer != null) footer!],
      );
    }
    final buckets = List.generate(columns, (_) => <Widget>[]);
    for (var i = 0; i < children.length; i++) {
      buckets[i % columns].add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: buckets[c],
                ),
              ),
            ],
          ],
        ),
        if (footer != null) footer!,
      ],
    );
  }
}

/// The stateful half of the section-38 plane shape: holds WHICH row's
/// detail is open and renders it through [ListPlaneFlow].
///
/// [T] is whatever the list needs to build its detail — an order, a
/// notification, a record. Section 38's three lists differ only in that
/// payload, so the flow itself is shared.
class ListDetailFlow<T extends Object> extends StatefulWidget {
  /// The list (the flow's root, claiming [listSpan] planes).
  final Widget Function(BuildContext context, ListDetailFlowState<T> flow)
  listBuilder;

  /// The pushed detail pane for the open row (default claim: one plane,
  /// so it lands in the LAST plane).
  final Widget Function(
    BuildContext context,
    T open,
    ListDetailFlowState<T> flow,
  )
  detailBuilder;

  /// Stable identity of a row, so the pane keeps its state while the
  /// allocation re-flows and is rebuilt when a different row is tapped.
  final String Function(T open) detailNameOf;

  /// Back-pill glyph; the caller passes its own icon pack's arrow.
  final IconData backIcon;

  /// Section 38 lists declare TWO planes.
  final PlaneSpan listSpan;

  const ListDetailFlow({
    super.key,
    required this.listBuilder,
    required this.detailBuilder,
    required this.detailNameOf,
    required this.backIcon,
    this.listSpan = PlaneSpan.two,
  });

  @override
  State<ListDetailFlow<T>> createState() => ListDetailFlowState<T>();
}

class ListDetailFlowState<T extends Object> extends State<ListDetailFlow<T>> {
  T? _open;

  /// The row whose detail holds the last plane, if any.
  T? get open => _open;

  void openDetail(T value) => setState(() => _open = value);

  void closeDetail() {
    if (_open == null) return;
    setState(() => _open = null);
  }

  @override
  Widget build(BuildContext context) {
    final T? open = _open;
    return ListPlaneFlow(
      backIcon: widget.backIcon,
      listSpan: widget.listSpan,
      onCloseDetail: closeDetail,
      listBuilder: (context) => widget.listBuilder(context, this),
      detailName: open == null ? null : widget.detailNameOf(open),
      detailBuilder: open == null
          ? null
          : (context) => widget.detailBuilder(context, open, this),
    );
  }
}
