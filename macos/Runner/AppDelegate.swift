import Cocoa
import FlutterMacOS
import AuthenticationServices
import Security

@main
class AppDelegate: FlutterAppDelegate {
  private var iCloudSyncChannel: ICloudSyncChannel?
  private var oauthBrowserChannel: FlutterMethodChannel?
  private var secureCredentialsChannel: FlutterMethodChannel?
  private var authorizationSession: ASWebAuthenticationSession?
  private var authorizationResult: FlutterResult?
  private var authorizationGeneration: UUID?
  private var activationObserver: NSObjectProtocol?
  private var confirmedClose = false
  private static let credentialService = "org.freevia.singbook.drive"

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // FlutterAppDelegate implements willFinishLaunching, not this optional
    // NSApplicationDelegate callback. Calling super here sends an unsupported
    // Objective-C selector and aborts normal startup with an AppKit exception.
    installNativeChannelsIfAvailable()
    activationObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.installNativeChannelsIfAvailable() }
  }

  private func installNativeChannelsIfAvailable() {
    guard oauthBrowserChannel == nil else { return }
    // MainFlutterWindow installs the Flutter controller before the app finishes
    // launching. Keep the channels on its engine so Google Sign-In plugin events
    // continue to use the normal macOS app delegate delivery path.
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      installNativeChannels(messenger: controller.engine.binaryMessenger)
    }
  }

  func installNativeChannels(messenger: FlutterBinaryMessenger) {
    iCloudSyncChannel = ICloudSyncChannel(messenger: messenger)
    let oauthChannel = FlutterMethodChannel(
      name: "org.freevia.singbook/oauth_browser",
      binaryMessenger: messenger
    )
    oauthBrowserChannel = oauthChannel
    oauthChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "authorization_failed", message: "Authorization is unavailable", details: nil))
        return
      }
      switch call.method {
      case "authorize": self.authorize(call.arguments, result: result)
      case "cancel": self.cancelAuthorization(); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }

    let credentialsChannel = FlutterMethodChannel(
      name: "org.freevia.singbook/secure_credentials",
      binaryMessenger: messenger
    )
    secureCredentialsChannel = credentialsChannel
    credentialsChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "secure_storage_error", message: "Credential storage is unavailable", details: nil))
        return
      }
      self.handleCredentialCall(call, result: result)
    }
  }

  private func authorize(_ arguments: Any?, result: @escaping FlutterResult) {
    guard authorizationSession == nil else {
      result(FlutterError(code: "busy", message: "Authorization is already in progress", details: nil))
      return
    }
    guard
      let values = arguments as? [String: Any],
      let rawURL = values["url"] as? String,
      let url = URL(string: rawURL),
      let callbackScheme = values["callbackScheme"] as? String,
      !callbackScheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      isConfiguredCallbackScheme(callbackScheme)
    else {
      result(FlutterError(code: "not_configured", message: "Authorization callback scheme is not configured", details: nil))
      return
    }
    guard
      url.scheme?.lowercased() == "https",
      url.host?.lowercased() == "accounts.google.com",
      url.path == "/o/oauth2/v2/auth",
      url.user == nil, url.password == nil, url.port == nil, url.fragment == nil
    else {
      result(FlutterError(code: "authorization_failed", message: "Invalid authorization request", details: nil))
      return
    }

    let generation = UUID()
    authorizationGeneration = generation
    authorizationResult = result
    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
      DispatchQueue.main.async {
        guard let self, self.authorizationGeneration == generation else { return }
        let pendingResult = self.authorizationResult
        self.authorizationGeneration = nil
        self.authorizationResult = nil
        self.authorizationSession = nil
        if let callbackURL {
          pendingResult?(callbackURL.absoluteString)
        } else if let sessionError = error as? ASWebAuthenticationSessionError,
                  sessionError.code == .canceledLogin {
          pendingResult?(FlutterError(code: "cancelled", message: "Authorization was cancelled", details: nil))
        } else {
          pendingResult?(FlutterError(code: "authorization_failed", message: "Authorization failed", details: nil))
        }
      }
    }
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = false
    authorizationSession = session
    if !session.start() {
      authorizationSession = nil
      authorizationGeneration = nil
      authorizationResult = nil
      result(FlutterError(code: "authorization_failed", message: "Could not start authorization", details: nil))
    }
  }

  private func cancelAuthorization() {
    guard let session = authorizationSession else { return }
    authorizationSession = nil
    authorizationGeneration = nil
    let result = authorizationResult
    authorizationResult = nil
    session.cancel()
    result?(FlutterError(code: "cancelled", message: "Authorization was cancelled", details: nil))
  }

  private func isConfiguredCallbackScheme(_ scheme: String) -> Bool {
    guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else { return false }
    return urlTypes.contains { entry in
      guard let schemes = entry["CFBundleURLSchemes"] as? [String] else { return false }
      return schemes.contains { $0.caseInsensitiveCompare(scheme) == .orderedSame }
    }
  }

  private func handleCredentialCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let values = call.arguments as? [String: Any],
      let key = values["key"] as? String,
      !key.isEmpty, !key.contains("\0"), key.utf8.count <= 1024
    else {
      result(FlutterError(code: "secure_storage_error", message: "Invalid credential key", details: nil))
      return
    }
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: Self.credentialService,
      kSecAttrAccount as String: key,
      // macOS Keychain items do not sync unless explicitly requested. This
      // retains the device-local behavior of the iOS device-only item.
      kSecAttrSynchronizable as String: kCFBooleanFalse as Any,
    ]
    switch call.method {
    case "read":
      query[kSecReturnData as String] = true
      query[kSecMatchLimit as String] = kSecMatchLimitOne
      var item: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &item)
      if status == errSecItemNotFound { result(nil) }
      else if status == errSecSuccess, let data = item as? Data, let value = String(data: data, encoding: .utf8) { result(value) }
      else { result(FlutterError(code: "secure_storage_error", message: "Could not read credential", details: nil)) }
    case "write":
      guard let value = values["value"] as? String, let data = value.data(using: .utf8) else {
        result(FlutterError(code: "secure_storage_error", message: "Invalid credential value", details: nil)); return
      }
      let update: [String: Any] = [kSecValueData as String: data]
      let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
      if status == errSecItemNotFound {
        query[kSecValueData as String] = data
        result(SecItemAdd(query as CFDictionary, nil) == errSecSuccess ? nil : FlutterError(
          code: "secure_storage_error", message: "Could not write credential", details: nil
        ))
      } else if status == errSecSuccess { result(nil) }
      else { result(FlutterError(code: "secure_storage_error", message: "Could not write credential", details: nil)) }
    case "delete":
      let status = SecItemDelete(query as CFDictionary)
      if status == errSecSuccess || status == errSecItemNotFound { result(nil) }
      else { result(FlutterError(code: "secure_storage_error", message: "Could not delete credential", details: nil)) }
    default: result(FlutterMethodNotImplemented)
    }
  }

  func terminateAfterConfirmedClose() {
    confirmedClose = true
    NSApp.terminate(nil)
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    confirmedClose ? .terminateNow : super.applicationShouldTerminate(sender)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}

extension AppDelegate: ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    mainFlutterWindow ?? NSApp.mainWindow ?? NSWindow()
  }
}
