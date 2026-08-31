package com.app.demo

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // Physical RAM lookup for base_sdk's MemoryPressureService.
        DeviceMemoryBridge.register(messenger, applicationContext)
        // Restore Credentials (Zero-Tap Sign-In) plumbing. Needs an Activity,
        // not the application context: the credential provider shows system UI.
        RestoreCredentialBridge.register(messenger, this)
    }
}
