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
