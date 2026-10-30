import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var clipboardChannel: FlutterMethodChannel?
  private var editorChannel: FlutterMethodChannel?
  private var closeChannel: FlutterMethodChannel?
  private var fileMenuChannel: FlutterMethodChannel?
  private var fileMenu: NSMenu?
  private var fileMenuRoot: NSMenuItem?
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
    installFileMenu(messenger: controller.engine.binaryMessenger)
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


  // MARK: File menu

  // Dart owns the localized titles and which items apply to the current
  // screen; it pushes them with "update". Items call back into Dart so the
  // menu runs the same actions as the in-app menus. Save reuses the editor's
  // shortcut channel, which also serves Cmd-S (see performKeyEquivalent).
  private static let fileMenuItems: [(tag: Int, key: String, equivalent: String, modifiers: NSEvent.ModifierFlags)] = [
    (1, "newSong", "n", .command),
    (2, "import", "o", .command),
    (3, "save", "s", .command),
    (4, "exportChordPro", "e", .command),
    (5, "exportPdf", "e", [.command, .shift]),
    (6, "print", "p", .command),
  ]

  private func installFileMenu(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "org.freevia.singbook/file_menu", binaryMessenger: messenger)
    fileMenuChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "update", let values = call.arguments as? [String: Any], let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.buildFileMenuIfNeeded()
      self.applyFileMenu(values)
      result(nil)
    }
  }

  // The main menu is only guaranteed to exist once the app is running, so the
  // File menu is added when Dart first reports its state.
  private func buildFileMenuIfNeeded() {
    guard let mainMenu = NSApp.mainMenu, fileMenu == nil else { return }
    let menu = NSMenu(title: "File")
    menu.autoenablesItems = false
    for (index, entry) in Self.fileMenuItems.enumerated() {
      if index == 3 || index == 5 { menu.addItem(.separator()) }
      let item = NSMenuItem(title: entry.key, action: #selector(fileMenuItemSelected(_:)), keyEquivalent: entry.equivalent)
      item.keyEquivalentModifierMask = entry.modifiers
      item.tag = entry.tag
      item.target = self
      item.isEnabled = false
      menu.addItem(item)
    }
    let root = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
    root.submenu = menu
    mainMenu.insertItem(root, at: min(1, mainMenu.items.count))
    fileMenu = menu
    fileMenuRoot = root
  }

  private func applyFileMenu(_ values: [String: Any]) {
    guard let menu = fileMenu else { return }
    let canCreate = values["canCreate"] as? Bool ?? false
    let canSave = values["canSave"] as? Bool ?? false
    let canExport = values["canExport"] as? Bool ?? false
    if let title = values["title"] as? String {
      menu.title = title
      fileMenuRoot?.title = title
    }
    for entry in Self.fileMenuItems {
      guard let item = menu.item(withTag: entry.tag) else { continue }
      if let title = values[entry.key] as? String { item.title = title }
      switch entry.key {
      case "newSong", "import": item.isEnabled = canCreate
      case "save": item.isEnabled = canSave
      default: item.isEnabled = canExport
      }
    }
  }

  @objc private func fileMenuItemSelected(_ sender: NSMenuItem) {
    guard let entry = Self.fileMenuItems.first(where: { $0.tag == sender.tag }) else { return }
    if entry.key == "save" {
      editorChannel?.invokeMethod("save", arguments: nil)
    } else {
      fileMenuChannel?.invokeMethod(entry.key, arguments: nil)
    }
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
