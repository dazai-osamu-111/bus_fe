package com.example.bus_management

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log 

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bus_management/momo"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestPayment") {
                val deeplink = call.argument<String>("deeplink")

                if (deeplink != null) {
                    requestPayment(deeplink)
                    result.success("Payment requested")
                } else {
                    result.error("INVALID_ARGUMENT", "One or more arguments are null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun requestPayment(deeplink: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deeplink))
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
            // Handle exception (e.g., show an error message)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action: String? = intent.action
        val data: Uri? = intent.data

        if (Intent.ACTION_VIEW == action && data != null) {
            val orderId = data.getQueryParameter("orderId")
            if (orderId != null) {
                Log.d("MainActivity", "Payment callback received: orderId = $orderId")
                MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onPaymentCallback", orderId)
            }
        }
    }
}
