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

import 'dart:async';

import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:remixicon/remixicon.dart';

/// Bell icon with the unread notification count (api.notification
/// .get_notification_count). Tapping it awaits [onOpen] (the host pushes the
/// inbox by route path) and then refreshes the count.
///
/// Default chosen: the badge shows the number up to 99 and "99+" above it,
/// and is hidden at zero. A failed count read leaves the last value and does
/// not show an error, so the bell never blocks the screen it sits on.
class NotificationBell extends StatefulWidget {
  final Future<void> Function() onOpen;

  const NotificationBell({super.key, required this.onOpen});

  /// Badge text: the count up to 99, then "99+".
  static String badgeLabel(int unread) => unread > 99 ? '99+' : '$unread';

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<NotificationRepositoryFacade>()) return;
    final result = await getIt<NotificationRepositoryFacade>().getCount();
    if (!mounted) return;
    result.when(
      success: (data) => setState(() => _unread = data.notification ?? 0),
      failure: (_, __) {},
    );
  }

  Future<void> _open() async {
    await widget.onOpen();
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final label = NotificationBell.badgeLabel(_unread);
    return Badge(
      isLabelVisible: _unread > 0,
      label: Text(label),
      child: IconButton(
        tooltip: AppHelpers.getTranslation(TrKeys.notifications),
        onPressed: () => unawaited(_open()),
        icon: Icon(
          Remix.notification_3_line,
          color: AppStyle.inkFor(brightness),
        ),
      ),
    );
  }
}
