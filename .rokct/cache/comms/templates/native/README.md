# Live activity native pieces (scaffold)

comms_sdk's `DeviceLiveActivitySink` draws base_sdk `LiveActivities` frames.
The Dart side works without anything here: Android falls back to a plain
progress notification, and iOS is skipped. These files add the full design
(sections 1c-i, 1c-iii and 1c-iv). The composer does not install them yet.
Each one needs a native build to verify.

## Android 16 ProgressStyle (`android/LiveUpdatesChannel.kt`)

Needs compileSdk 36 and an API 36 device or emulator. The steps are in the
file header. Below API 36 the channel answers `false`, and the sink draws
the plain bar.

## iOS Live Activity (`ios/LiveActivityWidget/`)

This part needs Xcode:

1. File > New > Target > Widget Extension named `LiveActivityWidget`, with
   "Include Live Activity" ticked. Replace the generated Swift with
   `LiveActivityWidget.swift`.
2. Add the same App Group (e.g. `group.<bundle id>.live`) to the Runner and
   to the extension. Set `appGroup` in the Swift file to it, and build with
   `--dart-define=LIVE_ACTIVITY_APP_GROUP=<the group>`.
3. Runner `Info.plist`: `NSSupportsLiveActivities` = YES. For backend push
   later, also add `NSSupportsLiveActivitiesFrequentUpdates`.
4. Extension deployment target iOS 16.1. The Runner can stay lower, because
   the plugin checks availability.
5. Optional: add the `live_tracker_*` images to the extension's asset
   catalog, and swap the SF Symbols in `Snapshot.symbol` for them.

Without backend pushes (APNs Live Activity and FCM data), updates stop while
the app is suspended. The controller then marks the entry stale after
10 minutes, and iOS dims it through `staleIn`.
