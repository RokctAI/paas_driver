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

// Regression guard for the customer route wiring, which is DATA in this
// manifest rather than code in lib/: a composed app's lib/ is generated and
// gitignored, so nothing else in this package can fail when the manifest
// stops declaring what the shell needs.
//
// What it guards: base_sdk's AppRoutes seam declares pushViewMapRoute and
// pushMapSearchRoute, and eight callers across base/marketplace/orders (and
// this SDK's own view_map_page) navigate through them. Only the SDK that
// owns the page may declare its route; until this manifest did, every one
// of those calls hit _HostAppRoutes.noSuchMethod and threw a StateError,
// and the marketplace pushNamed('/map') sites found no route at all.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The seam signature, verbatim from base_sdk's app_routes.dart. The
/// installer emits `Future<Object?> pushViewMapRoute(<params>) => <body>`
/// into the host's _HostAppRoutes, so the params must match the abstract
/// method character for character or the host stops compiling.
const _viewMapSeamParams =
    'BuildContext context, {dynamic address, dynamic indexAddress, '
    'dynamic isParcel, dynamic isPop, dynamic isShopLocation, dynamic shopId}';

const _shellImport =
    'package:\${package}/presentation/routes/map_route_pages.dart';
const _routerImport =
    "import 'package:\${package}/presentation/routes/app_router.dart';";

void main() {
  final manifest = jsonDecode(File('manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  final customer =
      ((manifest['app_type'] as Map)['customer'] as Map).cast<String, dynamic>();

  List<Map<String, dynamic>> listOf(String key) =>
      ((customer[key] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .toList();

  group('map_sdk customer route wiring', () {
    test('declares the pre-fork /map and /map_search paths', () {
      final byPath = {for (final r in listOf('routes')) r['path']: r};

      expect(byPath['/map']?['page'], 'ViewMapRoute.page');
      expect(byPath['/map_search']?['page'], 'MapSearchRoute.page');
      for (final route in byPath.values) {
        expect(route['import'], _shellImport,
            reason: 'route classes are generated from the installed shell');
      }
    });

    test('installs the route shell where the routes import it from', () {
      final install = listOf('installs').singleWhere(
        (i) => i['from'] == 'templates/routes/map_route_pages.dart',
        orElse: () => <String, dynamic>{},
      );

      expect(install, isNotEmpty,
          reason: 'without the install the host has no file to generate '
              'ViewMapRoute / MapSearchRoute from');
      expect(install['to'], 'lib/presentation/routes/map_route_pages.dart');

      final shell = File(install['from'] as String).readAsStringSync();
      expect(shell, contains("@RoutePage(name: 'ViewMapRoute')"));
      expect(shell, contains("@RoutePage(name: 'MapSearchRoute')"));
      expect(shell, contains('pages.ViewMapPage('));
      expect(shell, contains('pages.MapSearchPage()'));
    });

    test('fills the two AppRoutes seams with the declared routes', () {
      final appRoutes = {
        for (final r in listOf('app_routes')) r['method'] as String: r
      };
      expect(appRoutes.keys,
          containsAll(['pushViewMapRoute', 'pushMapSearchRoute']));

      final declared = listOf('routes')
          .map((r) => (r['page'] as String).replaceAll('.page', ''))
          .toSet();
      for (final route in appRoutes.values) {
        final body = route['body'] as String;
        expect(body, isNotEmpty,
            reason: 'an app_routes entry with no body is dropped silently');
        expect(declared.any(body.contains), isTrue,
            reason: '${route['method']} navigates to a route this SDK does '
                'not declare, which auto_route drops from the router: $body');
        expect((route['imports'] as List).cast<String>(),
            contains(_routerImport),
            reason: 'the generated route classes must resolve in main.dart');
      }
    });

    test('pushViewMapRoute matches the seam signature and the shell args',
        () {
      final entry = listOf('app_routes')
          .singleWhere((r) => r['method'] == 'pushViewMapRoute');
      expect(entry['params'], _viewMapSeamParams);

      final body = entry['body'] as String;
      final shell = File('templates/routes/map_route_pages.dart')
          .readAsStringSync();
      for (final arg in [
        'address',
        'indexAddress',
        'isParcel',
        'isPop',
        'isShopLocation',
        'shopId',
      ]) {
        expect(body, contains('$arg:'),
            reason: 'seam arg $arg must reach the route');
        expect(shell, contains('this.$arg'),
            reason: 'the shell constructor must accept $arg');
      }
      // The seam's args are dynamic-typed; the page's bools are non-nullable,
      // so an omitted arg must fall back the way the page defaults it.
      expect(body, contains('isParcel: isParcel ?? false'));
      expect(body, contains('isPop: isPop ?? true'));
      expect(body, contains('isShopLocation: isShopLocation ?? false'));
    });

    test('pushMapSearchRoute keeps the seam\'s context-only signature', () {
      final entry = listOf('app_routes')
          .singleWhere((r) => r['method'] == 'pushMapSearchRoute');
      expect(entry.containsKey('params'), isFalse,
          reason: 'the installer defaults params to "BuildContext context", '
              'which is exactly the seam');
    });

    test('customer is the only flavour that carries the map routes', () {
      final flavours = (manifest['app_type'] as Map).keys.toSet();
      expect(flavours, {'customer'});
      expect(manifest['routes'], isEmpty,
          reason: 'declaring /map top level would change every persona '
              'map_sdk is composed into');
    });
  });
}
