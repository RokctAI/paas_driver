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

// LOADS ON PLANES — the section-38 list shape the order history already
// takes: the list declares TWO planes, a tapped load's detail pushes with
// the default one-plane claim into the LAST plane, and the corner back
// pill pops the pane. /load is itself a pushed route, so at the flow's
// root the same pill stands in for the nav that folded, popping the route.
//
// The detail is a PANE rather than its own route, which is how every
// list in this SDK reaches a detail; there is no per-load path to
// register and no id to round-trip through the router.

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';

import 'load_detail.dart';
import 'loads_list.dart';

/// The plane-hosted loads workspace.
class LoadsPlaneFlow extends StatefulWidget {
  /// Back-pill glyph; the host passes its icon pack's arrow.
  final IconData backIcon;

  /// The header's Issue-load action.
  final VoidCallback onIssueLoad;

  /// Pops the /load route from the flow's root; null draws no root pill.
  final VoidCallback? onExit;

  const LoadsPlaneFlow({
    super.key,
    required this.backIcon,
    required this.onIssueLoad,
    this.onExit,
  });

  @override
  State<LoadsPlaneFlow> createState() => LoadsPlaneFlowState();
}

class LoadsPlaneFlowState extends State<LoadsPlaneFlow> {
  LoadData? _open;

  /// The load whose detail holds the last plane, if any.
  LoadData? get open => _open;

  /// Opens [load]'s detail in the last plane — how the issue screen hands
  /// the shop straight to the load it just issued.
  void openDetail(LoadData load) => setState(() => _open = load);

  void closeDetail() {
    if (_open == null) return;
    setState(() => _open = null);
  }

  @override
  Widget build(BuildContext context) {
    final LoadData? open = _open;
    final Widget flow = ListPlaneFlow(
      backIcon: widget.backIcon,
      onCloseDetail: closeDetail,
      listBuilder: (context) => LoadsList(
        selectedLoadId: open?.id,
        onIssueLoad: widget.onIssueLoad,
        onOpenDetail: openDetail,
      ),
      detailName: open?.id,
      detailBuilder: open == null
          ? null
          : (context) => ColoredBox(
              color: AppStyle.surfaceFor(Theme.of(context).brightness),
              child: LoadDetail(
                key: ValueKey('load-detail-${open.id}'),
                load: open,
              ),
            ),
    );
    final VoidCallback? onExit = widget.onExit;
    // One back per screen: while a detail holds a plane the PlaneHost
    // draws its own pill (popping the pane), so the root pill yields.
    if (onExit == null || open != null) return flow;
    return Stack(
      children: [
        Positioned.fill(child: flow),
        // Parked exactly where PlaneHost parks its pill — bottom-END, 16
        // logical in from both edges, inside the SafeArea — so the two
        // states read as one control.
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: SafeArea(
            child: FloatingBackPill(
              back: FloatingNavBack(
                icon: widget.backIcon,
                label: AppHelpers.getTranslation('back'),
                onTap: onExit,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
