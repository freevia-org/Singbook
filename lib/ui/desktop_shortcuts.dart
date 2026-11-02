import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'verse_ui_state.dart';

/// Platform-neutral desktop commands. Windows maps them to Ctrl+key and macOS
/// to Cmd+key; the macOS File menu can dispatch the same intents.
class AppNewIntent extends Intent {
  const AppNewIntent();
}

class AppImportIntent extends Intent {
  const AppImportIntent();
}

class AppPrintIntent extends Intent {
  const AppPrintIntent();
}

class AppSaveIntent extends Intent {
  const AppSaveIntent();
}

class AppExportIntent extends Intent {
  const AppExportIntent();
}

/// Callbacks for the commands that apply to the current screen. A null entry
/// disables that command so its key press is left to the focused widget.
class DesktopCommands {
  const DesktopCommands({
    this.onNew,
    this.onImport,
    this.onPrint,
    this.onSave,
    this.onExport,
  });

  final VoidCallback? onNew;
  final VoidCallback? onImport;
  final VoidCallback? onPrint;
  final VoidCallback? onSave;
  final VoidCallback? onExport;

  /// Maps the current route and tab to the existing controller actions.
  /// Save is left to the editor, which already handles Ctrl/Cmd+S itself.
  factory DesktopCommands.forState(
    VerseUiState state,
    VerseUiController controller, {
    required String newSetlistName,
  }) {
    switch (state.route) {
      case VerseRoute.main:
        final setlists = state.activeTab == VerseTab.setlists;
        if (state.activeTab == VerseTab.settings) {
          return const DesktopCommands();
        }
        return DesktopCommands(
          onNew: () => unawaited(
            setlists
                ? controller.createSetlist(name: newSetlistName)
                : controller.createSong(),
          ),
          onImport: () => unawaited(
            setlists ? controller.importSetlist() : controller.importChordPro(),
          ),
        );
      case VerseRoute.reader:
        final song = state.song;
        if (song == null) return const DesktopCommands();
        return DesktopCommands(
          onPrint: () => unawaited(controller.printSong(song.id)),
          onExport: () => unawaited(controller.shareSong(song.id)),
        );
      case VerseRoute.setlistDetail:
        final setlist = state.activeSetlist;
        if (setlist == null) return const DesktopCommands();
        return DesktopCommands(
          onPrint: () => unawaited(controller.printSetlist(setlist.id)),
          onExport: () => unawaited(controller.shareSetlist(setlist.id)),
        );
      case VerseRoute.editor:
        return const DesktopCommands();
    }
  }
}

/// Binds Ctrl+N/O/P/S/E (Cmd on macOS when [handleMacOS]) to [commands] for everything below it.
///
/// Uses a hardware-keyboard handler instead of the focus tree so the commands
/// work wherever focus is, including on screens that hold no focus. A command
/// that is null for the current screen is not consumed, and nothing fires while
/// a dialog or another route covers this one. The matching intents are also
/// exposed through [Actions] so a native menu can invoke the same commands.
class DesktopShortcuts extends StatefulWidget {
  const DesktopShortcuts({
    super.key,
    required this.commands,
    required this.child,
    this.platform,
    this.handleMacOS = false,
  });

  final DesktopCommands commands;
  final Widget child;
  final TargetPlatform? platform;

  /// macOS binds Cmd+N/O/P/E as native menu key equivalents, so by default
  /// the Cmd path is ignored there to avoid firing every command twice.
  final bool handleMacOS;

  @override
  State<DesktopShortcuts> createState() => _DesktopShortcutsState();
}

class _DesktopShortcutsState extends State<DesktopShortcuts> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool get _mac =>
      (widget.platform ?? defaultTargetPlatform) == TargetPlatform.macOS;

  VoidCallback? _commandFor(LogicalKeyboardKey key) {
    final commands = widget.commands;
    if (key == LogicalKeyboardKey.keyN) return commands.onNew;
    if (key == LogicalKeyboardKey.keyO) return commands.onImport;
    if (key == LogicalKeyboardKey.keyP) return commands.onPrint;
    if (key == LogicalKeyboardKey.keyS) return commands.onSave;
    if (key == LogicalKeyboardKey.keyE) return commands.onExport;
    return null;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_mac && !widget.handleMacOS) return false;
    final keyboard = HardwareKeyboard.instance;
    final primary = _mac ? keyboard.isMetaPressed : keyboard.isControlPressed;
    final other = _mac ? keyboard.isControlPressed : keyboard.isMetaPressed;
    if (!primary || other || keyboard.isAltPressed || keyboard.isShiftPressed) {
      return false;
    }
    final command = _commandFor(event.logicalKey);
    if (command == null || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    command();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Action<T> guarded<T extends Intent>(VoidCallback? run) => run == null
        ? _DisabledAction<T>()
        : CallbackAction<T>(onInvoke: (_) => run());
    final commands = widget.commands;
    return Actions(
      actions: {
        AppNewIntent: guarded<AppNewIntent>(commands.onNew),
        AppImportIntent: guarded<AppImportIntent>(commands.onImport),
        AppPrintIntent: guarded<AppPrintIntent>(commands.onPrint),
        AppSaveIntent: guarded<AppSaveIntent>(commands.onSave),
        AppExportIntent: guarded<AppExportIntent>(commands.onExport),
      },
      child: widget.child,
    );
  }
}

class _DisabledAction<T extends Intent> extends Action<T> {
  @override
  bool isEnabled(T intent) => false;

  @override
  Object? invoke(T intent) => null;
}
