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

// widgets.dart exports src/widgets/* only - it does NOT re-export
// services.dart - so MethodChannel and MissingPluginException need their
// own import. PaintingBinding does arrive with widgets.dart, and
// foundation is exported only with a show list, hence its separate import.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/database/app_database.dart';

/// What just happened to the app's memory situation.
enum MemoryEvent {
  /// The platform asked every app to give memory back. On Android this
  /// arrives through Flutter's `flutter/system` memoryPressure message,
  /// which the embedding sends from `Activity.onTrimMemory` — since
  /// Android 14 that is only `TRIM_MEMORY_UI_HIDDEN` and
  /// `TRIM_MEMORY_BACKGROUND`, so in practice it fires around backgrounding.
  pressure,

  /// The app left the foreground (`paused`, `hidden` or `detached`). This is
  /// the state whose Play memory budget is roughly half the foreground one,
  /// so it is the moment to drop every cache the app can rebuild.
  background,

  /// The app came back to the foreground. Handlers registered for this event
  /// re-warm whatever they released.
  resume,
}

/// A callback registered with [MemoryPressureService]. Must not throw; the
/// service catches and logs anyway so one bad handler cannot stop the rest.
typedef MemoryHandler = FutureOr<void> Function(MemoryEvent event);

/// How much bitmap memory the image cache may hold on this device.
@immutable
class ImageCacheBudget {
  const ImageCacheBudget({
    required this.maximumSizeBytes,
    required this.maximumSize,
    required this.totalPhysicalMemoryBytes,
  });

  /// Decoded-bitmap ceiling, in bytes.
  final int maximumSizeBytes;

  /// Ceiling on the number of cached images.
  final int maximumSize;

  /// Physical RAM the platform reported, or null when it could not be read
  /// (non-Android, or a shell whose native channel predates this service).
  final int? totalPhysicalMemoryBytes;

  @override
  String toString() =>
      'ImageCacheBudget(${maximumSizeBytes ~/ (1024 * 1024)}MB, '
      '$maximumSize images, ram=$totalPhysicalMemoryBytes)';
}

/// Central place for reacting to memory pressure and to backgrounding.
///
/// Nothing in the fleet reacted to either before this: Flutter's image cache
/// ran at its fixed default of 1000 images / 100MB on every device, and no
/// cache was dropped when the app went to the background. The Feb 2027 Play
/// memory thresholds are P90 anonymous RSS+swap over 28 days with the
/// background budget roughly half the foreground one, plus a hard bitmap
/// ceiling of 200MB in background — which a 100MB image cache alone puts
/// half of the app's allowance against on a 4GB device.
///
/// Other SDKs register into this rather than wiring their own lifecycle
/// observers:
///
/// ```dart
/// MemoryPressureService().registerHandler('my_sdk.tiles', (event) {
///   if (event == MemoryEvent.background) tileCache.clear();
/// });
/// ```
///
/// Safe on every platform: the native RAM lookup is the only platform call
/// and it degrades to a conservative default when the channel is absent, so
/// Windows and the other non-mobile targets are unaffected.
class MemoryPressureService with WidgetsBindingObserver {
  MemoryPressureService._();

  factory MemoryPressureService() =>
      _instance ??= MemoryPressureService._();
  static MemoryPressureService? _instance;

  /// Same channel name as the Kotlin handler in the android template's
  /// MainActivity.
  static const MethodChannel channel = MethodChannel(
    'rokct.base_sdk/device_memory',
  );

  static const int _mb = 1024 * 1024;
  static const int _gb = 1024 * 1024 * 1024;

  /// Handler keys reserved by base_sdk itself.
  static const String imageCacheHandlerKey = 'base_sdk.image_cache';
  static const String databaseHandlerKey = 'base_sdk.database';

  final Map<String, MemoryHandler> _handlers = {};

  bool _started = false;
  ImageCacheBudget? _budget;

  /// The budget applied at [start], or null before it runs.
  ImageCacheBudget? get budget => _budget;

  /// Whether [start] has run.
  bool get isStarted => _started;

  /// Size the image cache from device RAM and begin listening for memory
  /// pressure and lifecycle changes. Idempotent: calling it again returns
  /// the budget already in force without re-reading anything.
  ///
  /// Call once during boot, after `WidgetsFlutterBinding.ensureInitialized()`.
  /// [totalPhysicalMemoryBytesOverride] is for tests and for callers that
  /// already know the device's RAM.
  Future<ImageCacheBudget> start({
    int? totalPhysicalMemoryBytesOverride,
  }) async {
    if (_started) return _budget!;
    _started = true;

    final totalRam =
        totalPhysicalMemoryBytesOverride ?? await readTotalPhysicalMemory();
    final budget = budgetFor(totalRam);
    _budget = budget;

    // Guarded end to end: this runs during bootstrap, and a memory
    // optimisation must never be what stops an app from starting. Worst case
    // the fleet keeps Flutter's defaults, which is where it is today.
    try {
      applyBudget(budget);
      registerHandler(imageCacheHandlerKey, _releaseImageCache);
      registerHandler(databaseHandlerKey, _releaseDatabase);
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('==> memory pressure service could not attach: $e');
    }
    return budget;
  }

