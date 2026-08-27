// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

final shopNameProvider = FutureProvider.family<String, String>((
  ref,
  shopId,
) async {
  // Raw http (pre-DI) — POST the platform gateway envelope directly; the
  // DI'd PlatformGateway client is not in play here.
  final response = await http.post(
    Uri.parse('${AppConstants.baseUrl}$kPlatformGatewayPath'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'cmd': 'api.shop.get_shops_by_ids',
      'payload': {
        'shops': [shopId],
      },
    }),
  ).timeout(const Duration(seconds: 30));

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    // Raw http (pre-DI) — unwrap Frappe's top-level `message` envelope
    // ourselves; the backend returns api_response(data=[...]) inside it.
    final result =
        (responseData is Map ? responseData['message'] : null) ?? responseData;
    final shopTranslation = result['data'][0]['translation']['title'];
    return shopTranslation;
  } else {
    throw Exception('Failed to load shop details');
  }
});
