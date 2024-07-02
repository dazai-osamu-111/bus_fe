package com.example.bus_management

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import vn.momo.momo_partner.AppMoMoLib
import vn.momo.momo_partner.MoMoParameterNameMap

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bus_management/momo"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestPayment") {
                val amount = call.argument<String>("amount")
                val merchantName = call.argument<String>("merchantName")
                val merchantCode = call.argument<String>("merchantCode")
                val description = call.argument<String>("description")
                val deeplink = call.argument<String>("deeplink")

                if (amount != null && merchantName != null && merchantCode != null && description != null && deeplink != null) {
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == AppMoMoLib.getInstance().REQUEST_CODE_MOMO && resultCode == -1) {
            if (data != null) {
                val status = data.getIntExtra("status", -1)
                if (status == 0) {
                    // TOKEN IS AVAILABLE
                    val token = data.getStringExtra("data")
                    val phoneNumber = data.getStringExtra("phonenumber")
                    val env = data.getStringExtra("env") ?: "app"

                    if (!token.isNullOrEmpty()) {
                        // TODO: send phoneNumber & token to your server side to process payment with MoMo server
                    } else {
                        // Handle error
                    }
                } else {
                    val message = data.getStringExtra("message") ?: "Thất bại"
                    // Handle error
                }
            } else {
                // Handle error
            }
        }
    }
}
