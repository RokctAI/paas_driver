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

/// One tappable glance-card entry. Mirrors base_sdk's `GlanceCardItem` shape
/// (icon + text + tap) but declared here so the home-page template doesn't
/// need a host-supplied import just to describe "an icon and a line of
/// text" — the host adapter converts its own domain data into these.
class LaunchGlanceSignal {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const LaunchGlanceSignal({
    required this.icon,
    required this.text,
    this.onTap,
  });
}

/// Host-supplied glance content for the launcher home screen.
///
/// launch_sdk has no urgent signal of its own to show — an installed-apps
/// listing carries no notion of "urgent" — and must not import comms_sdk,
/// productivity_sdk, or any other feature SDK directly to invent one
/// (ADR-005). Apps composing launch_sdk register an implementation
/// (typically via `GetIt` before `LauncherHomePage` builds) that wraps
/// whatever that specific app actually has available: comms_sdk
/// notifications in one app, productivity_sdk tasks in another, nothing at
/// all in a bare-bones one. Without a registration, the glance card simply
/// doesn't render — see `templates/pages/home.dart`'s `@launcher-glance`
/// marker, which reads this via `GetIt.instance.isRegistered<...>()`.
abstract class LaunchGlanceSource {
  List<LaunchGlanceSignal> build();
}
