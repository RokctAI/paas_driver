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
// The package:dio import below is only for its request/response types.
// The actual client comes from base_sdk's dioHttp (HttpService), which sets
// connectTimeout and receiveTimeout (30s) centrally on its BaseOptions; the
// injectable _client seam is test-only.

import 'dart:convert';

import 'package:base_sdk/src/di/injection.dart';
import 'package:dio/dio.dart';

/// Calls Google's official Places API v1 directly — no third-party wrapper
/// package. Replaces a git-forked `google_place` dependency that this
/// workspace decided not to depend on.
///
/// Requests go through base_sdk's [HttpService] client so they ride the
/// standard interceptor chain — TimingInterceptor (timing telemetry) and the
/// ADR-006 trace-id stamping — instead of a bare [Dio] instance that the
/// telemetry pipeline never sees. `requireAuth: false` keeps the tenant
/// bearer token off this third-party host.
class GooglePlacesService {
  /// Test seam only. Production resolves the shared [HttpService] client
  /// lazily so registration order at bootstrap does not matter.
  final Dio? _client;

  final String _apiKey;

  GooglePlacesService({Dio? client, required String apiKey})
      : _client = client,
        _apiKey = apiKey;

  Dio get _dio => _client ?? dioHttp.client(requireAuth: false);

  /// Fetch autocomplete suggestions from Google Places API (v1)
  /// https://places.googleapis.com/v1/places:autocomplete
  Future<List<AutocompletePrediction>> getAutocomplete(
    String input, {
    String? sessionToken,
    String? languageCode,
  }) async {
    if (input.isEmpty) return [];

    try {
      final Map<String, dynamic> data = {
        'input': input,
      };

      if (sessionToken != null) {
        data['sessionToken'] = sessionToken;
      }
      if (languageCode != null) {
        data['languageCode'] = languageCode;
      }

      final response = await _dio.post<dynamic>(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
          },
        ),
      );

      final body = response.data;
      // Dio only auto-decodes application/json; fall back for providers that
      // serve JSON under another content type.
      final dynamic decoded = body is String ? json.decode(body) : body;
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final List predictions = decoded['suggestions'] ?? [];
        return predictions
            .map((prediction) => AutocompletePrediction.fromJson(prediction))
            .toList();
      }
    } catch (e) {
      // Fallback gracefully on API errors
    }
    return [];
  }

  /// Get place details (including latitude/longitude geometry) by placeId
  /// https://places.googleapis.com/v1/places/{placeId}
  Future<PlaceDetails?> getPlaceDetails(String placeId, {String? sessionToken}) async {
    try {
      final Map<String, String> queryParameters = {
        'fields': 'id,displayName,formattedAddress,location',
        'key': _apiKey,
      };

      if (sessionToken != null) {
        queryParameters['sessionToken'] = sessionToken;
      }

      final response = await _dio.get<dynamic>(
        'https://places.googleapis.com/v1/places/$placeId',
        queryParameters: queryParameters,
      );

      final body = response.data;
      // Dio only auto-decodes application/json; fall back for providers that
      // serve JSON under another content type.
      final dynamic decoded = body is String ? json.decode(body) : body;
      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        return PlaceDetails.fromJson(decoded);
      }
    } catch (e) {
      // Fallback gracefully on API errors
    }
    return null;
  }
}

class AutocompletePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  AutocompletePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    final placePrediction = json['placePrediction'] ?? {};
    final structuredFormat = placePrediction['structuredFormat'] ?? {};

    return AutocompletePrediction(
      placeId: placePrediction['placeId'] ?? '',
      description: placePrediction['text']?['text'] ?? '',
      mainText: structuredFormat['mainText']?['text'] ?? '',
      secondaryText: structuredFormat['secondaryText']?['text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String id;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.id,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    return PlaceDetails(
      id: json['id'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
