import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/application/youtube_music_consent.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/providers/core/youtube_music.dart';
import 'package:singbook/ui/app_controller_adapter.dart';

void main() {
  test('initial Music load cannot finish a consent flow', () {
    final navigation = YoutubeMusicConsentNavigation();
    navigation.started('https://music.youtube.com/');
    navigation.finished('https://music.youtube.com/');
    expect(navigation.canFinish, isFalse);
    navigation.started('https://consent.youtube.com/m?continue=synthetic');
    navigation.finished('https://consent.youtube.com/m?continue=synthetic');
    expect(navigation.canFinish, isFalse);
    navigation.started('https://music.youtube.com/?cbrd=1');
    navigation.finished('https://music.youtube.com/?cbrd=1');
    expect(navigation.canFinish, isTrue);
    navigation.started('https://accounts.google.com/');
    navigation.finished('https://accounts.google.com/');
    expect(navigation.canFinish, isFalse);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/youtube_music_session');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'app factory and UI actions share the same session without synced settings',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'getConsentCookies'
            ? {'SOCS': 'synthetic-choice'}
            : null,
      );
      final consent = YoutubeMusicConsent(supported: true);
      final app = AppController(youtubeMusicConsent: consent);
      final adapter = AppControllerAdapter(app);
      addTearDown(() {
        adapter.dispose();
        app.dispose();
      });
      final provider = app.discovery.providers
          .whereType<YoutubeMusicProvider>()
          .single;
      expect(identical(provider.session, consent.session), isTrue);
      expect(adapter.youtubeMusicConsentSupported, isTrue);
      expect(await adapter.completeYoutubeMusicConsent(), isTrue);
      expect(adapter.youtubeMusicConsentSaved, isTrue);
      expect(provider.session.cookieHeader, 'SOCS=synthetic-choice');
      expect(app.settings, isEmpty);
      expect(await adapter.clearYoutubeMusicConsent(), isTrue);
      expect(adapter.youtubeMusicConsentSaved, isFalse);
      expect(provider.session.cookieHeader, isNull);
      expect(app.settings, isEmpty);
    },
  );

  test(
    'restores anonymous consent only and clears through the native jar',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        expect(call.arguments, isNull);
        return call.method == 'getConsentCookies'
            ? {'SOCS': 'synthetic-choice', 'SID': 'synthetic-account-cookie'}
            : null;
      });
      final consent = YoutubeMusicConsent(supported: true);
      expect(await consent.restore(), isTrue);
      expect(consent.session.cookieHeader, 'SOCS=synthetic-choice');
      expect(await consent.clear(), isTrue);
      expect(consent.session.hasConsent, isFalse);
      expect(calls, ['getConsentCookies', 'clearConsentCookies']);
    },
  );

  test('clear invalidates a pending native read', () async {
    final response = Completer<Map<String, String>>();
    messenger.setMockMethodCallHandler(
      channel,
      (call) async =>
          call.method == 'getConsentCookies' ? response.future : null,
    );
    final consent = YoutubeMusicConsent(supported: true);
    final reading = consent.capture();
    expect(await consent.clear(), isTrue);
    response.complete({'SOCS': 'synthetic-stale-choice'});
    expect(await reading, isFalse);
    expect(consent.session.hasConsent, isFalse);
  });

  test(
    'native failure keeps cookie values out of errors and drops memory on clear',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(
          code: 'test',
          message: 'private platform details',
        ),
      );
      final consent = YoutubeMusicConsent(supported: true);
      consent.session.setConsentCookies({'SOCS': 'synthetic-choice'});
      expect(await consent.clear(), isFalse);
      expect(consent.session.hasConsent, isFalse);
      expect(await consent.capture(), isFalse);
    },
  );

  test('unsupported platforms never call the cookie bridge', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => fail('Unexpected native call'),
    );
    final consent = YoutubeMusicConsent(supported: false);
    expect(await consent.restore(), isFalse);
    expect(await consent.clear(), isFalse);
  });

  test(
    'browser navigation accepts only exact HTTPS consent and return hosts',
    () {
      for (final url in [
        'https://music.youtube.com/',
        'https://consent.youtube.com/m?continue=synthetic',
      ]) {
        expect(isYoutubeMusicConsentUrl(url), isTrue);
      }
      for (final url in [
        'http://music.youtube.com/',
        'https://music.youtube.com:8443/',
        'https://music.youtube.com.evil.example/',
        'https://accounts.google.com/',
        'https://user:secret@music.youtube.com/',
        'javascript:alert(1)',
      ]) {
        expect(isYoutubeMusicConsentUrl(url), isFalse);
      }
      expect(isYoutubeMusicReturnUrl('https://consent.youtube.com/m'), isFalse);
      expect(
        isYoutubeMusicReturnUrl('https://music.youtube.com/?cbrd=1'),
        isTrue,
      );
    },
  );
}
