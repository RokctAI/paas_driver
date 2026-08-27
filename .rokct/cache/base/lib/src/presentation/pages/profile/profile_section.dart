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


import 'package:flutter/widgets.dart';

/// One section of the generic profile page.
///
/// Feature SDKs contribute sections at bootstrap (typically from a manifest
/// `di_hooks` entry, per ADR-005) via [ProfileSectionRegistry.register];
/// [GenericProfilePage] renders every registered section in [order].
class ProfileSection {
  /// Unique across all SDKs. A duplicate id is dropped (first wins).
  final String id;

  /// Render position; lower renders first. Ties break by [id].
  final int order;

  /// Builds the section's widget inside the page body.
  final Widget Function(BuildContext context) builder;

  /// Optional async visibility gate, resolved once when the page mounts.
  /// `null` means always visible; `false` or a thrown error hides the
  /// section (mirrors the lms admin-row gating pattern).
  final Future<bool> Function()? visible;

  const ProfileSection({
    required this.id,
    required this.order,
    required this.builder,
    this.visible,
  });
}
