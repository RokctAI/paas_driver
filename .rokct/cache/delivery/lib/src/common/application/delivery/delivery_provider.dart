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

final deliveryProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/api/v1/rest/pages/delivery'),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final translation = data['data']['translation'];
      return {
        'title': translation['title'],
        'description': translation['description'],
      };
    } else {
      throw Exception('Failed to fetch delivery data');
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
