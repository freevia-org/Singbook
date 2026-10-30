import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import 'verse_ui_state.dart';

/// What the native macOS File menu shows: localized titles plus which items
/// apply to the current screen. Sent to the runner whenever either changes.
@immutable
class MacosFileMenuState {
  const MacosFileMenuState({
    required this.title,
    required this.newSong,
    required this.importItem,
    required this.save,
    required this.exportChordPro,
    required this.exportPdf,
    required this.print,
    required this.canCreate,
    required this.canSave,
    required this.canExport,
  });

  final String title,
      newSong,
      importItem,
      save,
      exportChordPro,
      exportPdf,
      print;
  final bool canCreate, canSave, canExport;

  Map<String, Object> toMap() => {
    'title': title,
    'newSong': newSong,
    'import': importItem,
    'save': save,
    'exportChordPro': exportChordPro,
    'exportPdf': exportPdf,
    'print': print,
    'canCreate': canCreate,
    'canSave': canSave,
    'canExport': canExport,
  };

  @override
  bool operator ==(Object other) =>
      other is MacosFileMenuState && mapEquals(toMap(), other.toMap());

  @override
  int get hashCode => Object.hashAll(toMap().values);

  /// Items apply by screen: songs and setlists can be created or imported from
  /// the library and readers, saving only exists in the editor, and the
  /// reader/setlist detail screens can export and print what they show.
  static MacosFileMenuState of(
    AppLocalizations l10n,
    VerseUiState state, {
    required String chordProLabel,
    required String setlistLabel,
  }) {
    final reading = state.route == VerseRoute.reader && state.song != null;
    final setlist =
        state.route == VerseRoute.setlistDetail && state.activeSetlist != null;
    return MacosFileMenuState(
      title: l10n.menuFile,
      newSong: '${l10n.menuNewSong}…',
      importItem: '${l10n.actionImport}…',
      save: l10n.actionSave,
      exportChordPro:
          '${l10n.actionExport} · ${setlist ? setlistLabel : chordProLabel}…',
      exportPdf: '${l10n.actionExport} · PDF…',
      print: '${l10n.actionPrint}…',
      canCreate: state.route != VerseRoute.editor,
      canSave: state.route == VerseRoute.editor,
      canExport: reading || setlist,
    );
  }
}

/// Connects the native File menu (macos/Runner/FileMenu.swift) to the shared
/// library actions. Save keeps using the editor's own native shortcut channel,
/// so Cmd-S and the menu item reach the same handler.
class MacosFileMenuScope extends StatefulWidget {
  const MacosFileMenuScope({
    super.key,
    required this.controller,
    required this.child,
    this.channel = const MethodChannel('org.freevia.singbook/file_menu'),
    this.enabled,
  });

  final VerseUiController controller;
  final Widget child;
  final MethodChannel channel;

  /// Overrides the platform check (tests).
  final bool? enabled;

  @override
  State<MacosFileMenuScope> createState() => _MacosFileMenuScopeState();
}

class _MacosFileMenuScopeState extends State<MacosFileMenuScope> {
  MacosFileMenuState? _sent;

  bool get _enabled =>
      widget.enabled ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    if (_enabled) {
      widget.channel.setMethodCallHandler(_onCall);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void didUpdateWidget(covariant MacosFileMenuScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled || identical(oldWidget.controller, widget.controller)) return;
    oldWidget.controller.removeListener(_sync);
    widget.controller.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    if (_enabled) {
      widget.controller.removeListener(_sync);
      widget.channel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  void _sync() {
    if (!_enabled || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final next = MacosFileMenuState.of(
      l10n,
      widget.controller.state,
      chordProLabel: 'ChordPro',
      setlistLabel: '.osts',
    );
    if (next == _sent) return;
    _sent = next;
    unawaited(
      widget.channel.invokeMethod<void>('update', next.toMap()).catchError((
        Object _,
      ) {
        // The native menu is optional (tests and non-Mac hosts have none).
      }),
    );
  }

  Future<Object?> _onCall(MethodCall call) async {
    final controller = widget.controller;
    final state = controller.state;
    switch (call.method) {
      case 'newSong':
        if (state.route == VerseRoute.editor) return null;
        await controller.createSong();
      case 'import':
        if (state.route == VerseRoute.editor) return null;
        await controller.importChordPro();
      case 'exportChordPro':
        if (state.route == VerseRoute.reader && state.song != null) {
          await controller.shareSong(state.song!.id);
        } else if (state.route == VerseRoute.setlistDetail &&
            state.activeSetlist != null) {
          await controller.shareSetlist(state.activeSetlist!.id);
        }
      case 'exportPdf':
        if (state.route == VerseRoute.reader && state.song != null) {
          await controller.shareSongPdf(state.song!.id);
        } else if (state.route == VerseRoute.setlistDetail &&
            state.activeSetlist != null) {
          await controller.shareSetlistPdf(state.activeSetlist!.id);
        }
      case 'print':
        if (state.route == VerseRoute.reader && state.song != null) {
          await controller.printSong(state.song!.id);
        } else if (state.route == VerseRoute.setlistDetail &&
            state.activeSetlist != null) {
          await controller.printSetlist(state.activeSetlist!.id);
        }
      default:
        throw MissingPluginException();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
