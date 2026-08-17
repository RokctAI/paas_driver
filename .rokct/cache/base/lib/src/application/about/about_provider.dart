import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

final aboutProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    // Raw http (pre-DI) — POST the platform gateway envelope directly; the
    // DI'd PlatformGateway client is not in play here.
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$kPlatformGatewayPath'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cmd': 'api.page.get_page',
        'payload': {'route': 'about'},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Raw http (pre-DI) — unwrap Frappe's top-level `message` envelope
      // ourselves; the dio stack's FrappeResponseInterceptor is not in play.
      final page = (data is Map ? data['message'] : null) ?? data;
      final translation = page['translation'];

      final imgUrl = page['img'];

      return {
        'title': translation['title'],
        'description': translation['description'],
        'img': imgUrl, // Include the image URL
      };
    } else {
      throw Exception('Failed to fetch about data');
    }
  } catch (e) {
    // Handle network exceptions here
    if (e.toString().contains('SocketException')) {
      // Return null to indicate network error
      return null;
    } else {
      rethrow;
    }
  }
});
