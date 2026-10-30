import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/desktop_shortcuts.dart';
import 'package:singbook/ui/verse_ui_state.dart';

Future<void> _chord(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  DesktopCommands commands, {
  TargetPlatform platform = TargetPlatform.windows,
}) => tester.pumpWidget(
  MaterialApp(
    home: DesktopShortcuts(
      commands: commands,
      platform: platform,
      child: const Scaffold(body: SizedBox.expand()),
    ),
  ),
);

class _Recorder extends VerseUiController {
  final calls = <String>[];

  @override
  Future<void> createSong() async => calls.add('createSong');
  @override
  Future<void> createSetlist({String? name, String? songId}) async =>
      calls.add('createSetlist:$name');
  @override
  Future<void> importChordPro() async => calls.add('importChordPro');
  @override
  Future<void> importSetlist() async => calls.add('importSetlist');
  @override
  Future<void> printSong(String id) async => calls.add('printSong:$id');
  @override
  Future<void> shareSong(String id) async => calls.add('shareSong:$id');
  @override
  Future<void> printSetlist(String id) async => calls.add('printSetlist:$id');
  @override
  Future<void> shareSetlist(String id) async => calls.add('shareSetlist:$id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Ctrl+N/O/P/S/E run the matching command on Windows', (
    tester,
  ) async {
    final hits = <String>[];
    await _pump(
      tester,
      DesktopCommands(
        onNew: () => hits.add('new'),
        onImport: () => hits.add('import'),
        onPrint: () => hits.add('print'),
        onSave: () => hits.add('save'),
        onExport: () => hits.add('export'),
      ),
    );
    for (final key in [
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.keyO,
      LogicalKeyboardKey.keyP,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyE,
    ]) {
      await _chord(tester, LogicalKeyboardKey.controlLeft, key);
    }
    expect(hits, ['new', 'import', 'print', 'save', 'export']);
  });

  testWidgets('macOS uses Cmd and ignores Ctrl', (tester) async {
    final hits = <String>[];
    await _pump(
      tester,
      DesktopCommands(onNew: () => hits.add('new')),
      platform: TargetPlatform.macOS,
    );
    await _chord(
      tester,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyN,
    );
    expect(hits, isEmpty);
    await _chord(tester, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.keyN);
    expect(hits, ['new']);
  });

  testWidgets('disabled commands leave the key to the focused widget', (
    tester,
  ) async {
    var focused = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DesktopShortcuts(
          commands: const DesktopCommands(),
          platform: TargetPlatform.windows,
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.keyP) {
                focused++;
              }
              return KeyEventResult.ignored;
            },
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pump();
    await _chord(
      tester,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyP,
    );
    expect(focused, 1);
  });

  testWidgets('commands do not fire under an open dialog', (tester) async {
    final hits = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DesktopShortcuts(
          commands: DesktopCommands(onNew: () => hits.add('new')),
          platform: TargetPlatform.windows,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(title: Text('dialog')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _chord(
      tester,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyN,
    );
    expect(hits, isEmpty);
  });

  group('forState', () {
    const song = SongCardData(id: 's1', title: 'Song');
    const setlist = SetlistCardData(id: 'l1', title: 'Sunday');

    test('songs tab creates and imports songs', () async {
      final c = _Recorder();
      addTearDown(c.dispose);
      final cmd = DesktopCommands.forState(
        const VerseUiState(activeTab: VerseTab.songs),
        c,
        newSetlistName: 'New setlist',
      );
      cmd.onNew!();
      cmd.onImport!();
      expect(cmd.onPrint, isNull);
      expect(cmd.onExport, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(c.calls, ['createSong', 'importChordPro']);
    });

    test('setlists tab creates and imports setlists', () async {
      final c = _Recorder();
      addTearDown(c.dispose);
      final cmd = DesktopCommands.forState(
        const VerseUiState(activeTab: VerseTab.setlists),
        c,
        newSetlistName: 'New setlist',
      );
      cmd.onNew!();
      cmd.onImport!();
      await Future<void>.delayed(Duration.zero);
      expect(c.calls, ['createSetlist:New setlist', 'importSetlist']);
    });

    test('reader prints and shares the open song', () async {
      final c = _Recorder();
      addTearDown(c.dispose);
      final cmd = DesktopCommands.forState(
        const VerseUiState(route: VerseRoute.reader, song: song),
        c,
        newSetlistName: 'x',
      );
      expect(cmd.onNew, isNull);
      cmd.onPrint!();
      cmd.onExport!();
      await Future<void>.delayed(Duration.zero);
      expect(c.calls, ['printSong:s1', 'shareSong:s1']);
    });

    test('setlist detail prints and shares the setlist', () async {
      final c = _Recorder();
      addTearDown(c.dispose);
      final cmd = DesktopCommands.forState(
        const VerseUiState(
          route: VerseRoute.setlistDetail,
          activeSetlist: setlist,
        ),
        c,
        newSetlistName: 'x',
      );
      cmd.onPrint!();
      cmd.onExport!();
      await Future<void>.delayed(Duration.zero);
      expect(c.calls, ['printSetlist:l1', 'shareSetlist:l1']);
    });

    test('editor and settings expose no commands', () {
      final c = _Recorder();
      addTearDown(c.dispose);
      for (final state in const [
        VerseUiState(route: VerseRoute.editor),
        VerseUiState(activeTab: VerseTab.settings),
      ]) {
        final cmd = DesktopCommands.forState(state, c, newSetlistName: 'x');
        expect(cmd.onNew, isNull);
        expect(cmd.onImport, isNull);
        expect(cmd.onPrint, isNull);
        expect(cmd.onExport, isNull);
      }
    });
  });
}
