import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var clipboardChannel: FlutterMethodChannel?
  private var closeChannel: FlutterMethodChannel?
  private var closeRequestPending = false

  override func awakeFromNib() {
    let controller = FlutterViewController()
    let windowFrame = frame
    contentViewController = controller
    setFrame(windowFrame, display: true)
    minSize = NSSize(width: 360, height: 480)
    title = "Singbook"
    (NSApp.delegate as? AppDelegate)?.installNativeChannels(messenger: controller.engine.binaryMessenger)
    RegisterGeneratedPlugins(registry: controller)
    delegate = self
    closeChannel = FlutterMethodChannel(
      name: "org.freevia.singbook/window_close",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let channel = FlutterMethodChannel(
      name: "org.freevia.singbook/rich_clipboard",
      binaryMessenger: controller.engine.binaryMessenger
    )
    clipboardChannel = channel
    channel.setMethodCallHandler { call, result in
      guard call.method == "setHtmlText" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let values = call.arguments as? [String: Any],
            let text = values["text"] as? String,
            let html = values["html"] as? String else {
        result(FlutterError(code: "invalid_arguments", message: "Invalid clipboard content", details: nil))
        return
      }
      let item = NSPasteboardItem()
      item.setString(text, forType: .string)
      item.setString(html, forType: .html)
      NSPasteboard.general.clearContents()
      result(NSPasteboard.general.writeObjects([item]) ? nil : FlutterError(
        code: "clipboard_failed", message: "Could not copy content", details: nil
      ))
    }
    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard !closeRequestPending, let closeChannel else { return false }
    closeRequestPending = true
    closeChannel.invokeMethod("requestClose", arguments: nil) { [weak self] response in
      guard let self else { return }
      self.closeRequestPending = false
      if response as? Bool == true {
        // Termination is also cancelable through FlutterAppDelegate. Keep the
        // window visible until that completes, including unsaved-draft prompts.
        (NSApp.delegate as? AppDelegate)?.terminateAfterConfirmedClose()
      }
    }
    return false
  }
}
