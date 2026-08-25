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
