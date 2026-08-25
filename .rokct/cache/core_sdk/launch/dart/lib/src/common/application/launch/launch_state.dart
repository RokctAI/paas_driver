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


import 'package:installed_apps/app_info.dart';

class LaunchState {
  final List<AppInfo> allApps;
  final List<AppInfo> filteredApps;
  final bool isLoading;
  final String query;

  /// Why the app list failed to load, or null if it didn't.
  ///
  /// Distinguishing "enumeration failed" from "there are no apps" matters on
  /// a launcher: both render an empty list, but one is a broken device and
  /// the other is a bare one, and the user can act on exactly one of them.
  /// Swallowing the error made them identical on screen and in the logs.
  final String? error;

  LaunchState({
    this.allApps = const [],
    this.filteredApps = const [],
    this.isLoading = true,
    this.query = '',
    this.error,
  });

  LaunchState copyWith({
    List<AppInfo>? allApps,
    List<AppInfo>? filteredApps,
    bool? isLoading,
    String? query,
    String? error,
    bool clearError = false,
  }) {
    return LaunchState(
      allApps: allApps ?? this.allApps,
      filteredApps: filteredApps ?? this.filteredApps,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
