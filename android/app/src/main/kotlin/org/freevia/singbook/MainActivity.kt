package org.freevia.singbook

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var clipboardWriteReceipt: Map<String, Any?>? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "org.freevia.singbook/rich_clipboard"
        ).setMethodCallHandler { call, result ->
            if (call.method == "debugWriteReceipt" &&
                (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                result.success(clipboardWriteReceipt)
                return@setMethodCallHandler
            }
            // Native integration assertion; release builds expose only writes.
            if (call.method == "debugMimeTypes" &&
                (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val description = clipboard.primaryClipDescription
                result.success(if (description == null) emptyList<String>() else
                    (0 until description.mimeTypeCount).map { description.getMimeType(it) })
                return@setMethodCallHandler
            }
            if (call.method != "setHtmlText") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val text = call.argument<String>("text")
            val html = call.argument<String>("html")
            val label = call.argument<String>("label") ?: ""
            if (text == null || html == null) {
                result.error("invalid_arguments", "Text and HTML are required", null)
                return@setMethodCallHandler
            }
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData(
                label,
                arrayOf(ClipDescription.MIMETYPE_TEXT_PLAIN, ClipDescription.MIMETYPE_TEXT_HTML),
                ClipData.Item(text, html)
            )
            clipboard.setPrimaryClip(clip)
            if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                val stored = clipboard.primaryClip
                clipboardWriteReceipt = mapOf(
                    "declaredTypes" to (0 until clip.description.mimeTypeCount).map { clip.description.getMimeType(it) },
                    "declaredHtmlPresent" to (clip.getItemAt(0).htmlText != null),
                    "storedTypes" to stored?.description?.let { d -> (0 until d.mimeTypeCount).map { d.getMimeType(it) } },
                    "htmlPresent" to (stored?.getItemAt(0)?.htmlText != null),
                    "hostClipboardReplacement" to (stored?.description?.label?.toString() == "host clipboard"),
                    "storedLabelMatches" to (stored?.description?.label?.toString() == label),
                    "storedTextMatches" to (stored?.getItemAt(0)?.text?.toString() == text)
                )
            }
            result.success(null)
        }
    }
}
