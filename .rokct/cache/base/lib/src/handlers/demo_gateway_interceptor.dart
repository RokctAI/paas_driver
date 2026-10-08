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

// compliance-ignore-file: flutter-http-timeout
// No client is created here: this is an interceptor on HttpService's Dio,
// whose BaseOptions set the timeouts centrally.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// Thrown (as a [DioException]'s `error`) when a demo session calls a
/// platform `cmd` that has no fixture. Demo never falls through to the
/// network and never answers with a silent empty value: a missing fixture
/// is a gap to fix, so it fails loudly with the cmd in the message.
class DemoFixtureMissing implements Exception {
  const DemoFixtureMissing(this.cmd);

  final String cmd;

  @override
  String toString() =>
      'DemoFixtureMissing: no demo fixture for platform cmd "$cmd". '
      'Add $cmd.json to a directory registered with '
      'DemoFixtures.registerAssetDirectory.';
}

/// Where demo answers for the platform gateway come from: JSON files named
/// `<cmd>.json` (for example `api.lms.list_courses.json`) in the asset
/// directories SDKs register at DI time.
///
/// A fixture file holds exactly what the backend method returns (the value
/// inside Frappe's `message` envelope), so the real repository parses it
/// with the same code it uses for a live answer. Three conveniences keep
/// fixtures honest without code:
///
/// * `"$now_iso"` / `"$now_ms"` as a string value anywhere are replaced
///   with the current UTC time (ISO-8601 / epoch milliseconds), for
///   answers such as a server clock that must not be frozen in a file.
///   `"$today"` gives the UTC date (`yyyy-MM-dd`). Each may carry one
///   relative offset `<+|-><n><m|h|d|w>`, e.g. `"$now_iso-30d"`,
///   `"$now_ms+2h"`, `"$today-7d"`, so dated fixtures stay current.
/// * An object of the form
///   `{"$demo_select": {"by": "payload.<field>" | "role", "cases": {...},
///   "default": <value>}}` answers the case keyed by that payload field
///   (or by the signed-in account's role), else `default` (null when
///   absent). Cases are resolved recursively, so they may hold tokens.
///
/// Registration is idempotent and order-preserving: the first directory
/// holding `<cmd>.json` wins.
class DemoFixtures {
  DemoFixtures._();

  static final List<String> _directories = <String>[];

  /// Reads one asset as text, or null when it does not exist. Defaults to
  /// the root bundle; tests swap it for a file-system or in-memory reader.
  static Future<String?> Function(String key) loader = _loadAsset;

  /// Reads the signed-in account's role for `"by": "role"` selection.
  /// A seam so tests need no storage.
  static String? Function() role = _storedRole;

  /// Registers [directory] (an asset path such as `assets/demo/lms`) as a
  /// source of `<cmd>.json` fixtures.
  static void registerAssetDirectory(String directory) {
    final String dir = directory.endsWith('/')
        ? directory.substring(0, directory.length - 1)
        : directory;
    if (!_directories.contains(dir)) _directories.add(dir);
  }

  /// The registered directories, in lookup order.
  static List<String> get directories => List.unmodifiable(_directories);

  /// Test seam: forgets every registration and restores the defaults.
  static void reset() {
    _directories.clear();
    loader = _loadAsset;
    role = _storedRole;
  }

  /// The demo answer for [cmd] called with [payload]. Throws
  /// [DemoFixtureMissing] when no registered directory has `<cmd>.json`.
  static Future<Object?> answer(String cmd, Map<String, dynamic> payload) async {
    for (final String dir in _directories) {
      final String? text = await loader('$dir/$cmd.json');
      if (text == null) continue;
      return _resolve(jsonDecode(text), payload, DateTime.now().toUtc());
    }
    throw DemoFixtureMissing(cmd);
  }

  static Object? _resolve(
    Object? node,
    Map<String, dynamic> payload,
    DateTime now,
  ) {
    if (node is String) {
      final Object? token = resolveTimeToken(node, now);
      return token ?? node;
    }
    if (node is List) {
      return <Object?>[for (final e in node) _resolve(e, payload, now)];
    }
    if (node is Map) {
      final Object? select = node[r'$demo_select'];
      if (select is Map) {
        final String by = select['by']?.toString() ?? '';
        final Object? key = by == 'role'
            ? role()
            : by.startsWith('payload.')
                ? payload[by.substring('payload.'.length)]
                : null;
        final Object? cases = select['cases'];
        final Object? picked = cases is Map && key != null &&
                cases.containsKey(key.toString())
            ? cases[key.toString()]
            : select['default'];
        return _resolve(picked, payload, now);
      }
      return <String, dynamic>{
        for (final MapEntry<dynamic, dynamic> e in node.entries)
          e.key.toString(): _resolve(e.value, payload, now),
      };
    }
    return node;
  }

