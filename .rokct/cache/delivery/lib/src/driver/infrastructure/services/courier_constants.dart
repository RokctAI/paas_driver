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

/// Courier-only constants carried out of paas_driver's host `AppConstants`.
///
/// base_sdk's AppConstants has no counterparts for these and the composer's
/// manifest "constants" key only OVERRIDES existing base fields (it never
/// adds new ones), so they live here as SDK-owned declarations.
abstract class CourierConstants {
  CourierConstants._();

  /// Hero tag shared by the profile avatar on the profile page and the
  /// edit-profile modal.
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// Legacy auth-phone-field switch, kept dart-define-driven exactly as the
  /// host declared it (used by the profile edit modal's phone field).
  static bool isSpecificNumberEnabled =
      const bool.fromEnvironment('IS_SPECIFIC_NUMBER_ENABLED');
}
