import 'package:dio/dio.dart';

/// Calls Google's official Places API v1 directly — no third-party wrapper
/// package. Replaces a git-forked `google_place` dependency that this
/// workspace decided not to depend on.
class GooglePlacesService {
  final Dio _dio;
  final String _apiKey;

  GooglePlacesService({required Dio dio, required String apiKey})
      : _dio = dio,
        _apiKey = apiKey;

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

      final response = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List predictions = response.data['suggestions'] ?? [];
        return predictions
            .map((json) => AutocompletePrediction.fromJson(json))
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

      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data != null) {
        return PlaceDetails.fromJson(response.data);
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
