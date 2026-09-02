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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_workspace.dart';

/// The manager KITCHEN tab (approved design, Ray 2026-08-29: 13:06Z
/// "approved: … 34b,34c,34d", 13:53Z "approved: 34a …"). Installed to
/// lib/presentation/pages/kitchen/kitchen_page.dart — the exact path
/// merchants_sdk's main_page.dart shell imports; tab-hosted, so it
/// declares no route (orders_sdk's OrdersHomePage contract).
///
/// All machinery lives in the analyzable, tested package code
/// (kitchen_sdk src/manager): [KitchenWorkspace] hosts the queue + detail
/// in base_sdk's plane model — the kitchen declares ALL planes, the
/// selected order's detail takes the LAST plane, phones collapse to
/// queue → pushed detail with the corner back pill by construction.
class KitchenHomePage extends StatelessWidget {
  const KitchenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyle.surfaceDark,
        body: const SafeArea(child: KitchenWorkspace()),
      ),
    );
  }
}
