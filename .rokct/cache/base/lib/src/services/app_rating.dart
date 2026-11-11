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
import 'dart:io' show Platform;

import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';
import '../handlers/platform_gateway.dart';
import 'demo_session.dart';
import 'local_storage.dart';

/// The app's own rating screen's memory (Ray, 2026-11-09: apps need a review
/// form that reaches the App Store or Play Store when the app is listed there;
/// "if its not in app store it save the rating locally").
///
/// Neither store lets an app post a custom review, so this works in two steps.
/// [save] keeps every rating on the phone (key [storageKey]) and sends it to
/// the backend (cmd [cmd]) when it can; a rating that could not be sent waits
/// and is sent by the next [flush]. In an app marked listed
/// ([AppConstants.storeListed]) every rating goes on to the store's own review
/// sheet ([openStore]); a rating under [noteBelow] stars also asks for a
/// private note, which stays with us.
class AppRating {
  AppRating._();

  static const storageKey = 'app_rating.v1';
  static const cmd = 'api.app_rating.submit_app_rating';

  /// Below this many stars the sheet also asks for a private note. Every
  /// rating gets the store step in a listed app: showing it only to happy
  /// raters is sentiment gating, which Google Play and Apple discourage.
  static const noteBelow = 4;

  /// Whether the sheet asks for a private note at this rating.
  static bool asksNote(int stars) => stars < noteBelow;

  /// Whether this rating goes on to the store step.
  static bool offersStore({bool? listed}) => listed ?? AppConstants.storeListed;

  static List<Map<String, dynamic>> pending() {
    final raw = LocalStorage.getJson(storageKey)?['items'];
    if (raw is! List) return [];
    return [for (final e in raw) if (e is Map) Map<String, dynamic>.from(e)];
  }

  static Future<void> _write(List<Map<String, dynamic>> items) =>
      LocalStorage.setJson(storageKey, items.isEmpty ? null : {'items': items});

  /// Keeps the rating on the phone, then tries to send everything waiting.
  static Future<void> save(
    int stars, {
    String comment = '',
    bool wentToStore = false,
    PlatformGateway gateway = const PlatformGateway(),
    DateTime? now,
  }) async {
    assert(stars >= 1 && stars <= 5);
    // A demo session or the tour build has no real backend: nothing is kept.
    if (DemoSession.demoActive) return;
    final at = (now ?? DateTime.now()).toUtc();
    final items = pending()
      ..add({
        'client_id': '${at.microsecondsSinceEpoch}',
        'stars': stars,
        'comment': comment,
        'went_to_store': wentToStore ? 1 : 0,
        'rated_at': at.toIso8601String(),
      });
    await _write(items);
    await flush(gateway: gateway);
  }

  /// Sends the waiting ratings; one that fails stays for next time.
  static Future<void> flush({PlatformGateway gateway = const PlatformGateway()}) async {
    final items = pending();
    if (items.isEmpty) return;
    String version = '';
    String appId = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      appId = info.packageName;
    } catch (_) {}
    final left = <Map<String, dynamic>>[];
    for (final item in items) {
      try {
        await gateway.tenant(cmd, {
          'app_id': appId,
          'platform': _platform(),
          'app_version': version,
          ...item,
        });
      } catch (_) {
        left.add(item);
      }
    }
    await _write(left);
  }

  static String _platform() {
    try {
      return Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : Platform.operatingSystem);
    } catch (_) {
      return '';
    }
  }

  /// The store's own review sheet, else the app's store page. Does nothing in
  /// an app not marked listed.
  static Future<void> openStore() async {
    if (!AppConstants.storeListed) return;
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {}
  }
}
