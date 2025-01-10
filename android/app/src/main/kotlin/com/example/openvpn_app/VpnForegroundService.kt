package com.example.openvpn_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class VpnForegroundService : Service() {

    private lateinit var channel: MethodChannel
    private lateinit var flutterEngine: FlutterEngine

    companion object {
        const val CHANNEL_ID = "VpnForegroundServiceChannel"
    }

    override fun onCreate() {
        super.onCreate()

        // Initialize FlutterEngine
        flutterEngine = FlutterEngine(applicationContext).apply {
            dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }

        // Set up MethodChannel
        channel = MethodChannel(flutterEngine.dartExecutor, "com.example.app/vpn")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpnService" -> startVpnService(result)
                "stopVpnService" -> stopVpnService(result)
                else -> result.notImplemented()
            }
        }

        // Create a notification channel and set up the foreground notification
        createNotificationChannel()
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("VPN Service")
            .setContentText("VPN is running in the background")
            .setSmallIcon(android.R.drawable.ic_lock_lock) // Replace with your custom app icon
            .build()
        startForeground(1, notification)

        println("VpnForegroundService created.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        println("VpnForegroundService started.")
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    // Start VPN service logic
    private fun startVpnService(result: MethodChannel.Result) {
        println("VPN Service Started")
        // Add actual VPN start logic here
        result.success("VPN Started Successfully")
    }

    // Stop VPN service logic
    private fun stopVpnService(result: MethodChannel.Result? = null) {
        println("VPN Service Stopped")
        // Add actual VPN stop logic here
        result?.success("VPN Stopped Successfully")
    }

    // Separate logic for stopping VPN without requiring a Result object
    private fun stopVpnServiceLogic() {
        println("Executing VPN stop logic...")
        // Add actual VPN stop logic here
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        println("App terminated: stopping VPN...")
        stopVpnServiceLogic() // Ensure VPN is stopped when the app is terminated
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        println("VpnForegroundService destroyed.")
        stopVpnServiceLogic() // Ensure VPN is stopped
        channel.setMethodCallHandler(null) // Clean up MethodChannel
        flutterEngine.destroy() // Destroy FlutterEngine
        super.onDestroy()
    }

    // Create a notification channel for the foreground service (required for Android 8.0 and above)
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service Channel",
                android.app.NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(android.app.NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }
}
