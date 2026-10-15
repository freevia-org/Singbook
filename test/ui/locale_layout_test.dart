import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

/// Right-to-left (Arabic) and long-text languages (German, Finnish, Greek,
/// Hungarian) plus scripts with tall glyphs, at normal and doubled text size.
const _locales = [
  Locale('ar'),
  Locale('de'),
  Locale('fi'),
  Locale('el'),
  Locale('hu'),
  Locale('ru'),
  Locale('vi'),
  Locale('ja'),
  Locale('hi'),
];

final _lines = [
  const LyricLineData(id: 'sec-0', section: 'Pre-Chorus 2'),
  for (var i = 0; i < 30; i++)
    LyricLineData(id: 'line-$i', text: 'Lyric number $i'),
];

final _songs = [
  for (var i = 0; i < 12; i++)
    SongCardData(
      id: 's$i',
      title: 'Song title $i',
      artist: 'Artist name $i',
      album: 'Album $i',
      playCount: i,
    ),
];

final _screens = <String, VerseUiState>{
  'songs': VerseUiState(activeTab: VerseTab.songs, songs: _songs),
  'setlists': VerseUiState(
    activeTab: VerseTab.setlists,
    setlists: [
      for (var i = 0; i < 4; i++)
        SetlistCardData(
          id: 'l$i',
          title: 'Setlist $i',
          songTitles: const ['One', 'Two', 'Three'],
        ),
    ],
  ),
  'settings': VerseUiState(
    activeTab: VerseTab.settings,
    syncReady: true,
    syncSignedIn: true,
    accountName: 'sam@example.com',
    lastSyncAt: DateTime(2026, 1, 1),
    lastSyncErrorCode: 'network',
    lastSyncConflicts: 2,
  ),
  'editor': const VerseUiState(
    route: VerseRoute.editor,
    editor: SongEditorData(
      songId: 's',
      isNew: false,
      title: 'Song',
      duration: 'x',
      tempo: 'y',
    ),
  ),
  'reader': VerseUiState(
    route: VerseRoute.reader,
    song: const SongCardData(
      id: 's',
      title: 'Test song',
      artist: 'Artist',
      durationSeconds: 200,
      hasChords: true,
    ),
    songLines: _lines,
    playerSections: const [
      PlayerSectionMarker(name: 'Verse 1', startSeconds: 0, lineId: 'sec-0'),
      PlayerSectionMarker(
        name: 'Pre-Chorus 2',
        startSeconds: 40,
        lineId: 'line-5',
      ),
      PlayerSectionMarker(name: 'Chorus', startSeconds: 80, lineId: 'line-10'),
      PlayerSectionMarker(name: 'Bridge', startSeconds: 120, lineId: 'line-15'),
      PlayerSectionMarker(name: 'Outro', startSeconds: 160, lineId: 'line-20'),
    ],
    readerKey: 'D',
    readerCapo: '2',
  ),
  'setlist detail': const VerseUiState(
    route: VerseRoute.setlistDetail,
    editingSetlist: true,
    activeSetlist: SetlistCardData(
      id: 'set',
      title: 'Sunday',
      notes: 'Notes',
      entries: [
        SetlistEntryData(id: 'e1', songId: 's1', title: 'Alpha', artist: 'A'),
        SetlistEntryData(id: 'e2', songId: 's2', title: 'Beta', artist: 'B'),
      ],
    ),
  ),
  'account change dialog': const VerseUiState(
    activeTab: VerseTab.settings,
    syncReady: true,
    syncSignedIn: true,
    accountName: 'sam@example.com',
    lastSyncErrorCode: 'account_changed',
  ),
};

void main() {
  for (final locale in _locales) {
    for (final scale in const [1.0, 2.0]) {
      for (final entry in _screens.entries) {
        testWidgets('${entry.key} lays out in $locale at ${scale}x text', (
          tester,
        ) async {
          final c = FakeUiController((_) => entry.value);
          addTearDown(c.dispose);
          await pumpShell(
            tester,
            c,
            locale: locale,
            textScale: scale,
            size: const Size(360, 640),
          );
          expect(tester.takeException(), isNull);
          final direction = Directionality.of(
            tester.element(find.byType(Scaffold).first),
          );
          expect(
            direction,
            locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
        });
      }
    }
  }

  testWidgets('the account change confirmation fits Arabic and Finnish', (
    tester,
  ) async {
    for (final locale in const [Locale('ar'), Locale('fi'), Locale('de')]) {
      final c = FakeUiController((_) => _screens['account change dialog']!);
      addTearDown(c.dispose);
      await pumpShell(
        tester,
        c,
        locale: locale,
        textScale: 2,
        size: const Size(360, 640),
        settle: true,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-change-replace')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-change-replace')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-replace-confirm-dialog')),
        findsOneWidget,
        reason: '$locale',
      );
      expect(tester.takeException(), isNull, reason: '$locale');
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-replace-cancel')),
      );
      await tester.tap(find.byKey(const ValueKey('account-replace-cancel')));
      await tester.pumpAndSettle();
    }
  });
}
