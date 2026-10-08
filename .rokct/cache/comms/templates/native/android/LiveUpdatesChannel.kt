// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
// For license information, please see license.txt
//
// SCAFFOLD, not installed by the composer yet. The Android 16 half of
// comms_sdk's DeviceLiveActivitySink: draws a LiveActivityFrame as a
// promoted Notification.ProgressStyle (segments, points, tracker icon).
//
// To wire it in a host (needs compileSdk 36 and a device or emulator on
// API 36 to verify):
//   1. Copy this file to android/app/src/main/kotlin/<package>/.
//   2. Add drawables live_tracker_car, live_tracker_scooter,
//      live_tracker_parcel and live_tracker_cap (white glyph on a 24dp
//      #FF6600 disc, design section 6c) and ic_live_small.
//   3. In MainActivity.configureFlutterEngine:
//        LiveUpdatesChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)
//   4. Add <uses-permission android:name="android.permission.POST_PROMOTED_NOTIFICATIONS"/>.
// Until then the Dart side gets MissingPluginException and falls back to
// the plain flutter_local_notifications progress bar (design 1c-ii).

package ai.rokct.comms

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class LiveUpdatesChannel(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "rokct/live_updates").setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> result.success(show(call.arguments as Map<*, *>))
                "cancel" -> {
                    val id = (call.argument<Number>("id") ?: 0).toInt()
                    manager().cancel(id)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun manager() =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** False below API 36: the Dart side then draws the plain bar. */
    private fun show(a: Map<*, *>): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        val channelId = a["channelId"] as String
        manager().createNotificationChannel(
            NotificationChannel(channelId, a["channelName"] as String,
                NotificationManager.IMPORTANCE_DEFAULT)
        )
        val state = a["state"] as String
        val terminal = state == "ended" || state == "error"
        val done = (a["colorDone"] as Number).toInt()
        val colour = when (state) {
            "ended" -> (a["colorEnded"] as Number).toInt()
            "error" -> (a["colorError"] as Number).toInt()
            else -> done
        }
        val segments = (a["segments"] as? List<*>).orEmpty()
        val progress = ((a["progress"] as? Number)?.toDouble() ?: 0.0)
        val style = Notification.ProgressStyle().setStyledByProgress(true)
        val count = segments.size.coerceAtLeast(1)
        val per = 100 / count
        repeat(count) {
            style.addProgressSegment(Notification.ProgressStyle.Segment(per).setColor(colour))
        }
        for (i in 1 until count) {
            style.addProgressPoint(Notification.ProgressStyle.Point(i * per).setColor(colour))
        }
        style.setProgress((progress * per * count).toInt())
        val tracker = a["trackerIcon"] as? String
        if (!terminal && tracker != null && tracker != "live_tracker_none") {
            val res = context.resources.getIdentifier(tracker, "drawable", context.packageName)
            if (res != 0) style.setProgressTrackerIcon(Icon.createWithResource(context, res))
        }
        val deepLink = a["deepLink"] as? String
        val tap = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply { if (deepLink != null) data = Uri.parse(deepLink) }
        val builder = Notification.Builder(context, channelId)
            .setSmallIcon(context.resources.getIdentifier("ic_live_small", "drawable", context.packageName)
                .takeIf { it != 0 } ?: context.applicationInfo.icon)
            .setContentTitle(a["title"] as String)
            .setContentText(a["subtitle"] as String)
            .setSubText(a["endLabel"] as? String)
            .setColor(colour)
            .setOnlyAlertOnce(a["alert"] != true)
            .setOngoing(a["dismissible"] != true)
            .setAutoCancel(false)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setRequestPromotedOngoing(!terminal)
        if (a["countdown"] == true && a["endsAtMs"] != null && !terminal) {
            builder.setUsesChronometer(true).setChronometerCountDown(true)
                .setWhen((a["endsAtMs"] as Number).toLong()).setShowWhen(true)
        }
        if (a["showProgress"] != false) builder.setStyle(style)
        (a["timeoutAfterMs"] as? Number)?.let { builder.setTimeoutAfter(it.toLong()) }
        if (tap != null) {
            builder.setContentIntent(PendingIntent.getActivity(context, 0, tap,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
        }
        manager().notify((a["id"] as Number).toInt(), builder.build())
        return true
    }
}
