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

// What the customer map is allowed to know about a stored point of interest,
// pinned on the mapping that turns `api.poi.get_customer_pois`'s answer into
// the POIData the page draws.
//
// Two things are guarded here. The first is the label a shopper reads: the
// point's own label, and for a point typed `other` the administrator's
// free-text type alongside it, because "other" on its own names nothing.
// The second is what never reaches the map - a stored point also holds
// contacts, an internal note, the shop it belongs to and its creator, and
// none of those may appear in a marker, so the mapping is asserted to carry
// the name, the position and nothing else even when the server sends more.
//
// The outgoing request is captured by swapping the HttpService that the
// platform gateway resolves through get_it for one whose Dio uses a
// recording HttpClientAdapter; nothing touches the network.

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/data/poi_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_sdk/src/common/infrastructure/repositories/customer_poi_repository.dart';
import 'dart:io';

import 'package:base_sdk/src/handlers/demo_gateway_interceptor.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:map_sdk/src/common/di/map_sdk_di.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final Object body;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RecordingHttpService extends HttpService {
  _RecordingHttpService(this.body);

  final Object body;
  late final _RecordingAdapter adapter = _RecordingAdapter(body);

  /// The flag the gateway asked for, so a guest read can be told from an
  /// authenticated one.
  bool? requestedAuth;

  @override
  Dio client({bool requireAuth = false, bool routing = false}) {
    requestedAuth = requireAuth;
    return Dio(BaseOptions(baseUrl: 'https://platform.test'))
      ..httpClientAdapter = adapter;
  }
}

/// One row in the contract's shape, with the fields a shopper may never see
/// present so the mapping can be caught carrying them.
const _withheldKeys = <String>[
  'phone',
  'mobile',
  'email',
  'contact',
  'note',
  'notes',
  'shop',
  'owner',
  'created_by',
];

Map<String, dynamic> _row({
  String name = 'POI-0001',
  String? label = 'Water Point',
  String? type = 'landmark',
  String? customType,
  Object? latitude = -26.204103,
  Object? longitude = 28.047305,
}) => <String, dynamic>{
  'name': name,
  if (label != null) 'label': label,
  if (type != null) 'type': type,
  if (customType != null) 'custom_type': customType,
  'latitude': latitude,
  'longitude': longitude,
  'address': '1 Market Street',
};

