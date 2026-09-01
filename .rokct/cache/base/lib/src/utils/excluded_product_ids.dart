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


// excluded_product_ids.dart

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

List<int> excludedProductIds = [];
List<int> excludedCategoryIds = [];

// firebase_remote_config has no Windows/Linux implementation — on desktop
// Firebase is (correctly) never initialized, so FirebaseRemoteConfig.instance
// throws [core/no-app]. Same platform guard + fail-open idiom as comms'
// firebase boot hook: off the Firebase platforms both initializers keep the
// compiled-in defaults (empty exclusion lists) instead of throwing.

Future<void> initializeExcludedProductIds() async {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set the default value for excludedProductIds
      await remoteConfig.setDefaults(<String, dynamic>{
        'excludedProductIds': '', // Default value is an empty string
      });

      // Fetch the latest value for excludedProductIds
      await remoteConfig.fetchAndActivate();

      // Update excludedProductIds with the fetched value from Remote Config
      final excludedProductIdsFromRemoteConfig = remoteConfig
          .getString('excludedProductIds')
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      excludedProductIds = excludedProductIdsFromRemoteConfig;
      // print('Excluded Product IDs: $excludedProductIds');
    } catch (e) {
      debugPrint('==> excluded product ids remote config skipped: $e');
    }
  }
}

Future<void> initializeExcludedCategoryIds() async {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set the default value for excludedCategoryIds
      await remoteConfig.setDefaults(<String, dynamic>{
        'excludedCategoryIds': '', // Default value is an empty string
      });

      // Fetch the latest value for excludedCategoryIds
      await remoteConfig.fetchAndActivate();

      // Update excludedCategoryIds with the fetched value from Remote Config
      final excludedCategoryIdsFromRemoteConfig = remoteConfig
          .getString('excludedCategoryIds')
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      excludedCategoryIds = excludedCategoryIdsFromRemoteConfig;
      // print('Excluded Category IDs: $excludedCategoryIds');
    } catch (e) {
      debugPrint('==> excluded category ids remote config skipped: $e');
    }
  }
}
