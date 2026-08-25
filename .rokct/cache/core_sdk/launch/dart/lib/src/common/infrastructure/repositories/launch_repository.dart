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


// compliance-ignore-file: obs-flutter-trace
// False positive: this repository makes no outgoing HTTP calls — it wraps the
// installed_apps platform channel (local device app list/launch). Flagged
// solely because its path contains 'repositories'; there is no network
// request to stamp with a trace id.

import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:launch_sdk/src/common/domain/interface/launch_service.dart';

class LaunchRepository implements ILaunchService {
  @override
  Future<List<AppInfo>> getInstalledApps({
    bool excludeSystemApps = false,
    bool excludeNonLaunchableApps = true,
    bool withIcon = false,
  }) async {
    return await InstalledApps.getInstalledApps(
      excludeSystemApps: excludeSystemApps,
      excludeNonLaunchableApps: excludeNonLaunchableApps,
      withIcon: withIcon,
    );
  }

  @override
  Future<void> startApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }

  @override
  Future<void> openAppSettings(String packageName) async {
    InstalledApps.openSettings(packageName);
  }
}
