package com.app.demo

import android.app.Activity
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import java.lang.reflect.Modifier

class MainActivity: FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Physical RAM lookup for base_sdk's MemoryPressureService.
        DeviceMemoryBridge.register(messenger, applicationContext)
        // Restore Credentials (Zero-Tap Sign-In) plumbing. Needs an Activity,
        // not the application context: the credential provider shows system UI.
        RestoreCredentialBridge.register(messenger, this)
        // Shared sign-in between same-key fleet apps (SessionHandoffBridge):
        // hands a sign-in to another fleet app, and takes one in.
        SessionHandoffBridge.register(messenger, this)
        // Bridges that only exist when the app is composed with the SDK that
        // ships them. This activity cannot reference them directly: it is
        // base_sdk's template and must still compile in an app composed
        // without them.
        registerOptionalBridges(messenger)
        registerOptionalEngineBridges(flutterEngine)
    }

    /**
     * Same as [registerOptionalBridges], for bridges that need the engine
     * itself (a platform view factory registers on the engine, not the
     * messenger): each exposes `register(FlutterEngine, Activity)`.
     */
    private fun registerOptionalEngineBridges(engine: FlutterEngine) {
        val packageName = javaClass.`package`?.name ?: return
        for (bridgeName in OPTIONAL_ENGINE_BRIDGES) {
            try {
                val bridge = Class.forName("$packageName.$bridgeName")
                val register = bridge.getMethod(
                    "register",
                    FlutterEngine::class.java,
                    Activity::class.java,
                )
                val receiver = if (Modifier.isStatic(register.modifiers)) {
                    null
                } else {
                    bridge.getField("INSTANCE").get(null)
                }
                register.invoke(receiver, engine, this)
            } catch (e: ClassNotFoundException) {
                // App composed without the SDK that ships this bridge.
            } catch (e: ReflectiveOperationException) {
                Log.e(TAG, "Optional bridge $bridgeName could not be registered", e)
            }
        }
    }

    /**
     * Registers every bridge in [OPTIONAL_BRIDGES] that is actually present in
     * this build.
     *
     * A package SDK (as opposed to a Flutter plugin) has no registration hook
     * of its own: its Kotlin lands in the host's source tree through the
     * composer's `installs` and then needs someone to call it. Only the host
     * Activity can do that, and only reflectively - a direct reference would
     * fail to compile in every app composed without that SDK.
     *
     * The package is read from this class at runtime rather than hard-coded:
     * the release lane rewrites every Kotlin source's `package` declaration to
     * the customer's application package before it compiles, so a literal
     * "com.app.demo.X" would resolve to nothing in a shipped build. Bridges
     * are installed next to this activity, so its own package is the right
     * one to look in.
     */
    private fun registerOptionalBridges(messenger: BinaryMessenger) {
        val packageName = javaClass.`package`?.name ?: return
        for (bridgeName in OPTIONAL_BRIDGES) {
            try {
                val bridge = Class.forName("$packageName.$bridgeName")
                val register = bridge.getMethod(
                    "register",
                    BinaryMessenger::class.java,
                    Activity::class.java,
                )
                // A Kotlin `object` exposes its members on the INSTANCE
                // singleton unless they are annotated @JvmStatic, so accept
                // either shape instead of dictating one to the SDKs.
                val receiver = if (Modifier.isStatic(register.modifiers)) {
                    null
                } else {
                    bridge.getField("INSTANCE").get(null)
                }
                register.invoke(receiver, messenger, this)
            } catch (e: ClassNotFoundException) {
                // App composed without the SDK that ships this bridge - nothing to register.
            } catch (e: ReflectiveOperationException) {
                // Present but not callable: a real defect in that bridge, and
                // still not worth taking the app down on the launch path.
                Log.e(TAG, "Optional bridge $bridgeName could not be registered", e)
            }
        }
    }

    private companion object {
        private const val TAG = "MainActivity"

        /**
         * Simple class names, each expected to expose
         * `register(BinaryMessenger, Activity)` and to be installed into this
         * activity's own package by its SDK's manifest `installs`.
         *
         * - DefaultHomeBridge (launch_sdk): the default-launcher role ask
         *   behind the `rokct.launch_sdk/default_home` channel.
         * - AppChangesBridge (launch_sdk): install and uninstall events
         *   behind the `rokct.launch_sdk/app_changes` channel, so the
         *   launcher is told when its app list changes instead of asking.
         */
        private val OPTIONAL_BRIDGES = listOf("DefaultHomeBridge", "AppChangesBridge")

        /**
         * Bridges registered with `register(FlutterEngine, Activity)`.
         *
         * - LauncherVerseWidgetBridge (launch_sdk): hosts the Bible app's
         *   verse widget on the launcher home. Missing from this list, it was
         *   never registered and R8 removed it, so the launcher home never
         *   showed the widget or its prompt (Ray, 2026-11-15).
         */
        private val OPTIONAL_ENGINE_BRIDGES = listOf("LauncherVerseWidgetBridge")
    }
}