  static final RegExp _timeToken =
      RegExp(r'^\$(now_iso|now_ms|today)(?:([+-])(\d+)([mhdw]))?$');

  /// Resolves a time token against [now], or null when [value] is not one.
  ///
  /// `$now_iso`, `$now_ms` and `$today` (UTC date, `yyyy-MM-dd`) may carry
  /// one signed offset `<+|-><n><m|h|d|w>`: `$now_iso-30d`, `$now_ms+2h`,
  /// `$today-7d`. Anything else (e.g. `$now_iso-1y`, `$now_iso -2d`) is
  /// not a token and is returned unchanged by the resolver.
  static Object? resolveTimeToken(String value, DateTime now) {
    final RegExpMatch? m = _timeToken.firstMatch(value);
    if (m == null) return null;
    DateTime t = now.toUtc();
    if (m.group(2) != null) {
      final int n = int.parse(m.group(3)!);
      final Duration unit = switch (m.group(4)) {
        'm' => const Duration(minutes: 1),
        'h' => const Duration(hours: 1),
        'd' => const Duration(days: 1),
        _ => const Duration(days: 7),
      };
      t = m.group(2) == '+' ? t.add(unit * n) : t.subtract(unit * n);
    }
    switch (m.group(1)) {
      case 'now_iso':
        return t.toIso8601String();
      case 'now_ms':
        return t.millisecondsSinceEpoch;
      default:
        return t.toIso8601String().substring(0, 10);
    }
  }

  static Future<String?> _loadAsset(String key) async {
    try {
      return await rootBundle.loadString(key);
    } catch (_) {
      return null;
    }
  }

  static String? _storedRole() {
    try {
      return LocalStorage.getUser()?.role;
    } catch (_) {
      return null;
    }
  }
}

/// Answers platform-gateway calls from [DemoFixtures] while
/// [DemoSession.demoActive], so a demo session runs the REAL repository
/// code end to end and only the network hop is replaced.
///
/// The switch is read on every request, never cached: a server-marked demo
/// account signs in long after the Dio client was built, and a sign-out
/// ends the session mid-run. Outside a demo session this is a pass-through.
///
/// Only `POST` [kPlatformGatewayPath] is intercepted. Inside a demo
/// session a gateway call NEVER reaches the network: a known cmd resolves
/// with its fixture, an unknown one fails with [DemoFixtureMissing].
/// Other paths pass through untouched (SDKs that still register their own
/// demo repositories are unaffected).
class DemoGatewayInterceptor extends Interceptor {
  const DemoGatewayInterceptor({this.isDemo});

  /// Test seam. Null means [DemoSession.demoActive], read per request.
  final bool Function()? isDemo;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool demo = isDemo?.call() ?? DemoSession.demoActive;
    if (!demo || !_isGatewayCall(options)) {
      handler.next(options);
      return;
    }
    final Object? body = options.data;
    final Object? cmd = body is Map ? body['cmd'] : null;
    final Object? rawPayload = body is Map ? body['payload'] : null;
    final Map<String, dynamic> payload = rawPayload is Map
        ? Map<String, dynamic>.from(rawPayload)
        : <String, dynamic>{};
    try {
      if (cmd is! String || cmd.isEmpty) {
        throw const DemoFixtureMissing('<missing cmd>');
      }
      final Object? data = await DemoFixtures.answer(cmd, payload);
      handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          statusMessage: 'OK (demo fixture)',
          data: data,
        ),
      );
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          message: e.toString(),
        ),
      );
    }
  }

  static bool _isGatewayCall(RequestOptions options) {
    if (options.method.toUpperCase() != 'POST') return false;
    final String path = options.path;
    return path == kPlatformGatewayPath ||
        Uri.tryParse(path)?.path == kPlatformGatewayPath;
  }
}
