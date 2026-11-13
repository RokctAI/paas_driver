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

// "Minimum build, update required" (Ray, 2026-11-09: "minimum version will
// be said by backend"). The backend's guest `api.system.api_status` answer
// may carry, per app, the oldest build it still serves and where to get a
// newer one:
//
//   "min_builds":  {"app.sticks.work": 42, "*": 0}
//   "update_urls": {"app.sticks.work": {"android": "https://…", "windows": "https://…"}}
//
// (an update_urls value may also be one plain URL for every platform). A
// build below its app's minimum stops at the splash with one friendly line
// and an Update button. Everything else fails OPEN: no answer, no entry for
// this app, or a build number the app cannot read never blocks anyone.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:base_sdk/src/constants/app_constants.dart';

/// This build is older than the backend accepts.
@immutable
class UpdateRequired {
  /// The app's key that matched in the backend's lists.
  final String app;

  /// The build that is running.
  final int build;

  /// The oldest build the backend still serves.
  final int minBuild;

  /// Where to get a newer build on this platform, if the backend gave one.
  final String? url;

  const UpdateRequired({required this.app, required this.build, required this.minBuild, this.url});
}

abstract class MinimumBuild {
  MinimumBuild._();

  static Map<String, dynamic>? _latest;

  /// Keeps the latest api_status `data` (AppConnectivity.backendStatus
  /// calls this), so the splash can decide without asking twice. Anything
  /// but a map (no answer) forgets it: an app that cannot reach the backend
  /// is never held back by an old answer.
  static void remember(Object? data) {
    _latest = data is Map ? Map<String, dynamic>.from(data) : null;
  }

  /// Forgets the latest answer. Tests only.
  @visibleForTesting
  static void reset() {
    _latest = null;
    identity = null;
    platform = null;
  }

  /// Which app this is and which build is running. Tests replace it.
  @visibleForTesting
  static Future<({List<String> keys, int? build})> Function()? identity;

  /// The platform name used to pick an update URL. Tests replace it.
  @visibleForTesting
  static String Function()? platform;

  /// Whether the running build is below the backend's minimum, from the
  /// latest api_status answer. Null when it is not, or when that cannot be
  /// told; never throws.
  static Future<UpdateRequired?> check() async {
    final data = _latest;
    if (data == null) return null;
    try {
      final me = await (identity ?? _identity)();
      return decide(data, keys: me.keys, build: me.build, platform: (platform ?? _platform)());
    } catch (e) {
      debugPrint('==> MinimumBuild: could not check: $e');
      return null;
    }
  }

  /// The rule itself, without any platform calls.
  @visibleForTesting
  /// [keys] are the names this app may be listed under, most specific
  /// first; the first one listed wins, then `*` (every app).
  static UpdateRequired? decide(Map<String, dynamic> data, {required List<String> keys, required int? build, required String platform}) {
    if (build == null || build <= 0) return null;
    final mins = data['min_builds'];
    if (mins is! Map) return null;
    final app = keys.firstWhere((k) => k.isNotEmpty && mins.containsKey(k), orElse: () => '*');
    final min = _int(mins[app]);
    if (min == null || build >= min) return null;
    return UpdateRequired(app: app, build: build, minBuild: min, url: _url(data['update_urls'], app, platform));
  }

  static int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'.trim()));

  static String? _url(Object? urls, String app, String platform) {
    if (urls is! Map) return null;
    final v = urls[app] ?? urls['*'];
    final url = v is Map ? v[platform] : v;
    if (url is! String) return null;
    final uri = Uri.tryParse(url.trim());
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') ? uri.toString() : null;
  }

  /// The package name compiled in, the platform's package name (the
  /// Android applicationId, e.g. `app.sticks.work`) and the app's name, so
  /// one entry can cover a shell on every platform.
  static Future<({List<String> keys, int? build})> _identity() async {
    final info = await PackageInfo.fromPlatform();
    return (
      keys: [AppConstants.androidPackageName, info.packageName, info.appName],
      build: int.tryParse(info.buildNumber.trim()),
    );
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'linux';
  }
}
