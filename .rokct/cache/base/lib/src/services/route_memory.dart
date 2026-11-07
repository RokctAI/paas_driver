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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import 'local_storage.dart';

/// Brings an app back to the page it was on (Ray, 2026-11-06: "Flutter has a
/// problem where we move to another app and when we come back, it doesn't
/// remember the state it was in"; "this needs to benefit our whole fleet").
///
/// Android closes apps in the background to save memory; the next open is a
/// cold start that went to splash and then home, losing the page. Every app
/// shell's [AppWidget] template attaches its router here, so the current
/// page's address is kept (in [LocalStorage], with the time) as the person
/// moves around. After the splash lands home ([AppHelpers.goHome]), the page
/// left less than [within] ago is opened again, once per run.
///
/// Splash, the no-connection and maintenance pages and any login or sign-up
/// page are never kept: coming back to those means starting over. Text a
/// page wants kept (a chat's unsent draft) is the page's own business.
///
/// Signing out forgets the kept page ([forget], called by
/// [LocalStorage.logout]), so the next person to sign in on the phone never
/// lands on the last one's page. A page that can only be opened with data
/// handed over in code (not in its address) is not reopened: it would fail
/// to build from the address alone.
class RouteMemory {
  RouteMemory._();

  static const storageKey = 'route_memory.v1';

  /// How old a kept page may be and still be opened again.
  static Duration within = const Duration(hours: 12);

  static RootStackRouter? _router;
  static bool _restored = false;
  static String _lastSaved = '';

  /// Kept nowhere: the start-up pages, and anything to do with signing in.
  @visibleForTesting
  static bool skip(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    if (path.isEmpty || path == '/' || path == '/no-connection' || path == '/maintenance') return true;
    // Whole path segments only, so "design" or "assignments" are kept.
    const words = {'login', 'logout', 'sign-in', 'signin', 'sign-up', 'signup', 'sign_in', 'sign_up', 'register', 'registration', 'otp', 'splash', 'verify-otp'};
    for (final seg in path.toLowerCase().split('/')) {
      if (words.contains(seg)) return true;
    }
    return false;
  }

  /// Forgets the kept page. Signing out calls this.
  static Future<void> forget() async {
    _lastSaved = '';
    await LocalStorage.deleteJson(storageKey);
  }

  /// Whether every page on the way to [url] can be built from the address
  /// alone. A generated page that needs typed arguments throws when they
  /// are missing; building the page widgets here (they are not mounted)
  /// finds that before anything is pushed.
  @visibleForTesting
  static bool rebuildable(RoutingController r, String url) {
    final List<RouteMatch>? matches;
    try {
      matches = r.matcher.match(url);
    } catch (_) {
      return false;
    }
    if (matches == null || matches.isEmpty) return false;
    for (final m in matches.expand((e) => e.flattened)) {
      final config = _find(r.routeCollection, m.name);
      if (config == null) return false;
      try {
        config.page.builder(RouteData(
          route: m,
          router: r,
          stackKey: const ValueKey('route_memory.check'),
          pendingChildren: const [],
          type: const RouteType.material(),
        ));
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  // auto_route 9 gives `children` as a RouteCollection, 10 as a
  // List<AutoRoute>. Read it loosely so both versions compile.
  static AutoRoute? _find(RouteCollection c, String name) =>
      c[name] ?? _findIn(c.routes, name);

  static AutoRoute? _findIn(Iterable<AutoRoute> routes, String name) {
    for (final route in routes) {
      if (route.name == name) return route;
      final dynamic sub = route.children;
      final Iterable<AutoRoute>? kids = sub is RouteCollection
          ? sub.routes
          : sub is Iterable<AutoRoute>
              ? sub
              : null;
      if (kids == null) continue;
      final found = _findIn(kids, name);
      if (found != null) return found;
    }
    return null;
  }

  /// Called once by the app shell with its root router.
  static void attach(RootStackRouter router) {
    if (identical(_router, router)) return;
    _router?.removeListener(_save);
    _router = router;
    router.addListener(_save);
  }

  static void _save() {
    final r = _router;
    if (r == null) return;
    String url;
    try {
      url = r.currentUrl;
    } catch (_) {
      return;
    }
    if (url == _lastSaved || skip(url)) return;
    _lastSaved = url;
    unawaited(LocalStorage.setJson(storageKey, {'url': url, 'at': DateTime.now().toIso8601String()}));
  }

  /// The page kept less than [within] ago, if any.
  static String? recent({DateTime? now}) {
    final m = LocalStorage.getJson(storageKey);
    final url = m?['url'];
    final at = DateTime.tryParse((m?['at'] ?? '').toString());
    if (url is! String || at == null || skip(url)) return null;
    if ((now ?? DateTime.now()).difference(at) > within) return null;
    return url;
  }

  /// Once per run, right after the app lands home: opens the kept page on
  /// top of home, so back still leads home. Nothing when the kept page is
  /// home itself, too old, or there is none.
  static void restoreAfterHome() {
    if (_restored) return;
    _restored = true;
    final url = recent();
    final r = _router;
    if (url == null || r == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (r.currentUrl == url) return;
        if (!rebuildable(r, url)) {
          debugPrint('==> RouteMemory: $url needs data the address does not carry; staying home');
          return;
        }
        unawaited(r.pushNamed<Object?>(url).catchError((Object e) {
          debugPrint('==> RouteMemory could not reopen $url: $e');
          return null;
        }));
      } catch (e) {
        debugPrint('==> RouteMemory could not reopen $url: $e');
      }
    });
  }

  /// For tests: forget the router and let a restore run again.
  @visibleForTesting
  static void reset() {
    _router?.removeListener(_save);
    _router = null;
    _restored = false;
    _lastSaved = '';
  }
}
