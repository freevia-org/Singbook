import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/library_actions.dart';
import 'package:singbook/ui/verse_ui_state.dart';

import 'support/fake_controller.dart';

void main() {
  testWidgets('setlist song picker keeps its confirmation above the keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    final controller = FakeUiController(
      (_) => const VerseUiState(
        songs: [
          SongCardData(id: 'song-1', title: 'Lanterns at Dawn'),
          SongCardData(id: 'song-2', title: 'Second Song'),
          SongCardData(id: 'song-3', title: 'Third Song'),
          SongCardData(id: 'song-4', title: 'Fourth Song'),
          SongCardData(id: 'song-5', title: 'Fifth Song'),
          SongCardData(id: 'song-6', title: 'Sixth Song'),
          SongCardData(id: 'song-7', title: 'Seventh Song'),
          SongCardData(id: 'song-8', title: 'Eighth Song'),
          SongCardData(id: 'song-9', title: 'Ninth Song'),
          SongCardData(id: 'song-10', title: 'Tenth Song'),
        ],
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () =>
                    showAddSongsToSetlist(context, controller, 'setlist-1'),
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanterns at Dawn'));
    await tester.pump();

    // Simulate the system keyboard occupying the lower 300 logical pixels.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final confirm = find.text('Add songs (1)');
    expect(confirm, findsOneWidget);
    final confirmRect = tester.getRect(confirm);
    final songsList = find.byType(ListView);
    expect(
      tester.getRect(songsList).bottom,
      lessThanOrEqualTo(confirmRect.top),
    );
    final scrollable = find.descendant(
      of: songsList,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
      reason: 'The song rows should scroll in the space above the footer.',
    );
    final keyboardTop = tester.view.physicalSize.height - 300;
    expect(
      confirmRect.bottom,
      lessThanOrEqualTo(keyboardTop),
      reason:
          'The confirm action must remain above the keyboard. '
          'confirm=$confirmRect keyboardTop=$keyboardTop',
    );
    await tester.tap(find.text('Add songs (1)'));
    await tester.pumpAndSettle();
    expect(controller.calls, contains('addSongToSetlist(song-1, setlist-1)'));
  });
}
