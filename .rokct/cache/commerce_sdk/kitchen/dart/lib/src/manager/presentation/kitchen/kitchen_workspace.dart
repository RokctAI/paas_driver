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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_provider.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_detail_pane.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_plane_flow.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_queue_view.dart';

/// The whole manager Kitchen screen body — everything below the shell:
/// fetch-on-mount and the auto-refresh polling lifecycle, hosted in the
/// approved plane behaviour ([KitchenPlaneFlow]). The tab page template
/// mounts exactly this widget.
class KitchenWorkspace extends ConsumerStatefulWidget {
  const KitchenWorkspace({super.key});

  @override
  ConsumerState<KitchenWorkspace> createState() => _KitchenWorkspaceState();
}

class _KitchenWorkspaceState extends ConsumerState<KitchenWorkspace> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(kitchenProvider.notifier);
      notifier.fetchOrders(isRefresh: true);
      notifier.startPolling();
    });
  }

  @override
  void deactivate() {
    ref.read(kitchenProvider.notifier).stopPolling();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(kitchenProvider.select((s) => s.selectedOrder));
    return ColoredBox(
      color: AppStyle.surfaceDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On a ONE-plane (phone) width the detail is a real pushed
          // route (KitchenDetailPage, approved 34c) — the flow hosts the
          // queue alone there, so the selection a pushed route holds
          // never double-mounts a detail plane beneath it.
          final bool onePlane =
              PlaneHost.planeCountFor(constraints.maxWidth) == 1;
          return KitchenPlaneFlow(
            selectedOrder: onePlane ? null : selected,
            queueBuilder: (context) => const KitchenQueueView(),
            detailBuilder: (context, order) => KitchenDetailPane(order: order),
            onCloseDetail: () =>
                ref.read(kitchenProvider.notifier).selectOrder(null),
          );
        },
      ),
    );
  }
}
