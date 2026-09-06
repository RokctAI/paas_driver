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

import 'dart:async';

import 'package:flutter/material.dart';

/// Holds a platform-view child (the driver home's `GoogleMap`) back until
/// the page it sits on has settled, and never mounts it on a page that is
/// already on its way out.
///
/// Why this exists. A `GoogleMap` creates its native view the first time
/// it is built. The plugin then awaits the view's controller and fires a
/// handful of un-awaited channel calls of its own (`updateTileOverlays`
/// first, from `_GoogleMapState.onPlatformViewCreated`). When the page is
/// replaced before the native view has finished connecting, those calls
/// land on a channel with nobody at the other end and the plugin throws
///
///   PlatformException(channel-error, Unable to establish connection on
///   channel: "dev.flutter.pigeon.google_maps_flutter_android.MapsApi
///   .updateTileOverlays.0")
///
/// from inside `google_maps_flutter_android/src/messages.g.dart`. It is the
/// plugin's own future, so the page cannot catch it (paas_driver guided
/// tour 34049256577, phone leg, both attempts: the driver home was
/// created and disposed within about a second of the demo sign-in /
/// sign-out / driver sign-in churn). The 1.19.1 `animateCamera` guard
/// covered the page's OWN calls; this covers the plugin's.
///
/// The child is mounted only once all three hold:
///
///   1. at least one frame has been painted with this widget in the tree
///      (a post-frame callback, so a page that never gets a frame never
///      spawns the view);
///   2. [settleDelay] has elapsed since that frame, uninterrupted by the
///      route losing currency;
///   3. the widget is still mounted and its [ModalRoute] is current at the
///      moment the delay lands (a route that has been replaced is no
///      longer current from the instant the replacement is pushed, well
///      before its exit transition finishes and it is disposed).
///
/// If the route is covered when the delay lands (a sheet or another page
/// on top), nothing is built; the timer is re-armed when the route becomes
/// current again, so a page that survives its cover still gets its map.
/// Once mounted the child stays mounted: the danger is at creation only,
/// and tearing a platform view down for every sheet would be worse than
/// the bug. The pending timer is cancelled in [dispose].
///
/// Until the child mounts, [placeholder] is drawn - a plain box in the
/// theme's surface colour by default, which is what the map area looks
/// like before the native map has drawn its first tiles anyway.
class DeferredMapSurface extends StatefulWidget {
  const DeferredMapSurface({
    super.key,
    required this.child,
    this.placeholder,
    this.settleDelay = defaultSettleDelay,
  });

  /// 800 ms: longer than a full Material page transition (300 ms in and,
  /// for a replaced page, 300 ms out), so a page that is only ever a
  /// stepping stone in a redirect never spawns the view; and short next to
  /// the second or two the native map takes to draw its first tiles, so a
  /// driver landing on the home page sees no added wait he could notice.
  static const Duration defaultSettleDelay = Duration(milliseconds: 800);

  /// The platform-view widget to mount once the page has settled.
  final Widget child;

  /// What to draw until then. Defaults to a box in the theme's surface
  /// colour.
  final Widget? placeholder;

  /// How long the page must stay current after its first frame before the
  /// child is mounted.
  final Duration settleDelay;

  @override
  State<DeferredMapSurface> createState() => _DeferredMapSurfaceState();
}

class _DeferredMapSurfaceState extends State<DeferredMapSurface> {
  Timer? _timer;
  ModalRoute<Object?>? _route;
  bool _framePainted = false;
  bool _ready = false;

  bool get _isCurrent => _route?.isCurrent ?? true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _framePainted = true;
      _syncTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute.of subscribes this element to the route's status, so a
    // change of [ModalRoute.isCurrent] lands here again and the timer is
    // armed or disarmed to match.
    _route = ModalRoute.of(context);
    _syncTimer();
  }

  void _syncTimer() {
    if (_ready) return;
    if (!_framePainted || !_isCurrent) {
      _disarm();
      return;
    }
    _timer ??= Timer(widget.settleDelay, _onSettled);
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
  }

  void _onSettled() {
    _timer = null;
    if (!mounted || _ready) return;
    // Live read of the route, not the cached status: a replacement pushed
    // this very frame has already made this route non-current.
    if (!_isCurrent) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _disarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    return widget.placeholder ??
        ColoredBox(color: Theme.of(context).colorScheme.surface);
  }
}
