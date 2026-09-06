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

// Regression guard for the OpenRouteService directions request built by
// DrawRepository.getRouting.
//
// ORS's GET /v2/directions/{profile} takes `start` and `end` as
// comma-separated `lon,lat` strings. The repository used to hand Dio the
// Dart records `(lon, lat)`, which Dio stringified as "(lon, lat)" (with
// parentheses and a space), so every routing call came back HTTP 400 with
// ORS error code 2003 ("Parameter 'start' has incorrect value").
//
// The outgoing request is captured by swapping the HttpService that
// `dioHttp` resolves through get_it for one whose Dio uses a recording
// HttpClientAdapter; nothing touches the network.

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/models/response/draw_routing_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_sdk/src/common/infrastructure/repositories/draw_repository.dart';

/// Records the request Dio would have sent and answers with a minimal but
/// fully parseable ORS directions body so the success path is exercised.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(_orsDirectionsBody),
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
  final adapter = _RecordingAdapter();

  @override
  Dio client({bool requireAuth = false, bool routing = false}) =>
      Dio(BaseOptions(baseUrl: 'https://ors.test'))
        ..httpClientAdapter = adapter;
}

const _orsDirectionsBody = <String, dynamic>{
  'type': 'FeatureCollection',
  'bbox': [28.047305, -26.204103, 28.056, -26.195],
  'features': [
    {
      'bbox': [28.047305, -26.204103, 28.056, -26.195],
      'type': 'Feature',
      'properties': {
        'segments': [
          {
            'distance': 1234.5,
            'duration': 321,
            'steps': [
              {
                'distance': 1234.5,
                'duration': 321.0,
                'type': 11,
                'instruction': 'Head north',
                'name': '-',
                'way_points': [0, 1],
              },
            ],
          },
        ],
        'summary': {'distance': 1234.5, 'duration': 321},
        'way_points': [0, 1],
      },
      'geometry': {
        'coordinates': [
          [28.047305, -26.204103],
          [28.056, -26.195],
        ],
        'type': 'LineString',
      },
    },
  ],
  'metadata': {
    'attribution': 'openrouteservice.org',
    'service': 'routing',
    'timestamp': 1,
    'query': {
      'coordinates': [
        [28.047305, -26.204103],
        [28.056, -26.195],
      ],
      'profile': 'driving-car',
      'format': 'json',
    },
    'engine': {
      'version': '8.0.0',
      'build_date': '2026-01-01T00:00:00Z',
      'graph_date': '2026-01-01T00:00:00Z',
    },
  },
};

/// A bare `lon,lat` pair: digits, an optional sign and decimal point, one
/// comma, and nothing else (no parentheses, no whitespace).
final _lonLatPair = RegExp(r'^-?\d+(\.\d+)?,-?\d+(\.\d+)?$');

void main() {
  late _RecordingHttpService http;

  setUp(() {
    http = _RecordingHttpService();
    if (getIt.isRegistered<HttpService>()) {
      getIt.unregister<HttpService>();
    }
    getIt.registerSingleton<HttpService>(http);
  });

  tearDown(() {
    getIt.unregister<HttpService>();
  });

  group('DrawRepository.getRouting ORS query parameters', () {
    // Full-precision doubles: the request must carry them unrounded.
    const start = LatLng(-26.204103, 28.047305);
    const end = LatLng(-26.195, 28.056);

    test('sends start and end as lon,lat strings', () async {
      final result = await DrawRepository().getRouting(start: start, end: end);

      final request = http.adapter.captured;
      expect(request, isNotNull, reason: 'no request reached the adapter');
      expect(request!.path, '/v2/directions/driving-car');

      expect(
        request.queryParameters['start'],
        '${start.longitude},${start.latitude}',
      );
      expect(
        request.queryParameters['end'],
        '${end.longitude},${end.latitude}',
      );

      expect(result, isA<Success<DrawRouting>>());
    });

    test('encoded start and end carry no parentheses or spaces', () async {
      await DrawRepository().getRouting(start: start, end: end);

      final encoded = http.adapter.captured!.uri.queryParameters;
      for (final key in const ['start', 'end']) {
        final value = encoded[key];
        expect(value, isNotNull, reason: '$key missing from the query');
        expect(value, matches(_lonLatPair), reason: '$key = "$value"');
        expect(value, isNot(contains('(')));
        expect(value, isNot(contains(')')));
        expect(value, isNot(contains(' ')));
      }
      expect(encoded['start'], '28.047305,-26.204103');
      expect(encoded['end'], '28.056,-26.195');
    });
  });
}
