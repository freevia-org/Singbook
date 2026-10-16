import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/settings/youtube_music_consent_section.dart';

const labels = YoutubeConsentLabels(
  title: 'YouTube Music',
  explanation: 'Experimental. Make your choice on Google.',
  connect: 'Review Google consent',
  saved: 'Consent saved',
  clear: 'Clear consent',
  instructions: 'Make your choice, return here, then tap Done.',
  notReady: 'Consent is not saved yet.',
  navigationBlocked: 'Account login is unavailable.',
  loadFailed: 'Could not load Google.',
  clearFailed: 'Could not clear consent. Try again.',
  done: 'Done',
  retry: 'Retry',
);

void main() {
  testWidgets('consent controls fit a compact screen at double text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: YoutubeMusicConsentSection(
                labels: labels,
                hasConsent: true,
                onComplete: () async => true,
                onClear: () async => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('youtube-consent-connect')),
      findsOneWidget,
    );
  });
  testWidgets(
    'cancel does not capture; completing and clearing update consent state',
    (tester) async {
      var completeCalls = 0, clearCalls = 0, openCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YoutubeMusicConsentSection(
              labels: labels,
              hasConsent: false,
              onComplete: () async {
                completeCalls++;
                return true;
              },
              onClear: () async {
                clearCalls++;
                return true;
              },
              openBrowser: (_, complete) async {
                openCalls++;
                return openCalls == 1 ? null : await complete();
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('youtube-consent-connect')));
      await tester.pumpAndSettle();
      expect(completeCalls, 0);
      expect(find.text('Consent saved'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('youtube-consent-connect')));
      await tester.pumpAndSettle();
      expect(completeCalls, 1);
      expect(find.text('Consent saved'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('youtube-consent-clear')));
      await tester.pumpAndSettle();
      expect(clearCalls, 1);
      expect(find.text('Consent saved'), findsNothing);
    },
  );

  testWidgets('failed clear offers a retry instead of claiming success', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YoutubeMusicConsentSection(
            labels: labels,
            hasConsent: true,
            onComplete: () async => true,
            onClear: () async => false,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('youtube-consent-clear')));
    await tester.pumpAndSettle();
    expect(find.text(labels.clearFailed), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('youtube-consent-clear')),
          )
          .onPressed,
      isNotNull,
    );
  });
}
