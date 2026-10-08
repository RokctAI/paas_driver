// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
// For license information, please see license.txt
//
// SCAFFOLD for the iOS half of comms_sdk's DeviceLiveActivitySink. Needs
// Xcode to wire; see ../README.md. Draws design sections 1c-iii (lock
// screen) and 1c-iv (Dynamic Island) from the flat map the Dart sink
// writes into the shared app group (LiveActivitySnapshot.toMap()).

import ActivityKit
import SwiftUI
import WidgetKit

// Must match the live_activities plugin's attributes type exactly.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState
  public struct ContentState: Codable, Hashable {}
  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

// Set to the same value as --dart-define=LIVE_ACTIVITY_APP_GROUP.
private let appGroup = "group.REPLACE_ME.live"
private let shared = UserDefaults(suiteName: appGroup)!

private enum LiveColor {
  static let done = Color(red: 1.0, green: 0.4, blue: 0.0)          // #FF6600
  static let todo = Color(red: 0.29, green: 0.29, blue: 0.32)       // #4A4B52
  static let time = Color(red: 1.0, green: 0.54, blue: 0.24)        // #FF8A3D
  static let ended = Color(red: 0.055, green: 0.624, blue: 0.431)   // #0E9F6E
  static let error = Color(red: 1.0, green: 0.239, blue: 0.0)       // #FF3D00
}

private struct Snapshot {
  let title, subtitle, endLabel, state, tracker, kind: String
  let progress: Double
  let segments: [String]
  let endsAt: Date?
  let countdown: Bool
  let deepLink: URL?

  init(_ ctx: ActivityViewContext<LiveActivitiesAppAttributes>) {
    let a = ctx.attributes
    func s(_ k: String) -> String { shared.string(forKey: a.prefixedKey(k)) ?? "" }
    title = s("title"); subtitle = s("subtitle"); endLabel = s("endLabel")
    state = s("state"); tracker = s("trackerIcon"); kind = s("kind")
    progress = shared.double(forKey: a.prefixedKey("progress"))
    segments = shared.stringArray(forKey: a.prefixedKey("segments")) ?? []
    let ms = shared.double(forKey: a.prefixedKey("endsAtMs"))
    endsAt = ms > 0 ? Date(timeIntervalSince1970: ms / 1000) : nil
    countdown = shared.bool(forKey: a.prefixedKey("countdown"))
    deepLink = URL(string: s("deepLink"))
  }

  var colour: Color {
    state == "ended" ? LiveColor.ended : state == "error" ? LiveColor.error : LiveColor.done
  }
  var terminal: Bool { state == "ended" || state == "error" }

  // SF Symbols stand in for the shared tracker assets until the asset
  // catalog carries live_tracker_*.
  var symbol: String {
    switch tracker {
    case "live_tracker_car": return "car.fill"
    case "live_tracker_scooter": return "scooter"
    case "live_tracker_parcel": return "shippingbox.fill"
    case "live_tracker_cap": return "graduationcap.fill"
    default: return "circle.fill"
    }
  }
}

private struct EndTime: View {
  let snap: Snapshot
  var body: some View {
    if snap.countdown, let end = snap.endsAt, !snap.terminal {
      Text(timerInterval: Date()...max(Date(), end), countsDown: true)
        .monospacedDigit().foregroundColor(LiveColor.time)
    } else {
      Text(snap.endLabel).foregroundColor(LiveColor.time)
    }
  }
}

private struct TrackerBar: View {
  let snap: Snapshot
  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      ZStack(alignment: .leading) {
        Capsule().fill(LiveColor.todo).frame(height: 4)
        Capsule().fill(snap.colour).frame(width: w * snap.progress, height: 4)
        ForEach(Array(snap.segments.indices.dropFirst()), id: \.self) { i in
          let x = w * Double(i) / Double(snap.segments.count)
          Circle().fill(x <= w * snap.progress ? snap.colour : LiveColor.todo)
            .frame(width: 8, height: 8).offset(x: x - 4)
        }
        if !snap.terminal && !snap.segments.isEmpty {
          Image(systemName: snap.symbol).font(.system(size: 11)).foregroundColor(.white)
            .frame(width: 24, height: 24).background(Circle().fill(LiveColor.done))
            .offset(x: max(0, w * snap.progress - 12))
        }
      }
    }.frame(height: 24)
  }
}

struct LiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { ctx in
      let snap = Snapshot(ctx)
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 10) {
          Image(systemName: snap.symbol).foregroundColor(.white)
            .frame(width: 34, height: 34).background(RoundedRectangle(cornerRadius: 9).fill(LiveColor.done))
          VStack(alignment: .leading) {
            Text(snap.title).font(.headline).foregroundColor(snap.terminal ? snap.colour : .white)
            Text(snap.subtitle).font(.caption).foregroundColor(.gray).lineLimit(1)
          }
          Spacer()
          EndTime(snap: snap).font(.title2.weight(.semibold))
        }
        if snap.kind != "classCountdown" { TrackerBar(snap: snap) }
      }
      .padding(16)
      .activityBackgroundTint(Color.black.opacity(0.86))
      .widgetURL(snap.deepLink)
    } dynamicIsland: { ctx in
      let snap = Snapshot(ctx)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: snap.symbol).foregroundColor(LiveColor.done)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading) {
            Text(snap.title).font(.headline)
            Text(snap.subtitle).font(.caption).foregroundColor(.gray).lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.trailing) { EndTime(snap: snap).font(.title3) }
        DynamicIslandExpandedRegion(.bottom) {
          if snap.kind != "classCountdown" { TrackerBar(snap: snap) }
        }
      } compactLeading: {
        Image(systemName: snap.symbol).foregroundColor(LiveColor.done)
      } compactTrailing: {
        EndTime(snap: snap).font(.caption.weight(.semibold))
      } minimal: {
        Image(systemName: snap.symbol).foregroundColor(LiveColor.done)
      }
      .widgetURL(snap.deepLink)
    }
  }
}

@main
struct LiveActivityWidgetBundle: WidgetBundle {
  var body: some Widget { LiveActivityWidget() }
}
