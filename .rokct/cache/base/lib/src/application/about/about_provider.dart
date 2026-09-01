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
    ).timeout(const Duration(seconds: 30));

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
