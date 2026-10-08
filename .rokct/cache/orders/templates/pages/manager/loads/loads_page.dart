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

// THE SHOP'S CONSIGNMENT LOADS — /load.
//
// The list body and the plane flow live in the SDK
// (`orders_sdk/src/manager/presentation/loads/`) so both are widget-tested
// at every width; this installed file is the host shell, which is where
// the router lives:
//
// * TWO PLANES OR MORE — `LoadsPlaneFlow`: the list declares two, a tapped
//   load's detail pushes into the LAST plane, the corner back pill pops
//   the pane and, at the root, this route.
// * ONE PLANE — the list is the whole screen and a tap opens the detail as
//   the bottom sheet, the same degradation the order history takes.
//
// Issuing pushes /load/issue and comes back with the load that was
// created; the shop lands straight on its detail.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/adaptive/adaptive_shell.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/loads/load_detail.dart';
import 'package:orders_sdk/src/manager/presentation/loads/loads_list.dart';
import 'package:orders_sdk/src/manager/presentation/loads/loads_plane_flow.dart';

@RoutePage(name: 'ManagerLoadsRoute')
class LoadsPage extends StatelessWidget {
  const LoadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: const AdaptiveShell(
        compact: _buildCompact,
        medium: _buildExpanded,
        expanded: _buildExpanded,
      ),
    );
  }
}

/// Pushes /load/issue and answers the load it issued, if any.
Future<LoadData?> _pushIssueLoad(BuildContext context) async {
  final result = await context.pushRoute(const ManagerIssueLoadRoute());
  return result is LoadData ? result : null;
}

void _openLoadSheet(BuildContext context, LoadData load) {
  AppHelpers.showCustomModalBottomSheet(
    paddingTop: MediaQuery.paddingOf(context).top + 60,
    context: context,
    radius: 12,
    modal: LoadDetail(load: load),
    isDarkMode: true,
  );
}

/// One plane: the list is the whole screen, the tap opens the sheet, and
/// the ONE back affordance is the corner pill.
Widget _buildCompact(BuildContext context) {
  return Scaffold(
    backgroundColor: AppStyle.surfaceDark,
    body: SafeArea(
      child: Stack(
        children: [
          Builder(
            builder: (context) => LoadsList(
              compact: true,
              onOpenDetail: (load) => _openLoadSheet(context, load),
              onIssueLoad: () async {
                final LoadData? issued = await _pushIssueLoad(context);
                if (issued != null && context.mounted) {
                  _openLoadSheet(context, issued);
                }
              },
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: FloatingBackPill(
              back: FloatingNavBack(
                icon: Remix.arrow_left_wide_fill,
                label: AppHelpers.getTranslation(TrKeys.back),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Two planes or more: the plane-hosted loads workspace.
Widget _buildExpanded(BuildContext context) => const _LoadsPlanes();

class _LoadsPlanes extends StatefulWidget {
  const _LoadsPlanes();

  @override
  State<_LoadsPlanes> createState() => _LoadsPlanesState();
}

class _LoadsPlanesState extends State<_LoadsPlanes> {
  final GlobalKey<LoadsPlaneFlowState> _flowKey =
      GlobalKey<LoadsPlaneFlowState>();

  Future<void> _issue() async {
    final LoadData? issued = await _pushIssueLoad(context);
    if (issued == null || !mounted) return;
    _flowKey.currentState?.openDetail(issued);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceFor(Theme.of(context).brightness),
      body: SafeArea(
        child: LoadsPlaneFlow(
          key: _flowKey,
          backIcon: Remix.arrow_left_wide_fill,
          onIssueLoad: _issue,
          onExit: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}
