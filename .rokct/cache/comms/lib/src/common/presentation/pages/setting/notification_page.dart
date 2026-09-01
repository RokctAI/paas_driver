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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/setting/setting_notifier.dart';
import 'package:base_sdk/src/presentation/components/custom_toggle.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';

import 'package:base_sdk/src/application/setting/setting_provider.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  late SettingNotifier event;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingProvider.notifier).getNotificationList(context);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(settingProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingProvider);
    return state.isLoading
        ? const Loading()
        : Column(
            children: [
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: state.notifications?.length ?? 0,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      CustomToggle(
                        controller: ValueNotifier<bool>(
                          state.notifications?[index].active ?? false,
                        ),
                        title: state.notifications?[index].type ?? "",
                        isChecked: state.notifications?[index].active ?? false,
                        onChange: () {
                          event.updateData(
                            context,
                            index,
                            !(state.notifications?[index].active ?? false),
                          );
                        },
                      ),
                      8.verticalSpace,
                    ],
                  );
                },
              ),
            ],
          );
  }
}