  /// Stop observing and forget every registered handler. Mainly for tests
  /// and hot restart; app code has no reason to call it.
  void stop() {
    if (!_started) return;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {
      // No binding (a plain unit test); nothing was attached either.
    }
    _handlers.clear();
    _started = false;
    _budget = null;
  }

  /// Register [handler] under [key]. Re-registering the same key replaces
  /// the previous handler, which makes this hot-restart safe.
  void registerHandler(String key, MemoryHandler handler) {
    _handlers[key] = handler;
  }

  /// Drop the handler registered under [key]. Returns whether one was there.
  bool unregisterHandler(String key) => _handlers.remove(key) != null;

  /// Run every registered handler for [event], in registration order. One
  /// handler throwing never stops the others.
  Future<void> notify(MemoryEvent event) async {
    for (final entry in _handlers.entries.toList()) {
      try {
        await entry.value(event);
      } catch (e) {
        debugPrint('==> memory handler ${entry.key} failed on $event: $e');
      }
    }
  }

  /// Physical RAM in bytes, or null when it cannot be read.
  ///
  /// Reads `ActivityManager.MemoryInfo.totalMem` through the android
  /// template's method channel. Returns null — never throws — on every other
  /// platform, and on an Android shell whose MainActivity has not taken the
  /// template update that registers the handler.
  Future<int?> readTotalPhysicalMemory() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final value = await channel.invokeMethod<int>(
        'totalPhysicalMemoryBytes',
      );
      if (value == null || value <= 0) return null;
      return value;
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('==> device memory lookup failed: $e');
      return null;
    }
  }

  /// The image cache budget for a device with [totalPhysicalMemoryBytes] of
  /// RAM. Pure and total, so it can be tested without a binding.
  ///
  /// Tiers follow the RAM tiers in Play's memory thresholds (4GB / 6GB / 8GB
  /// devices). `ActivityManager` reports rather less than the nominal figure
  /// — a "4GB" phone reports around 3.7GB — so each boundary sits below its
  /// nominal value. Every tier is at or under Flutter's fixed 100MB default,
  /// so this can only ever lower the ceiling, never raise it: the cost of a
  /// miss is a re-decode, not a correctness change.
  static ImageCacheBudget budgetFor(int? totalPhysicalMemoryBytes) {
    final ram = totalPhysicalMemoryBytes;
    if (ram == null || ram <= 0) {
      // Unknown device: assume the smallest tier we actively support.
      return ImageCacheBudget(
        maximumSizeBytes: 48 * _mb,
        maximumSize: 300,
        totalPhysicalMemoryBytes: ram,
      );
    }
    if (ram < 3 * _gb) {
      // Under 3GB: below every tier Play's thresholds name.
      return ImageCacheBudget(
        maximumSizeBytes: 32 * _mb,
        maximumSize: 200,
        totalPhysicalMemoryBytes: ram,
      );
    }
    if (ram < 4 * _gb + _gb ~/ 2) {
      // Under 4.5GB: the ~4GB class.
      return ImageCacheBudget(
        maximumSizeBytes: 48 * _mb,
        maximumSize: 300,
        totalPhysicalMemoryBytes: ram,
      );
    }
    if (ram < 7 * _gb) {
      // Under 7GB: the ~6GB class.
      return ImageCacheBudget(
        maximumSizeBytes: 72 * _mb,
        maximumSize: 400,
        totalPhysicalMemoryBytes: ram,
      );
    }
    // 8GB and above.
    return ImageCacheBudget(
      maximumSizeBytes: 96 * _mb,
      maximumSize: 500,
      totalPhysicalMemoryBytes: ram,
    );
  }

  /// Apply [budget] to Flutter's image cache. Separate from [start] so a
  /// host can re-apply it after its own tuning.
  void applyBudget(ImageCacheBudget budget) {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = budget.maximumSizeBytes;
    cache.maximumSize = budget.maximumSize;
  }

  @override
  void didHaveMemoryPressure() {
    unawaited(notify(MemoryEvent.pressure));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(notify(MemoryEvent.background));
      case AppLifecycleState.resumed:
        unawaited(notify(MemoryEvent.resume));
      case AppLifecycleState.inactive:
        // A transient state (a system dialog, the app switcher opening).
        // Dropping caches here would thrash.
        break;
    }
  }

  void _releaseImageCache(MemoryEvent event) {
    if (event == MemoryEvent.resume) return;
    final cache = PaintingBinding.instance.imageCache;
    // clear() drops the pending/decoded cache; clearLiveImages() additionally
    // releases images still referenced by a live ImageStream, which is the
    // half that keeps holding bitmaps once the UI is hidden.
    cache.clear();
    cache.clearLiveImages();
  }

  Future<void> _releaseDatabase(MemoryEvent event) async {
    if (event == MemoryEvent.resume) return;
    // Deliberately NOT close(). See the class docs on AppDatabase.
    await AppDatabase().releaseMemory();
  }
}
