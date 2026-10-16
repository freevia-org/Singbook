import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/ui/settings/youtube_music_consent_section.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const _rendererTestChannel = MethodChannel(
  'org.freevia.singbook/webview_renderer_test',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renderer crash is recoverable and preserves the route', (
    tester,
  ) async {
    final controllers = <WebViewController>[];
    final startedUrls = <String>[];
    var completionCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bg'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Comparison remains open'),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => YoutubeMusicConsentScreen(
                              labels: YoutubeConsentLabels(
                                title: 'YouTube Music',
                                explanation: l10n.youtubeConsentHint,
                                connect: l10n.youtubeConsentOpen,
                                saved: l10n.youtubeConsentSaved,
                                clear: l10n.youtubeConsentClear,
                                instructions: l10n.youtubeConsentInstructions,
                                notReady: l10n.youtubeConsentError,
                                navigationBlocked: l10n.youtubeConsentBlocked,
                                loadFailed: l10n.youtubeConsentPageError,
                                clearFailed: l10n.youtubeConsentError,
                                done: l10n.actionDone,
                                retry: l10n.actionRetry,
                              ),
                              onComplete: () async {
                                completionCalls++;
                                return true;
                              },
                              onWebViewControllerCreated: controllers.add,
                              onPageStartedForTesting: startedUrls.add,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open consent'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open consent'));
    await _pumpUntil(
      tester,
      () => controllers.isNotEmpty && startedUrls.isNotEmpty,
    );

    final initialController = controllers.last.platform;
    expect(initialController, isA<AndroidWebViewController>());
    final initialId =
        (initialController as AndroidWebViewController).webViewIdentifier;
    await _terminateRendererWhenReady(tester, initialId);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(YoutubeMusicConsentScreen)),
    );
    await _pumpUntil(
      tester,
      () => find.text(l10n.youtubeConsentPageError).evaluate().isNotEmpty,
    );
    expect(completionCalls, 0);
    expect(tester.takeException(), isNull);

    final pageStartsBeforeRetry = startedUrls.length;
    await tester.tap(find.byTooltip(l10n.actionRetry));
    await _pumpUntil(
      tester,
      () =>
          controllers.length >= 2 && startedUrls.length > pageStartsBeforeRetry,
    );
    final replacementController = controllers.last.platform;
    expect(replacementController, isA<AndroidWebViewController>());
    expect(
      (replacementController as AndroidWebViewController).webViewIdentifier,
      isNot(initialId),
    );
    expect(completionCalls, 0);
    expect(tester.takeException(), isNull);

    await binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Comparison remains open'), findsOneWidget);
    expect(find.byType(YoutubeMusicConsentScreen), findsNothing);
    expect(completionCalls, 0);
  });
}

Future<void> _terminateRendererWhenReady(
  WidgetTester tester,
  int webViewIdentifier,
) async {
  var terminated = false;
  for (var attempt = 0; attempt < 100 && !terminated; attempt++) {
    terminated =
        await _rendererTestChannel.invokeMethod<bool>('terminateRenderer', {
          'webViewIdentifier': webViewIdentifier,
        }) ??
        false;
    if (!terminated) await tester.pump(const Duration(milliseconds: 100));
  }
  expect(terminated, isTrue, reason: 'Timed out waiting for WebView renderer.');
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    condition(),
    isTrue,
    reason: 'Timed out waiting for native WebView state.',
  );
}
