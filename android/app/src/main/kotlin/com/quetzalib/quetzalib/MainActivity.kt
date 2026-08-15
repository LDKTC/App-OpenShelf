package com.quetzalib.quetzalib

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Installs update APKs via the [PackageInstaller] session API (rather than
/// handing off to the system installer with a fire-and-forget ACTION_VIEW
/// intent) so the app can observe the final install outcome -- in
/// particular [PackageInstaller.STATUS_FAILURE_CONFLICT], which is what
/// Android reports when an update APK is signed with a different
/// certificate than the app already on the device, and surface that as a
/// clear in-app message instead of a silent/cryptic system dialog.
class MainActivity : FlutterActivity() {
    private val channelName = "quetzalib/apk_installer"
    private val installAction get() = "$packageName.INSTALL_RESULT"

    private var channel: MethodChannel? = null
    private var installReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("bad_args", "Missing 'path' argument", null)
                    } else {
                        try {
                            installApk(path)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("install_failed", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        registerInstallReceiver()
    }

    override fun onDestroy() {
        installReceiver?.let { unregisterReceiver(it) }
        installReceiver = null
        channel = null
        super.onDestroy()
    }

    private fun registerInstallReceiver() {
        if (installReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) = handleInstallResult(intent)
        }
        installReceiver = receiver
        val filter = IntentFilter(installAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, filter)
        }
    }

    private fun handleInstallResult(intent: Intent) {
        when (val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE,
        )) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                @Suppress("DEPRECATION")
                val confirmIntent = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                confirmIntent?.let {
                    it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(it)
                }
            }
            PackageInstaller.STATUS_SUCCESS ->
                channel?.invokeMethod("installResult", mapOf("status" to "success"))
            PackageInstaller.STATUS_FAILURE_CONFLICT ->
                channel?.invokeMethod(
                    "installResult",
                    mapOf(
                        "status" to "conflict",
                        "message" to intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE),
                    ),
                )
            else ->
                channel?.invokeMethod(
                    "installResult",
                    mapOf(
                        "status" to "failure",
                        "message" to intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE),
                    ),
                )
        }
    }

    private fun installApk(path: String) {
        val file = File(path)
        val packageInstaller = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        val sessionId = packageInstaller.createSession(params)
        packageInstaller.openSession(sessionId).use { session ->
            session.openWrite("quetzalib_update", 0, file.length()).use { out ->
                file.inputStream().use { input -> input.copyTo(out) }
                session.fsync(out)
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                sessionId,
                Intent(installAction).setPackage(packageName),
                flags,
            )
            session.commit(pendingIntent.intentSender)
        }
    }
}
