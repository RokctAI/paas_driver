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


import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// The app's orientation policy, and the claim a page makes to be excused
/// from it.
///
/// Orientation is DECLARED, never taken. The app pins portrait on phones
/// only ([shouldLockPortrait] — the single copy of that rule); a page that
/// genuinely wants to turn with the device says so by wrapping itself in a
/// [FreeRotation], and base honours the claim while that page is mounted
/// and puts the app's own policy back the moment it goes away.
///
/// The point is that a page never calls [SystemChrome] itself: ownership
/// never leaves base, so there is no restore for a page to forget and no
/// second copy of the phone/tablet rule to drift. It is the same shape as
/// the plane claim in `planes.dart` — the page declares what it needs, the
/// host arbitrates — but it deliberately rides on the widget tree rather
/// than on `PlanePage`, because the pages that need it most (radio, which
/// is the fleet's no-planes carve-out) sit outside the plane host
/// entirely.
abstract class AppOrientation {
  AppOrientation._();

  /// The phone lock: upright either way up.
  static const List<DeviceOrientation> _portrait = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  /// Every orientation the device offers — what an honoured claim grants.
  static const List<DeviceOrientation> _free = DeviceOrientation.values;

  /// The empty list means "no app-imposed preference": the platform
  /// manifest / Info.plist decides. This is exactly the state a
  /// non-locking launch leaves behind (base's boot simply does not call
  /// [SystemChrome.setPreferredOrientations] then), so restoring to it
  /// reproduces boot rather than inventing a wider policy than the app
  /// ever had.
  static const List<DeviceOrientation> _platformDefault = <DeviceOrientation>[];

  /// Live [FreeRotation] claims. Counted, not a flag: two claimants can
  /// overlap for a frame while one route replaces another, and the lock
  /// must not come back in between.
  static int _claims = 0;

  /// Whether this launch should pin the app to portrait.
  ///
  /// Only phone-sized mobile devices lock: web and desktop never do, and a
  /// mobile device whose logical shortest side reaches
  /// [AppBreakpoints.medium] (a tablet) keeps free rotation. Safe to call
  /// before `runApp` — the size comes from the platformDispatcher's views
  /// rather than a MediaQuery.
  static bool shouldLockPortrait() {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return false;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        break;
    }
    for (final view in WidgetsBinding.instance.platformDispatcher.views) {
      final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
      if (shortestSide >= AppBreakpoints.medium) return false;
    }
    return true;
  }

  /// Push the current answer to the platform: an honoured claim wins,
  /// otherwise the app's own policy.
  static Future<void> _apply() {
    if (_claims > 0) {
      return SystemChrome.setPreferredOrientations(_free);
    }
    return SystemChrome.setPreferredOrientations(
      shouldLockPortrait() ? _portrait : _platformDefault,
    );
  }

  /// Register a claim. Called by [FreeRotation]; pages do not call this
  /// directly.
  static Future<void> claimFreeRotation() {
    _claims += 1;
    return _claims == 1 ? _apply() : Future<void>.value();
  }

  /// Drop a claim, restoring the app's policy once the last one goes.
  static Future<void> releaseFreeRotation() {
    if (_claims == 0) return Future<void>.value();
    _claims -= 1;
    return _claims == 0 ? _apply() : Future<void>.value();
  }
}

/// A page's declaration that it turns with the device.
///
/// Wrap the page's subtree in one and the app's portrait lock is lifted
/// for as long as that subtree is mounted; it comes back on its own when
/// the page is popped or replaced. Nothing else is needed and nothing
/// needs undoing — see [AppOrientation].
///
/// ```dart
/// Widget build(BuildContext context) => FreeRotation(child: MyPage());
/// ```
class FreeRotation extends StatefulWidget {
  const FreeRotation({super.key, required this.child});

  /// The subtree whose lifetime the claim follows.
  final Widget child;

  @override
  State<FreeRotation> createState() => _FreeRotationState();
}

class _FreeRotationState extends State<FreeRotation> {
  @override
  void initState() {
    super.initState();
    AppOrientation.claimFreeRotation();
  }

  @override
  void dispose() {
    AppOrientation.releaseFreeRotation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
