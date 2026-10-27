import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var clipboardChannel: FlutterMethodChannel?
  private var editorChannel: FlutterMethodChannel?
  private var closeChannel: FlutterMethodChannel?
  private var closeRequestPending = false
  private var fullScreenChannel: FlutterMethodChannel?
  private var playerFullScreenActive = false
  private var fullScreenBeforePlayer: Bool?
  private var desiredFullScreen: Bool?
  private var fullScreenTransitioning = false

  override func awakeFromNib() {
    if CommandLine.arguments.contains("--startup-timings") {
      NSLog("Singbook startup: native_window_awake")
    }
    backgroundColor = NSColor.windowBackgroundColor
    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())
    let controller = FlutterViewController(project: project)
    controller.backgroundColor = NSColor.windowBackgroundColor
    let windowFrame = frame
    contentViewController = controller
    setFrame(windowFrame, display: true)
    minSize = NSSize(width: 360, height: 480)
    title = "Singbook"
    (NSApp.delegate as? AppDelegate)?.installNativeChannels(messenger: controller.engine.binaryMessenger)
    RegisterGeneratedPlugins(registry: controller)
    delegate = self
    collectionBehavior.insert(.fullScreenPrimary)
    let fullScreen = FlutterMethodChannel(
      name: "org.freevia.singbook/fullscreen",
      binaryMessenger: controller.engine.binaryMessenger
    )
    fullScreenChannel = fullScreen
    fullScreen.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let enabled = call.arguments as? Bool, let self else {
        result(FlutterError(code: "invalid_arguments", message: "Fullscreen requires a boolean", details: nil))
        return
      }
      self.setPlayerFullScreen(enabled)
      result(nil)
    }
    editorChannel = FlutterMethodChannel(
      name: "org.freevia.singbook/editor_shortcuts",
      binaryMessenger: controller.engine.binaryMessenger
    )
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

  // Requests specify a desired state. Cocoa transitions asynchronously, so
  // repeated/rapid requests must not blindly toggle or lose the final exit.
  private func setPlayerFullScreen(_ enabled: Bool) {
    if enabled {
      if !playerFullScreenActive && fullScreenBeforePlayer == nil {
        fullScreenBeforePlayer = styleMask.contains(.fullScreen)
      }
      playerFullScreenActive = true
      desiredFullScreen = true
    } else {
      guard playerFullScreenActive || desiredFullScreen != nil else { return }
      playerFullScreenActive = false
      desiredFullScreen = fullScreenBeforePlayer ?? false
    }
    reconcileFullScreen()
  }

  private func reconcileFullScreen() {
    guard !fullScreenTransitioning, let desiredFullScreen else { return }
    if styleMask.contains(.fullScreen) != desiredFullScreen {
      fullScreenTransitioning = true
      toggleFullScreen(nil)
    } else if !playerFullScreenActive {
      // Restore the user's original window/fullscreen state on player exit.
      self.desiredFullScreen = nil
      fullScreenBeforePlayer = nil
    }
  }

  func windowWillEnterFullScreen(_ notification: Notification) {
    fullScreenTransitioning = true
  }

  func windowDidEnterFullScreen(_ notification: Notification) {
    fullScreenTransitioning = false
    reconcileFullScreen()
  }

  func windowWillExitFullScreen(_ notification: Notification) {
    // Native Escape/menu exit is a user choice, not a request to re-enter.
    if !fullScreenTransitioning && playerFullScreenActive {
      playerFullScreenActive = false
      desiredFullScreen = false
      fullScreenBeforePlayer = nil
      fullScreenChannel?.invokeMethod("exited", arguments: nil)
    }
    fullScreenTransitioning = true
  }

  func windowDidExitFullScreen(_ notification: Notification) {
    fullScreenTransitioning = false
    reconcileFullScreen()
  }

  func windowDidFailToEnterFullScreen(_ window: NSWindow) {
    cancelFullScreenRequest()
  }

  func windowDidFailToExitFullScreen(_ window: NSWindow) {
    cancelFullScreenRequest()
  }

  private func cancelFullScreenRequest() {
    fullScreenTransitioning = false
    playerFullScreenActive = false
    desiredFullScreen = nil
    fullScreenBeforePlayer = nil
    fullScreenChannel?.invokeMethod("exited", arguments: nil)
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    // Cocoa carries per-event modifiers even when synthetic input has no
    // separate flagsChanged event for Flutter's HardwareKeyboard state.
    let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
    if event.type == .keyDown,
       modifiers == [.command, .control],
       event.charactersIgnoringModifiers?.lowercased() == "f",
       let fullScreenChannel {
      // Route through Flutter so the reader panels and native window agree.
      fullScreenChannel.invokeMethod("toggleRequested", arguments: nil)
      return true
    }
    if event.type == .keyDown,
       modifiers == .command,
       event.charactersIgnoringModifiers?.lowercased() == "s",
       let editorChannel {
      editorChannel.invokeMethod("save", arguments: nil)
      return true
    }
    return super.performKeyEquivalent(with: event)
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
