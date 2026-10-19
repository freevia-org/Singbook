package org.freevia.singbook

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.accounts.Account
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.auth.api.identity.AuthorizationResult
import com.google.android.gms.auth.api.identity.ClearTokenRequest
import com.google.android.gms.common.api.Scope
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var clipboardWriteReceipt: Map<String, Any?>? = null
    private var drivePickerResult: MethodChannel.Result? = null
    private var drivePickerFolderMode = true
    private var drivePickerExpectedEmail: String? = null
    private val drivePickerRequestCode = 41827
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "org.freevia.singbook/rich_clipboard"
        ).setMethodCallHandler { call, result ->
            if (call.method == "pickVisibleDriveFolder" ||
                call.method == "pickChordProFiles") {
                if (drivePickerResult != null) {
                    result.error("picker_busy", "A Drive picker is already open", null)
                    return@setMethodCallHandler
                }
                val expectedEmail = call.argument<String>("accountEmail")?.trim()
                if (expectedEmail.isNullOrBlank()) {
                    result.error("account_mismatch", "Reconnect the selected Google account", null)
                    return@setMethodCallHandler
                }
                drivePickerResult = result
                drivePickerFolderMode = call.method == "pickVisibleDriveFolder"
                drivePickerExpectedEmail = expectedEmail
                val builder = AuthorizationRequest.Builder()
                    .setAccount(Account(expectedEmail, "com.google"))
                    .setRequestedScopes(listOf(Scope(DRIVE_FILE_SCOPE)))
                    .setOptOutIncludingGrantedScopes(true)
                    .setPrompt(AuthorizationRequest.Prompt.CONSENT)
                    .addResourceParameter(
                        AuthorizationRequest.ResourceParameter.PICKER_OAUTH_TRIGGER,
                        "true"
                    )
                if (drivePickerFolderMode) {
                    builder.addResourceParameter(
                        AuthorizationRequest.ResourceParameter.PICKER_ALLOW_FOLDER_SELECTION,
                        "true"
                    )
                } else {
                    builder.addResourceParameter(
                        AuthorizationRequest.ResourceParameter.PICKER_ALLOW_MULTIPLE,
                        "true"
                    )
                }
                val request = builder.build()
                Identity.getAuthorizationClient(this).authorize(request)
                    .addOnSuccessListener { authorization ->
                        if (authorization.hasResolution()) {
                            try {
                                startIntentSenderForResult(
                                    authorization.pendingIntent!!.intentSender,
                                    drivePickerRequestCode,
                                    null,
                                    0,
                                    0,
                                    0
                                )
                            } catch (error: Exception) {
                                finishDrivePickerError("picker_unavailable", error.message)
                            }
                        } else {
                            finishDrivePicker(authorization)
                        }
                    }
                    .addOnFailureListener { error ->
                        finishDrivePickerError("picker_unavailable", error.message)
                    }
                return@setMethodCallHandler
            }
            if (call.method == "driveFileAccessToken") {
                val expected = call.argument<String>("accountEmail")?.trim()
                if (expected.isNullOrBlank()) {
                    result.error("account_mismatch", "Reconnect the selected Google account", null)
                    return@setMethodCallHandler
                }
                requestDriveFileToken(
                    expected,
                    call.argument<Boolean>("forceRefresh") == true,
                    result
                )
                return@setMethodCallHandler
            }
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

    private fun requestDriveFileToken(
        expectedEmail: String,
        forceRefresh: Boolean,
        result: MethodChannel.Result
    ) {
        val request = AuthorizationRequest.Builder()
            .setAccount(Account(expectedEmail, "com.google"))
            .setRequestedScopes(listOf(Scope(DRIVE_FILE_SCOPE)))
            .setOptOutIncludingGrantedScopes(true)
            .build()
        val client = Identity.getAuthorizationClient(this)
        client.authorize(request)
            .addOnSuccessListener { authorization ->
                val actual = authorization.toGoogleSignInAccount()?.email?.trim()
                val token = authorization.accessToken
                when {
                    authorization.hasResolution() -> result.error(
                        "authorization_required", "Reconnect Google Drive to continue", null
                    )
                    actual.isNullOrBlank() ||
                        !expectedEmail.equals(actual, ignoreCase = true) -> result.error(
                        "account_mismatch", "Reconnect the selected Google account", null
                    )
                    token.isNullOrBlank() -> result.error(
                        "authorization_required", "Reconnect Google Drive to continue", null
                    )
                    forceRefresh -> client.clearToken(
                        ClearTokenRequest.builder().setToken(token).build()
                    ).addOnSuccessListener {
                        // Cache eviction is complete before requesting once more.
                        // This does not revoke the grant or launch consent UI.
                        requestDriveFileToken(expectedEmail, false, result)
                    }.addOnFailureListener { error ->
                        result.error("drive_authorization_failed", error.message, null)
                    }
                    else -> result.success(token)
                }
            }
            .addOnFailureListener { error ->
                result.error("drive_authorization_failed", error.message, null)
            }
    }

    @Deprecated("Deprecated in Android, kept for Google AuthorizationClient resolution results")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != drivePickerRequestCode) return
        if (resultCode != RESULT_OK || data == null) {
            finishDrivePickerError("cancelled", "Drive folder selection was cancelled")
            return
        }
        try {
            finishDrivePicker(
                Identity.getAuthorizationClient(this).getAuthorizationResultFromIntent(data)
            )
        } catch (error: Exception) {
            finishDrivePickerError("picker_failed", error.message)
        }
    }

    private fun finishDrivePicker(authorization: AuthorizationResult) {
        val expectedEmail = drivePickerExpectedEmail
        val actualEmail = authorization.toGoogleSignInAccount()?.email?.trim()
        if (expectedEmail.isNullOrBlank() || actualEmail.isNullOrBlank() ||
            !expectedEmail.equals(actualEmail, ignoreCase = true)) {
            finishDrivePickerError("account_mismatch", "Select the Google account connected to Singbook")
            return
        }
        val ids = authorization.tokenResponseParams?.getString("picked_file_ids")
            ?.split(',')?.filter { it.isNotBlank() } ?: emptyList()
        val token = authorization.accessToken
        if (ids.isEmpty() || token.isNullOrBlank()) {
            finishDrivePickerError("nothing_selected", "No Drive items were selected")
            return
        }
        if (drivePickerFolderMode && ids.size != 1) {
            finishDrivePickerError("folder_not_selected", "Select one Drive folder")
            return
        }
        drivePickerResult?.success(
            if (drivePickerFolderMode) mapOf("folderId" to ids.single())
            else mapOf("fileIds" to ids)
        )
        drivePickerResult = null
        drivePickerExpectedEmail = null
    }

    private fun finishDrivePickerError(code: String, message: String?) {
        drivePickerResult?.error(code, message ?: "Google Drive authorization failed", null)
        drivePickerResult = null
        drivePickerExpectedEmail = null
    }

    companion object {
        private const val DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file"
    }
}
