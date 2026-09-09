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

// Regression guard for how GooglePlacesService presents its API key.
//
// The key must ride an `X-Goog-Api-Key` header and must never appear in
// the request URI. A credential in a query string is copied verbatim into
// every access log between the client and the provider - proxies,
// gateways, and Google's own - and none of those are ours to redact, so
// keeping it out of the URI in the first place is the only fix that
// reaches them. `getAutocomplete` has always sent the header;
// `getPlaceDetails` used to send `key=` in the query and is the reason
// this file exists.
//
// The outgoing request is captured through the service's documented
// `client` test seam, backed by a recording HttpClientAdapter; nothing
// touches the network.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_sdk/src/common/infrastructure/services/places/places_service.dart';

/// A value shaped like a real Google API key, so a substring search for it
/// across the URI is meaningful.
const _apiKey = 'AIzaSyTEST-ThisIsNotARealKey_0123456789abcd';
const _placeId = 'ChIJj61dQgK6j4AR4GeTYWZsKWw';

/// Records the request Dio would have sent and answers with a minimal but
/// fully parseable Places body so the success path is exercised.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? captured;
  final Map<String, dynamic> body;

  _RecordingAdapter(this.body);

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

const _placeDetailsBody = <String, dynamic>{
  'id': _placeId,
  'formattedAddress': '1 Test Road, Messina',
  'displayName': {'text': 'Test Place'},
  'location': {'latitude': -26.204103, 'longitude': 28.047305},
};

const _autocompleteBody = <String, dynamic>{
  'suggestions': [
    {
      'placePrediction': {
        'placeId': _placeId,
        'text': {'text': '1 Test Road, Messina'},
        'structuredFormat': {
          'mainText': {'text': '1 Test Road'},
          'secondaryText': {'text': 'Messina'},
        },
      },
    },
  ],
};

/// Builds a service whose Dio records instead of sending.
(GooglePlacesService, _RecordingAdapter) _serviceFor(
  Map<String, dynamic> body,
) {
  final adapter = _RecordingAdapter(body);
  final dio = Dio()..httpClientAdapter = adapter;
  return (GooglePlacesService(client: dio, apiKey: _apiKey), adapter);
}

/// Every place the credential could hide in a request line.
void _expectKeyAbsentFromUri(RequestOptions request) {
  expect(
    request.uri.toString(),
    isNot(contains(_apiKey)),
    reason: 'the API key appears in the request URI',
  );
  expect(
    request.uri.query,
    isNot(contains(_apiKey)),
    reason: 'the API key appears in the query string',
  );
  expect(
    request.uri.queryParameters.keys,
    isNot(contains('key')),
    reason: 'a `key` query parameter is still being sent',
  );
  expect(
    request.queryParameters.containsKey('key'),
    isFalse,
    reason: 'a `key` entry is still in the structured query parameters',
  );
}

void main() {
  group('GooglePlacesService.getPlaceDetails', () {
    test('sends the API key as a header, never in the URI', () async {
      final (service, adapter) = _serviceFor(_placeDetailsBody);

      final details = await service.getPlaceDetails(_placeId);

      final request = adapter.captured;
      expect(request, isNotNull, reason: 'no request reached the adapter');

      _expectKeyAbsentFromUri(request!);
      expect(request.headers['X-Goog-Api-Key'], _apiKey);

      // The call still works and still asks for the fields it needs.
      expect(details, isNotNull);
      expect(details!.id, _placeId);
      expect(
        request.uri.queryParameters['fields'],
        'id,displayName,formattedAddress,location',
      );
      expect(request.uri.path, endsWith('/v1/places/$_placeId'));
    });

    test('keeps the session token in the query and the key out of it',
        () async {
      final (service, adapter) = _serviceFor(_placeDetailsBody);

      await service.getPlaceDetails(_placeId, sessionToken: 'session-123');

      final request = adapter.captured!;
      _expectKeyAbsentFromUri(request);
      expect(request.headers['X-Goog-Api-Key'], _apiKey);
      // sessionToken is not a credential; it belongs in the query.
      expect(request.uri.queryParameters['sessionToken'], 'session-123');
    });
  });

  group('GooglePlacesService.getAutocomplete', () {
    test('sends the API key as a header, never in the URI', () async {
      final (service, adapter) = _serviceFor(_autocompleteBody);

      final predictions = await service.getAutocomplete('1 Test Road');

      final request = adapter.captured;
      expect(request, isNotNull, reason: 'no request reached the adapter');

      _expectKeyAbsentFromUri(request!);
      expect(request.headers['X-Goog-Api-Key'], _apiKey);

      expect(predictions, hasLength(1));
      expect(predictions.first.placeId, _placeId);
    });
  });
}