void main() {
  _RecordingHttpService register(Object body) {
    final http = _RecordingHttpService(body);
    if (getIt.isRegistered<HttpService>()) {
      getIt.unregister<HttpService>();
    }
    getIt.registerSingleton<HttpService>(http);
    return http;
  }

  tearDown(() {
    if (getIt.isRegistered<HttpService>()) {
      getIt.unregister<HttpService>();
    }
  });

  group('CustomerPoiRepository.getCustomerPois request', () {
    test('posts the prefix-free cmd and the centre it was asked for',
        () async {
      final http = register([_row()]);

      final result = await CustomerPoiRepository().getCustomerPois(
        latitude: -26.2,
        longitude: 28.05,
        radiusKm: 2,
      );

      final request = http.adapter.captured;
      expect(request, isNotNull, reason: 'no request reached the adapter');
      expect(request!.method, 'POST');
      expect(request.path, kPlatformGatewayPath);

      final body = (request.data as Map).cast<String, dynamic>();
      expect(body['cmd'], 'api.poi.get_customer_pois');
      final payload = (body['payload'] as Map).cast<String, dynamic>();
      expect(payload['latitude'], -26.2);
      expect(payload['longitude'], 28.05);
      expect(payload['radius_km'], 2);

      expect(result, isA<Success<List<POIData>>>());
    });

    test('reads as a guest, because the def allows one', () async {
      final http = register(const <Object>[]);

      await CustomerPoiRepository()
          .getCustomerPois(latitude: -26.2, longitude: 28.05);

      expect(http.requestedAuth, isFalse);
    });

    test('defaults the radius to the def own default', () async {
      final http = register(const <Object>[]);

      await CustomerPoiRepository()
          .getCustomerPois(latitude: -26.2, longitude: 28.05);

      final body = (http.adapter.captured!.data as Map).cast<String, dynamic>();
      final payload = (body['payload'] as Map).cast<String, dynamic>();
      expect(payload['radius_km'], CustomerPoiRepository.defaultRadiusKm);
    });

    test('an empty area is an empty list, not a failure', () async {
      register(const <Object>[]);

      final result = await CustomerPoiRepository()
          .getCustomerPois(latitude: -26.2, longitude: 28.05);

      expect(result, isA<Success<List<POIData>>>());
      result.when(
        success: (pois) => expect(pois, isEmpty),
        failure: (error, status) => fail('an empty area failed: $error'),
      );
    });
  });

  group('CustomerPoiRepository mapping', () {
    test('a typed point is labelled with its label', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(label: 'Water Point', type: 'landmark'),
      ]);

      expect(pois, hasLength(1));
      expect(pois.single.name, 'Water Point');
      expect(pois.single.latitude, -26.204103);
      expect(pois.single.longitude, 28.047305);
    });

    test('an "other" point carries the free-text type beside its label', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(label: 'North Gate', type: 'other', customType: 'Boom gate'),
      ]);

      expect(pois.single.name, 'North Gate · Boom gate');
    });

    test('the free-text type is ignored unless the type is "other"', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(label: 'North Gate', type: 'landmark', customType: 'Boom gate'),
      ]);

      expect(pois.single.name, 'North Gate');
    });

    test('an "other" point with no label falls back to the free text', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(label: null, type: 'other', customType: 'Boom gate'),
      ]);

      expect(pois.single.name, 'Boom gate');
    });

    test('a point with nothing to call it falls back to the record id', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(name: 'POI-0009', label: '  ', type: null),
      ]);

      expect(pois.single.name, 'POI-0009');
    });

    test('every point carries the default pin, whatever its type', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(type: 'landmark'),
        _row(name: 'POI-0002', label: 'Clinic', type: 'clinic'),
        _row(
          name: 'POI-0003',
          label: 'North Gate',
          type: 'other',
          customType: 'Boom gate',
        ),
      ]);

      expect(pois, hasLength(3));
      for (final poi in pois) {
        expect(poi.pin, CustomerPoiRepository.pinAsset);
        expect(poi.titleColor, Colors.transparent);
      }
    });

    test('coordinates sent as strings are still read', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(latitude: '-26.204103', longitude: ' 28.047305 '),
      ]);

      expect(pois.single.latitude, -26.204103);
      expect(pois.single.longitude, 28.047305);
    });

    test('a point with no usable position is dropped, not drawn at 0,0', () {
      final pois = CustomerPoiRepository.poiListFrom([
        _row(latitude: null),
        _row(name: 'POI-0002', longitude: 'not a number'),
        _row(name: 'POI-0003', label: 'Clinic'),
      ]);

      expect(pois.map((poi) => poi.name), ['Clinic']);
    });

    test('missing keys cost a marker at most, never the list', () {
      final pois = CustomerPoiRepository.poiListFrom([
        <String, dynamic>{'latitude': -26.2, 'longitude': 28.05},
        'not a row',
        _row(name: 'POI-0002', label: 'Clinic'),
      ]);

      expect(pois.map((poi) => poi.name), ['', 'Clinic']);
    });

    test('a one-key envelope around the list is read too', () {
      for (final key in const ['data', 'pois', 'message', 'result']) {
        final pois = CustomerPoiRepository.poiListFrom({
          key: [_row(label: 'Clinic')],
        });
        expect(pois.single.name, 'Clinic', reason: 'envelope key "$key"');
      }
    });

    test('nothing recognisable is no points rather than a throw', () {
      expect(CustomerPoiRepository.poiListFrom(null), isEmpty);
      expect(CustomerPoiRepository.poiListFrom('unexpected'), isEmpty);
      expect(CustomerPoiRepository.poiListFrom(const {}), isEmpty);
    });

    test('a point of interest reaches the map as position and name only', () {
      final row = _row(label: 'Water Point');
      for (final key in _withheldKeys) {
        row[key] = 'must not be drawn';
      }

      final poi = CustomerPoiRepository.poiListFrom([row]).single;

      // POIData holds five fields; each is checked against the row so a
      // withheld value cannot have been carried into any of them.
      expect(poi.name, 'Water Point');
      expect(poi.latitude, -26.204103);
      expect(poi.longitude, 28.047305);
      expect(poi.pin, CustomerPoiRepository.pinAsset);
      expect(poi.titleColor, CustomerPoiRepository.pinTint);

      final drawn = poi.toString();
      for (final key in _withheldKeys) {
        expect(drawn, isNot(contains(key)), reason: '$key reached POIData');
      }
      expect(drawn, isNot(contains('must not be drawn')));
      expect(drawn, isNot(contains('Market Street')));
    });
  });

  group('demo session', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LocalStorage.init();
      await DemoSession.instance.activate();
      if (getIt.isRegistered<HttpService>()) {
        await getIt.unregister<HttpService>();
      }
      getIt.registerSingleton<HttpService>(HttpService());
      DemoFixtures.reset();
      DemoFixtures.loader = (key) async {
        final f = File(key.replaceFirst(
            '$mapDemoFixtureDirectory/', 'templates/assets/demo/map/'));
        return f.existsSync() ? f.readAsString() : null;
      };
      DemoFixtures.registerAssetDirectory(mapDemoFixtureDirectory);
    });

    tearDown(() async {
      DemoFixtures.reset();
      await DemoSession.instance.clear();
    });

    test('the real repository serves no points from the demo fixture',
        () async {
      final result = await CustomerPoiRepository()
          .getCustomerPois(latitude: -26.2, longitude: 28.05);

      result.when(
        success: (pois) => expect(pois, isEmpty),
        failure: (error, status) => fail('the demo fixture failed: $error'),
      );
    });
  });
}
