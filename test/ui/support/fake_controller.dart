import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/file_actions.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';
import 'package:singbook/ui/verse_ui_state.dart';

/// A [VerseUiController] whose state comes from a closure and which records the
/// calls the screens make. Screens depend only on the controller interface, so
/// they can be exercised without a database.
class FakeUiController extends VerseUiController {
  FakeUiController(this.build);

  /// Produces the state to show; read on every `state` access.
  final VerseUiState Function(FakeUiController controller) build;
  final calls = <String>[];
  final positionNotifier = ValueNotifier<PlayerPosition>(PlayerPosition.zero);
  final _notices = StreamController<UiNotice>.broadcast();

  // Mutable inputs tests can change before calling [refresh].
  bool dirty = false;
  void Function()? onBack;

  void refresh() => notifyListeners();
  void emit(UiNotice notice) => _notices.add(notice);

  @override
  VerseUiState get state => build(this);

  @override
  ValueListenable<PlayerPosition> get playerPosition => positionNotifier;

  @override
  Stream<UiNotice> get notices => _notices.stream;

  @override
  void dispose() {
    _notices.close();
    positionNotifier.dispose();
    super.dispose();
  }

  Future<void> _record(String call) async {
    calls.add(call);
  }

  @override
  Future<void> back() async {
    await _record('back');
    onBack?.call();
  }

  @override
  void setEditorDirty(bool value) {
    calls.add('setEditorDirty($value)');
    dirty = value;
    notifyListeners();
  }

  @override
  Future<void> saveLyricsEdit(String chordProText) =>
      _record('saveLyricsEdit(${chordProText.replaceAll('\n', '|')})');

  @override
  Future<void> createSetlist({String? name, String? songId}) =>
      _record('createSetlist(name: $name, songId: $songId)');

  @override
  Future<void> importChordPro() => _record('importChordPro');

  @override
  Future<void> importSetlist() => _record('importSetlist');

  @override
  Future<void> removeSetlistEntry(
    String setlistId,
    String entryId, {
    String? name,
    String? notes,
  }) => _record('removeSetlistEntry($setlistId, $entryId, $name, $notes)');

  @override
  Future<void> saveSetlistDetails({
    required String name,
    required String notes,
    List<String>? entryOrder,
    bool finishEditing = false,
  }) =>
      _record('saveSetlistDetails($name, $notes, $entryOrder, $finishEditing)');

  @override
  Future<void> setLyricsFontSize(double size) =>
      _record('setLyricsFontSize($size)');

  @override
  Future<void> seek(double seconds) async {
    calls.add('seek(${seconds.toStringAsFixed(1)})');
    positionNotifier.value = PlayerPosition(
      seconds,
      positionNotifier.value.currentLineId,
    );
  }

  @override
  Future<void> playPause() => _record('playPause');

  @override
  Future<void> toggleSongFavorite(String id) => _record('toggleFavorite($id)');

  @override
  Future<void> openSong(String id) => _record('openSong($id)');

  @override
  Future<void> addSongToSetlist(String songId, String setlistId) =>
      _record('addSongToSetlist($songId, $setlistId)');

  @override
  Future<void> syncNow() => _record('syncNow');

  @override
  Future<void> signInForSync() => _record('signInForSync');

  @override
  Future<void> signOutFromSync() => _record('signOutFromSync');

  @override
  Future<void> setAutoSync(bool enabled) => _record('setAutoSync($enabled)');

  @override
  Future<void> adoptAccount({required bool mergeLocal}) =>
      _record('adoptAccount(mergeLocal: $mergeLocal)');

  @override
  Future<void> confirmRemoteDeletions() => _record('confirmRemoteDeletions');

  @override
  Future<void> keepLocalAfterRemoteDeletions() =>
      _record('keepLocalAfterRemoteDeletions');

  @override
  void onAppResumed() => calls.add('onAppResumed');

  @override
  void reviewSyncConflicts() => calls.add('reviewSyncConflicts');

  @override
  void clearConflictFilter() => calls.add('clearConflictFilter');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName
        .toString()
        .replaceAll('Symbol("', '')
        .replaceAll('")', '');
    if (invocation.isMethod) {
      calls.add(name);
      return Future<void>.value();
    }
    return null;
  }
}

/// Pumps [VerseAppShell] around [controller] in a MaterialApp.
Future<void> pumpShell(
  WidgetTester tester,
  VerseUiController controller, {
  Size size = const Size(360, 780),
  Locale locale = const Locale('en'),
  double textScale = 1,
  int syncFocusRequest = 0,
  VoidCallback? onSyncFocusConsumed,
  VoidCallback? onOpenSyncSettings,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      theme: verseTheme(brightness: Brightness.light, palette: 'navy'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: VerseAppShell(
        controller: controller,
        files: VerseFileActions(),
        syncFocusRequest: syncFocusRequest,
        onSyncFocusConsumed: onSyncFocusConsumed ?? () {},
        onOpenSyncSettings: onOpenSyncSettings ?? () {},
      ),
    ),
  );
  // A running progress indicator never settles; step the clock instead.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));
