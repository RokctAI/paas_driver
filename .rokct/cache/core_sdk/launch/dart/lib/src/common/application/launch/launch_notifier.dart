// Copyright (c) 2026 RokctAI
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


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:launch_sdk/src/common/domain/interface/launch_service.dart';
import 'launch_state.dart';

class LaunchNotifier extends StateNotifier<LaunchState> {
  final ILaunchService _launchService;

  LaunchNotifier(this._launchService) : super(LaunchState()) {
    loadApps();
  }

  Future<void> loadApps() async {
    state = state.copyWith(isLoading: true);
    try {
      final apps = await _launchService.getInstalledApps();
      final sortedApps = List<AppInfo>.from(apps)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = state.copyWith(
        allApps: sortedApps,
        filteredApps: sortedApps,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      // Surface it rather than rendering an empty list: on a launcher a
      // silent failure is indistinguishable from a phone with no apps.
      debugPrint('==> LaunchNotifier: app enumeration failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void filterApps(String query) {
    state = state.copyWith(query: query);
    final filtered = state.allApps.where((app) {
      return app.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
    state = state.copyWith(filteredApps: filtered);
  }

  Future<void> startApp(String packageName) async {
    await _launchService.startApp(packageName);
  }

  Future<void> openAppSettings(String packageName) async {
    await _launchService.openAppSettings(packageName);
  }
}
