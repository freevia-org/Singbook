import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/verse_ui_state.dart';

void main() {
  testWidgets(
    'source comparison uses two panes on tablets and stacks on phones',
    (tester) async {
      const state = VerseUiState(
        homeListMode: HomeListMode.online,
        query: 'Small Hours',
        searchState: LoadState.loaded,
        comparison: SearchComparisonData(
          reference: SearchReferenceData(
            id: 'reference',
            title: 'Small Hours',
            artist: 'Freevia Test',
          ),
          suggested: SourceVersionData(
            id: 'sheet',
            providerId: 'test',
            providerName: 'Original source',
            title: 'Original arrangement',
            artist: 'Freevia Test',
            hasLyrics: true,
            hasChords: true,
            canSave: true,
            bodyPreview: [
              LyricLineData(id: 'line', text: 'A quiet room, a song to share'),
            ],
          ),
          alternatives: [
            SourceVersionData(
              id: 'alternative',
              providerId: 'alternate',
              providerName: 'Alternative source',
              title: 'Small Hours',
              artist: 'Freevia Test',
              hasLyrics: true,
              isUsableVersion: true,
            ),
          ],
        ),
      );
      final controller = _TabletHomeController(state);
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final size in const [
        Size(1280, 800),
        Size(800, 1280),
        Size(400, 850),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('uk'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width >= 800 ? 1.4 : 1),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: VerseHomeScreen(controller: controller, state: state),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Comparison at $size');
        final list = tester.getRect(
          find.byKey(const PageStorageKey('version-list')),
        );
        final preview = tester.getRect(
          find.byKey(const ValueKey('version-selection-footer')),
        );
        final saveButton = tester.getRect(
          find.byKey(const ValueKey('save-open-lyrics')),
        );
        expect(find.text('A quiet room, a song to share'), findsOneWidget);
        expect(saveButton.bottom, lessThanOrEqualTo(size.height));
        if (size.width >= 800) {
          expect(list.right, lessThanOrEqualTo(preview.left));
          expect(list.top, lessThan(preview.bottom));
          expect(preview.top, lessThan(list.bottom));
        } else {
          expect(preview.top, greaterThan(list.top));
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _TabletHomeController extends VerseUiController {
  _TabletHomeController(this._state);
  final VerseUiState _state;
  @override
  VerseUiState get state => _state;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #submitSearch ||
        invocation.memberName == #saveSelectedVersion ||
        invocation.memberName == #loadMoreRecent) {
      return Future<void>.value();
    }
    return null;
  }
}
