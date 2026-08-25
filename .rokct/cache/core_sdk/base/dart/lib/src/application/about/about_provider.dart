// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


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
