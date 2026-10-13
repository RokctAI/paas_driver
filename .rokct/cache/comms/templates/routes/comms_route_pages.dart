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

// Host-side route shells for comms_sdk (customer app).
//
// auto_route's generator only scans the host package, so the SDK-resident
// chat and notification-settings pages are wrapped in thin @RoutePage
// shells here (the same pattern as marketplace_sdk's
// marketplace_route_pages.dart). The route names are the ones base_sdk's
// AppRoutes seam expects: pushChatRoute -> ChatRoute, pushSettingRoute ->
// SettingRoute.
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:comms_sdk/src/common/presentation/pages/chat/chat/chat_page.dart';
import 'package:comms_sdk/src/common/presentation/pages/setting/setting_page.dart';

/// Chat with a shop or with the platform admin.
@RoutePage(name: 'ChatRoute')
class ChatRouteView extends StatelessWidget {
  final String roleId;
  final String name;

  const ChatRouteView({super.key, required this.roleId, required this.name});

  @override
  Widget build(BuildContext context) => ChatPage(roleId: roleId, name: name);
}

/// Notification settings (Profile > My account > Notifications).
@RoutePage(name: 'SettingRoute')
class SettingRouteView extends StatelessWidget {
  const SettingRouteView({super.key});

  @override
  Widget build(BuildContext context) => const SettingPage();
}
