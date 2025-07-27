package com.nativemind.vpnClient.vpn_client

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // GeneratedPluginRegistrant.registerWith(flutterEngine) is called automatically by FlutterFragmentActivity.
        // Calling it manually here causes plugins to be registered twice, causing the warning.

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "v2ray_notification_channel"
            val channelName = "V2Ray VPN Service"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(channelId, channelName, importance)
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
