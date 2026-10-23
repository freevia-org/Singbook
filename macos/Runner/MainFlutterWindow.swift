import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var clipboardChannel: FlutterMethodChannel?
  private var editorChannel: FlutterMethodChannel?
  private var closeChannel: FlutterMethodChannel?
  private var closeRequestPending = false

  override func awakeFromNib() {
    let project = FlutterDartProject()
    project.dartEntrypointArguments = Array(CommandLine.arguments.dropFirst())
    let controller = FlutterViewController(project: project)
    let windowFrame = frame
    contentViewController = controller
    setFrame(windowFrame, display: true)
    minSize = NSSize(width: 360, height: 480)
    title = "Singbook"
    (NSApp.delegate as? AppDelegate)?.installNativeChannels(messenger: controller.engine.binaryMessenger)
    RegisterGeneratedPlugins(registry: controller)
    delegate = self
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

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    // Cocoa carries per-event modifiers even when synthetic input has no
    // separate flagsChanged event for Flutter's HardwareKeyboard state.
    let modifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
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
