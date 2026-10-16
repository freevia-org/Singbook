import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/application/youtube_music_consent.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/providers/core/youtube_music.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';

class _PendingSessionProvider implements LyricsProvider {
  _PendingSessionProvider(this.id);
  final String id;
  final started = Completer<CancellationToken?>();
  final response = Completer<SourceResult>();
  Completer<List<SongCandidate>>? searchResponse;
  final searchStarted = Completer<CancellationToken?>();
  SongCandidate get song => SongCandidate(
    providerId: id,
    id: 'fresh',
    title: 'Fixture',
    artist: 'Original Artist',
  );
  SourceResult get result => SourceResult(
    candidate: song,
    body: 'Original fixture words preserved for this particular recording.',
  );
  @override
  ProviderDefinition get definition =>
      ProviderDefinition(id: id, name: id, capabilities: {'catalog', 'lyrics'});
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) {
    if (!searchStarted.isCompleted) searchStarted.complete(cancel);
    return searchResponse?.future ?? Future.value([song]);
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) {
    started.complete(cancel);
    // Deliberately uncooperative: the controller/service must reject late data.
    return response.future;
  }
}

void main() {
  test('an automatic chooser redirect cannot stand in for a decision page', () {
    final navigation = YoutubeMusicConsentNavigation();
    navigation.started('https://consent.youtube.com/m?continue=synthetic');
    navigation.started('https://music.youtube.com/?cbrd=1');
    navigation.finished('https://music.youtube.com/?cbrd=1');
    expect(navigation.canFinish, isFalse);
    expect(navigation.canRestoreSession, isTrue);
  });

  test('initial Music load cannot finish a consent flow', () {
    final navigation = YoutubeMusicConsentNavigation();
    navigation.started('https://music.youtube.com/');
    navigation.finished('https://music.youtube.com/');
    expect(navigation.canFinish, isFalse);
    expect(navigation.canRestoreSession, isTrue);
    navigation.started('https://consent.youtube.com/m?continue=synthetic');
    navigation.finished('https://consent.youtube.com/m?continue=synthetic');
    expect(navigation.canFinish, isFalse);
    expect(navigation.canRestoreSession, isFalse);
    navigation.started('https://music.youtube.com/?cbrd=1');
    navigation.finished('https://music.youtube.com/?cbrd=1');
    expect(navigation.canFinish, isTrue);
    navigation.started('https://accounts.google.com/');
    navigation.finished('https://accounts.google.com/');
    expect(navigation.canFinish, isFalse);
    expect(navigation.canRestoreSession, isFalse);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.freevia.singbook/youtube_music_session');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'absent YouTube without a saved preference leaves native cookies alone',
    () async {
      sqfliteFfiInit();
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        throw PlatformException(code: 'unexpected_native_access');
      });
      final app = AppController(
        repository: repo,
        youtubeMusicConsent: YoutubeMusicConsent(supported: true),
        discovery: SourceDiscoveryService([_PendingSessionProvider('genius')]),
      );
      addTearDown(app.dispose);
      await app.initialize();
      expect(calls, isEmpty);
      expect(app.lastMessage, isNull);
    },
  );

  test(
    'disabled startup deletes legacy native cookies without restoring them',
    () async {
      sqfliteFfiInit();
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      await repo.setSetting('app', {
        'providers': {'youtubemusic': false},
      });
      var legacyCookies = true;
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'clearConsentCookies') {
          legacyCookies = false;
          return null;
        }
        return legacyCookies
            ? {'SOCS': 'synthetic-legacy-choice'}
            : <String, String>{};
      });
      final consent = YoutubeMusicConsent(supported: true);
      final app = AppController(
        repository: repo,
        youtubeMusicConsent: consent,
        discovery: SourceDiscoveryService([
          _PendingSessionProvider('youtubemusic'),
        ]),
      );
      addTearDown(app.dispose);
      await app.initialize();
      expect(calls, ['clearConsentCookies']);
      expect(legacyCookies, isFalse);
      expect(consent.session.hasConsent, isFalse);
      expect(app.providerEnabled('youtubemusic'), isFalse);
    },
  );

  for (final reenable in [false, true]) {
    test(
      'disable excludes late YouTube discovery and preserves other providers: $reenable',
      () async {
        sqfliteFfiInit();
        final repo = await LibraryRepository.open(
          path: inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        );
        addTearDown(repo.close);
        final youtube = _PendingSessionProvider('youtubemusic');
        final other = _PendingSessionProvider('genius');
        final consent = YoutubeMusicConsent(supported: false);
        final app = AppController(
          repository: repo,
          youtubeMusicConsent: consent,
          discovery: SourceDiscoveryService([youtube, other]),
        );
        addTearDown(app.dispose);
        final saved = SourceResult(
          candidate: const SongCandidate(
            providerId: 'youtubemusic',
            id: 'saved',
            title: 'Fixture',
            artist: 'Original Artist',
          ),
          body: 'Previously saved original words.',
        );
        final lookup = app.selectCandidate(
          youtube.song,
          cachedResults: [saved],
        );
        final ytCancel = await youtube.started.future;
        final otherCancel = await other.started.future;
        await app.setProviderEnabled('youtubemusic', false);
        expect(ytCancel!.isCancelled, isTrue);
        expect(otherCancel!.isCancelled, isFalse);
        expect(app.discovering, isTrue);
        if (reenable) await app.setProviderEnabled('youtubemusic', true);
        youtube.response.complete(youtube.result);
        other.response.complete(other.result);
        await lookup;
        expect(
          app.results.map((r) => r.id),
          containsAll([saved.id, other.result.id]),
        );
        expect(
          app.results.map((r) => r.id),
          isNot(contains(youtube.result.id)),
        );
        expect(app.checks.containsKey('youtubemusic'), isFalse);
        expect(app.checks['genius']?.state, 'found');
      },
    );
  }

  test(
    'disabling YouTube does not cancel an unrelated catalog search',
    () async {
      sqfliteFfiInit();
      final repo = await LibraryRepository.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      addTearDown(repo.close);
      final other = _PendingSessionProvider('genius')
        ..searchResponse = Completer<List<SongCandidate>>();
      final app = AppController(
        repository: repo,
        youtubeMusicConsent: YoutubeMusicConsent(supported: false),
        discovery: SourceDiscoveryService([
          other,
          _PendingSessionProvider('youtubemusic'),
        ]),
      );
      addTearDown(app.dispose);
      final search = app.search('Fixture');
      final cancel = await other.searchStarted.future;
      await app.setProviderEnabled('youtubemusic', false);
      expect(cancel!.isCancelled, isFalse);
      other.searchResponse!.complete([other.song]);
      await search;
      expect(app.suggestions.map((song) => song.identity), [
        other.song.identity,
      ]);
    },
  );

  test('off/on rejects a late YouTube catalog response', () async {
    sqfliteFfiInit();
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(repo.close);
    final youtube = _PendingSessionProvider('youtubemusic')
      ..searchResponse = Completer<List<SongCandidate>>();
    final app = AppController(
      repository: repo,
      youtubeMusicConsent: YoutubeMusicConsent(supported: false),
      discovery: SourceDiscoveryService([youtube]),
    );
    addTearDown(app.dispose);
    final lookup = app.search('Fixture');
    final cancellation = await youtube.searchStarted.future;
    await app.setProviderEnabled('youtubemusic', false);
    expect(cancellation!.isCancelled, isTrue);
    await app.setProviderEnabled('youtubemusic', true);
    youtube.searchResponse!.complete([youtube.song]);
    await lookup;
    expect(app.suggestions, isEmpty);
    expect(app.searching, isFalse);
    await app.search('Fixture');
    expect(app.suggestions.single.identity, youtube.song.identity);
  });

  test('disabled YouTube cannot issue a new catalog lookup', () async {
    sqfliteFfiInit();
    final repo = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(repo.close);
    final youtube = _PendingSessionProvider('youtubemusic');
    final app = AppController(
      repository: repo,
      youtubeMusicConsent: YoutubeMusicConsent(supported: false),
      discovery: SourceDiscoveryService([youtube]),
    );
    addTearDown(app.dispose);
    await app.setProviderEnabled('youtubemusic', false);
    await app.search('Fixture');
    expect(youtube.searchStarted.isCompleted, isFalse);
    expect(app.suggestions, isEmpty);
    expect(app.errorCode, 'not_configured');
  });

  for (final nativeFailure in [false, true]) {
    test('capture waits for pending native clear: $nativeFailure', () async {
      final deletion = Completer<void>();
      var reads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'clearConsentCookies') {
          await deletion.future;
          if (nativeFailure) throw PlatformException(code: 'synthetic_failure');
          return null;
        }
        reads++;
        return <String, String>{};
      });
      final consent = YoutubeMusicConsent(supported: true);
      consent.session.setConsentCookies({'SOCS': 'synthetic-choice'});
      final clearing = consent.clear();
      final capturing = consent.capture();
      await Future<void>.delayed(Duration.zero);
      expect(reads, 0);
      expect(consent.session.hasConsent, isFalse);
      deletion.complete();
      expect(await clearing, !nativeFailure);
      expect(await capturing, isFalse);
      expect(reads, nativeFailure ? 0 : 1);
      expect(consent.session.hasConsent, isFalse);
    });
  }

  for (final nativeFailure in [false, true]) {
    test(
      'disabling YouTube Music drops its session and keeps source off: $nativeFailure',
      () async {
        sqfliteFfiInit();
        final repo = await LibraryRepository.open(
          path: inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        );
        addTearDown(repo.close);
        var clears = 0;
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'clearConsentCookies');
          clears++;
          if (nativeFailure) throw PlatformException(code: 'synthetic_failure');
          return null;
        });
        final consent = YoutubeMusicConsent(supported: true);
        consent.session.setConsentCookies({'SOCS': 'synthetic-choice'});
        final app = AppController(
          repository: repo,
          youtubeMusicConsent: consent,
        );
        addTearDown(app.dispose);
        await app.setProviderEnabled('genius', false);
        expect(clears, 0);
        expect(consent.session.hasConsent, isTrue);
        await app.setProviderEnabled('youtubemusic', false);
        expect(clears, 1);
        expect(consent.session.hasConsent, isFalse);
        expect(app.providerEnabled('youtubemusic'), isFalse);
        expect(
          (await repo.getSetting('app'))['providers']['youtubemusic'],
          isFalse,
        );
        expect(
          app.messages.value?.code,
          nativeFailure ? 'operation_failed' : null,
        );
      },
    );
  }

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
