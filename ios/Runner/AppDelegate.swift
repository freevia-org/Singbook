import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var youtubeMusicSessionChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "org.freevia.singbook/youtube_music_session",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    youtubeMusicSessionChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard self != nil else {
        DispatchQueue.main.async {
          result(FlutterError(code: "unavailable", message: "Session bridge unavailable", details: nil))
        }
        return
      }
      guard call.arguments == nil else {
        DispatchQueue.main.async {
          result(FlutterError(code: "invalid_arguments", message: "This method does not accept arguments", details: nil))
        }
        return
      }

      switch call.method {
      case "getConsentCookies":
        self?.readYouTubeMusicConsentCookies(result: result)
      case "clearConsentCookies":
        self?.clearYouTubeMusicConsentCookies(result: result)
      default:
        DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
      }
    }
  }

  private func readYouTubeMusicConsentCookies(result: @escaping FlutterResult) {
    let store = WKWebsiteDataStore.default().httpCookieStore
    store.getAllCookies { cookies in
      let allowed = Set(["SOCS", "CONSENT"])
      var values: [String: String] = [:]
      for cookie in cookies where allowed.contains(cookie.name) && Self.appliesToYouTubeMusic(cookie) {
        values[cookie.name] = cookie.value
      }
      DispatchQueue.main.async { result(values) }
    }
  }

  private func clearYouTubeMusicConsentCookies(result: @escaping FlutterResult) {
    let store = WKWebsiteDataStore.default().httpCookieStore
    store.getAllCookies { cookies in
      let consentCookies = cookies.filter {
        ["SOCS", "CONSENT"].contains($0.name) && Self.appliesToYouTubeMusic($0)
      }
      let group = DispatchGroup()
      consentCookies.forEach { cookie in
        group.enter()
        store.delete(cookie) { group.leave() }
      }
      group.notify(queue: .main) { result(nil) }
    }
  }

  private static func appliesToYouTubeMusic(_ cookie: HTTPCookie) -> Bool {
    guard cookie.isSecure else { return false }
    if let expiresDate = cookie.expiresDate, expiresDate <= Date() { return false }

    let host = "music.youtube.com"
    let domain = cookie.domain.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    guard domain == "youtube.com" || domain == host else { return false }

    let requestPath = "/"
    let cookiePath = cookie.path
    guard requestPath == cookiePath ||
      (requestPath.hasPrefix(cookiePath) && (cookiePath.hasSuffix("/") ||
        requestPath.dropFirst(cookiePath.count).hasPrefix("/"))) else {
      return false
    }
    return true
  }
}
