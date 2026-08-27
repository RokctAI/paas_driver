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
