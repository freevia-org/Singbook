package org.freevia.singbook

import android.webkit.CookieManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            YOUTUBE_MUSIC_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.arguments != null) {
                result.error("invalid_arguments", "This method does not accept arguments", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "getConsentCookies" -> result.success(readConsentCookies())
                "clearConsentCookies" -> clearConsentCookies(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun readConsentCookies(): Map<String, String> {
        val raw = CookieManager.getInstance().getCookie(YOUTUBE_MUSIC_URL) ?: return emptyMap()
        val allowed = setOf("SOCS", "CONSENT")
        val cookies = mutableMapOf<String, String>()
        raw.split(';').forEach { item ->
            val separator = item.indexOf('=')
            if (separator > 0) {
                val name = item.substring(0, separator).trim()
                if (name in allowed) {
                    cookies[name] = item.substring(separator + 1).trim()
                }
            }
        }
        return cookies
    }

    private fun clearConsentCookies(result: MethodChannel.Result) {
        // Expire only the two consent names, for host-only and applicable domain cookies.
        // CookieManager exposes no per-cookie deletion API.
        val expirations = listOf(
            "https://music.youtube.com" to "SOCS=; Max-Age=0; Path=/; Secure",
            "https://music.youtube.com" to "CONSENT=; Max-Age=0; Path=/; Secure",
            "https://music.youtube.com" to "SOCS=; Max-Age=0; Path=/; Domain=.youtube.com; Secure",
            "https://music.youtube.com" to "CONSENT=; Max-Age=0; Path=/; Domain=.youtube.com; Secure",
            "https://music.youtube.com" to "SOCS=; Max-Age=0; Path=/; Domain=music.youtube.com; Secure",
            "https://music.youtube.com" to "CONSENT=; Max-Age=0; Path=/; Domain=music.youtube.com; Secure"
        )
        val manager = CookieManager.getInstance()
        var remaining = expirations.size
        var succeeded = true
        expirations.forEach { (url, cookie) ->
            manager.setCookie(url, cookie) { accepted ->
                runOnUiThread {
                    succeeded = succeeded && accepted
                    remaining -= 1
                    if (remaining == 0) {
                        manager.flush()
                        if (succeeded && readConsentCookies().isEmpty()) {
                            result.success(null)
                        } else {
                            result.error("cookie_clear_failed", "Could not clear consent cookies", null)
                        }
                    }
                }
            }
        }
    }

    private companion object {
        const val YOUTUBE_MUSIC_CHANNEL = "org.freevia.singbook/youtube_music_session"
        const val YOUTUBE_MUSIC_URL = "https://music.youtube.com/"
    }
}
