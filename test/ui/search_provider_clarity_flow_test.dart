import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui_image;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:singbook/application/app_controller.dart';
import 'package:singbook/data/library_repository.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/extra/import_sources.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/ui/app_controller_adapter.dart';
import 'package:singbook/ui/home/home_screen.dart';
import 'package:singbook/ui/theme/verse_theme.dart';
import 'package:singbook/ui/verse_app.dart';

// Synthetic public-shaped search results exercise real Genius and LRCLIB
// parsers, the real union/controller/adapter path, and the Online tile UI.
const _captureOutput = String.fromEnvironment('SEARCH_PROVIDER_CAPTURE_DIR');
final _artworkUrls = <Uri>{
  Uri.parse('https://images.genius.com/synthetic-eric.png'),
  Uri.parse('https://images.genius.com/synthetic-georgia.png'),
  Uri.parse('https://images.genius.com/synthetic-cynik.png'),
};

void main() {
  sqfliteFfiInit();

  testWidgets('Online results retain provider identity and distinct artwork', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      _clearTestImageCache();
      addTearDown(_clearTestImageCache);
      final previousOverrides = HttpOverrides.current;
      final imageRequests = <Uri>[];
      HttpOverrides.global = _ControlledImageOverrides(imageRequests);
      addTearDown(() => HttpOverrides.global = previousOverrides);
      final requests = <Uri>[];
      final transport = ProviderTransport(
        hostInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          if (request.url.host == 'api.genius.com') {
            return httpResponse({
              'response': {
                'hits': [
                  for (final row in _geniusRows)
                    {'type': 'song', 'result': row},
                ],
              },
            });
          }
          if (request.url.host == 'lrclib.net') {
            return httpResponse(_lrclibRows);
          }
          throw StateError('Unexpected request: ${request.url}');
        }),
      );
      final genius = GeniusProvider(transport, token: 'synthetic-test-token');
      final lrclib = LrclibProvider(transport);
      final disabled = _DisabledProvider();
      final wikisource = WikisourceProvider(transport);
      final customPublicDomain = _PublicDomainFixtureProvider();
      final repository = await _openRealAsyncRepository(tester, 'main');
      final (app, ui) = await _createFixtureController(
        tester,
        repository,
        SourceDiscoveryService([
          genius,
          lrclib,
          wikisource,
          customPublicDomain,
          disabled,
        ]),
        'main',
      );
      addTearDown(() async {
        ui.dispose();
        app.dispose();
        await _closeTransportInFakeAsync(tester, 'main', transport);
      });
      await _initializeOnlineUi(tester, repository, ui, 'main');
      expect(ui.state.searchIncludesOtherSources, isTrue);
      ui.setQuery('Lonely Stranger');

      await _pumpOnlineHome(tester, ui);
      await ui.submitSearch();
      await tester.pumpAndSettle();

      final references = ui.state.autocomplete;
      expect(references, hasLength(5));
      expect(
        references.map((row) => row.id),
        unorderedEquals([
          'genius:333411',
          'genius:5796943',
          'genius:12940913',
          'lrclib:36984333',
          'lrclib:36990105',
        ]),
      );
      final byId = {for (final row in references) row.id: row};
      expect(
        references.map((row) => row.providerId),
        unorderedEquals(['genius', 'genius', 'genius', 'lrclib', 'lrclib']),
      );
      expect(
        references.map((row) => row.providerName),
        unorderedEquals(['Genius', 'Genius', 'Genius', 'LRCLIB', 'LRCLIB']),
      );
      expect(
        references.map((row) => row.artist),
        unorderedEquals([
          'Eric Clapton',
          'Georgia Parker',
          'Cynik',
          'Eric Clapton',
          'Eric Clapton',
        ]),
      );
      expect(byId['genius:333411']!.title, 'Lonely Stranger (Acoustic Live)');
      expect(byId['genius:333411']!.artist, 'Eric Clapton');
      expect(byId['genius:5796943']!.artist, 'Georgia Parker');
      expect(byId['genius:12940913']!.artist, 'Cynik');
      expect(
        byId['genius:333411']!.artworkUrl,
        'https://images.genius.com/synthetic-eric.png',
      );
      expect(
        byId['genius:5796943']!.artworkUrl,
        'https://images.genius.com/synthetic-georgia.png',
      );
      expect(
        byId['genius:12940913']!.artworkUrl,
        'https://images.genius.com/synthetic-cynik.png',
      );
      expect(byId['genius:333411']!.album, isNull);
      expect(byId['genius:333411']!.durationSeconds, isNull);
      expect(byId['lrclib:36984333']!.album, 'Eric Clapton Unplugged');
      expect(byId['lrclib:36984333']!.durationSeconds, 351);
      expect(byId['lrclib:36990105']!.album, 'Eric Clapton - MTV Unplugged');
      expect(byId['lrclib:36990105']!.durationSeconds, 327);
      expect(
        byId.values
            .where((row) => row.providerId == 'genius')
            .every((row) => row.artworkUrl != null),
        isTrue,
      );
      expect(
        byId.values
            .where((row) => row.providerId == 'lrclib')
            .every((row) => row.artworkUrl == null),
        isTrue,
      );
      final ericTile = find.byKey(
        const ValueKey('online-reference-genius:333411'),
      );
      await _scrollOnlineResultIntoView(tester, ericTile, 100);
      expect(await _precacheTileImage(tester, ericTile), isEmpty);
      expect(
        find.descendant(of: ericTile, matching: find.byType(RawImage)),
        findsOneWidget,
        reason: 'a valid local PNG must decode inside Eric Clapton’s row',
      );
      expect(
        tester
            .widget<RawImage>(
              find.descendant(of: ericTile, matching: find.byType(RawImage)),
            )
            .image,
        isNotNull,
      );
      final failedTile = find.byKey(
        const ValueKey('online-reference-genius:5796943'),
      );
      await _scrollOnlineResultIntoView(tester, failedTile, 100);
      final failedImageErrors = await _precacheTileImage(tester, failedTile);
      expect(failedImageErrors, hasLength(1));
      expect(
        find.descendant(of: failedTile, matching: find.byType(RawImage)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: failedTile,
          matching: find.byIcon(Icons.graphic_eq_rounded),
        ),
        findsOneWidget,
        reason: 'a 404 uses the fallback in the same row',
      );
      expect(
        byId['genius:5796943']!.artworkUrl,
        'https://images.genius.com/synthetic-georgia.png',
      );
      final cynikTile = find.byKey(
        const ValueKey('online-reference-genius:12940913'),
      );
      await _scrollOnlineResultIntoView(tester, cynikTile, 100);
      expect(await _precacheTileImage(tester, cynikTile), isEmpty);
      final cynikRawImage = tester.widget<RawImage>(
        find.descendant(of: cynikTile, matching: find.byType(RawImage)),
      );
      expect(cynikRawImage.image, isNotNull);
      final lrclibTile = find.byKey(
        const ValueKey('online-reference-lrclib:36984333'),
      );
      await _scrollOnlineResultIntoView(tester, lrclibTile, 100);
      await tester.pump();
      final requestsBeforeNullArtworkTiles = imageRequests.length;
      for (final id in const ['lrclib:36984333', 'lrclib:36990105']) {
        final tile = find.byKey(ValueKey('online-reference-$id'));
        await _scrollOnlineResultIntoView(tester, tile, 100);
        expect(
          find.descendant(of: tile, matching: find.byType(Image)),
          findsNothing,
        );
        expect(
          find.descendant(of: tile, matching: find.byType(RawImage)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: tile,
            matching: find.byIcon(Icons.graphic_eq_rounded),
          ),
          findsOneWidget,
        );
      }
      expect(imageRequests.length, requestsBeforeNullArtworkTiles);
      expect(imageRequests.toSet(), containsAll(_artworkUrls));
      expect(
        imageRequests.every(_artworkUrls.contains),
        isTrue,
        reason:
            'null-artwork LRCLIB rows cannot request an image; Georgia may be retried by precache after the failed key is evicted',
      );

      // Labels travel with the tile, rather than being inferred from the result
      // ID or the preferred source. Selection still receives the original ID.
      for (var index = 0; index < references.length; index++) {
        final tileFinder = find.byKey(
          ValueKey('online-reference-${references[index].id}'),
        );
        await _scrollOnlineResultIntoView(tester, tileFinder, 100);
        final tile = tester.widget<ListTile>(tileFinder);
        expect(tile.subtitle, isA<Column>());
        expect(
          find.descendant(
            of: tileFinder,
            matching: find.text(references[index].providerName),
          ),
          findsOneWidget,
          reason: 'provider brand is visible in the result row',
        );
        final label = 'Source: ${references[index].providerName}';
        final sourceSemantics = tester
            .widgetList<Semantics>(
              find.descendant(of: tileFinder, matching: find.byType(Semantics)),
            )
            .where((semantics) => semantics.properties.label == label);
        expect(sourceSemantics, hasLength(1));
      }
      expect(requests.map((uri) => uri.host).toSet(), {
        'api.genius.com',
        'lrclib.net',
      });
      expect(imageRequests.toSet(), containsAll(_artworkUrls));
      expect(imageRequests.every(_artworkUrls.contains), isTrue);
      expect(disabled.searchCalls, 0);
      expect(app.songs, isEmpty);
      late Iterable<Object?> savedSongs;
      late Iterable<Object?> savedSetlists;
      await _runRealAsync(tester, 'main verify empty library', () async {
        savedSongs = await repository.listSongs();
        savedSetlists = await repository.listSetlists();
      });
      expect(savedSongs, isEmpty);
      expect(savedSetlists, isEmpty);

      final viewVariants = [
        (name: 'compact-en', locale: const Locale('en'), scale: 1.0),
        (name: 'compact-en-large-text', locale: const Locale('en'), scale: 2.0),
        (name: 'compact-ar-rtl', locale: const Locale('ar'), scale: 1.0),
      ];
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final variant in viewVariants) {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(780, 1688);
        await _pumpOnlineHome(
          tester,
          ui,
          locale: variant.locale,
          textScale: variant.scale,
        );
        final home = find.byType(VerseHomeScreen);
        expect(
          Directionality.of(tester.element(home)),
          variant.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          reason: variant.name,
        );
        for (final reference in references) {
          final tile = find.byKey(ValueKey('online-reference-${reference.id}'));
          await _scrollOnlineResultIntoView(tester, tile, 100);
          final brand = find.descendant(
            of: tile,
            matching: find.text(reference.providerName),
          );
          expect(brand, findsOneWidget, reason: variant.name);
          final tileRect = tester.getRect(tile);
          final brandRect = tester.getRect(brand);
          expect(
            brandRect.left >= tileRect.left - 0.5 &&
                brandRect.right <= tileRect.right + 0.5 &&
                brandRect.top >= tileRect.top - 0.5 &&
                brandRect.bottom <= tileRect.bottom + 0.5,
            isTrue,
            reason: '${variant.name}: provider label remains inside its tile',
          );
          expect(tester.takeException(), isNull, reason: variant.name);
        }
      }
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      await _pumpOnlineHome(tester, ui);

      // Tapping a Genius row carries the parsed provider-scoped ID unchanged.
      final selectedTile = find.byKey(
        const ValueKey('online-reference-genius:5796943'),
      );
      await _scrollOnlineResultIntoView(tester, selectedTile, 100);
      await tester.tap(selectedTile);
      await tester.pump();
      expect(app.selection?.providerId, 'genius');
      expect(app.selection?.id, '5796943');
      app.cancelDiscovery();

      // The capability follows the same isolation rule as the backend union:
      // only multiple ordinary catalogs with an ordinary primary can contribute.
      await _runRealAsync(
        tester,
        'main provider/catalog preference writes',
        () async {
          await app.setProviderEnabled('genius', false);
          await app.setProviderEnabled('wikisource', true);
          await app.setSearchCatalog('lrclib');
        },
      );
      expect(ui.state.searchIncludesOtherSources, isFalse);
      await _runRealAsync(
        tester,
        'main historical catalog preference',
        () async {
          await app.setSearchCatalog('wikisource');
        },
      );
      expect(ui.state.searchIncludesOtherSources, isFalse);
      await _runRealAsync(
        tester,
        'main public-domain catalog preference',
        () async {
          await app.setProviderEnabled('synthetic-public-domain', true);
          await app.setSearchCatalog('synthetic-public-domain');
        },
      );
      expect(ui.state.searchIncludesOtherSources, isFalse);
      await _runRealAsync(
        tester,
        'main restore ordinary provider preferences',
        () async {
          await app.setProviderEnabled('genius', true);
          await app.setProviderEnabled('wikisource', false);
          await app.setProviderEnabled('synthetic-public-domain', false);
          await app.setSearchCatalog('genius');
        },
      );
      expect(ui.state.searchIncludesOtherSources, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled Genius and LRCLIB providers are not queried', (
    tester,
  ) async {
    final requests = <Uri>[];
    final transport = ProviderTransport(
      hostInterval: Duration.zero,
      client: MockClient((request) async {
        requests.add(request.url);
        throw StateError('Disabled provider was queried: ${request.url}');
      }),
    );
    final repository = await _openRealAsyncRepository(tester, 'disabled');
    final (app, ui) = await _createFixtureController(
      tester,
      repository,
      SourceDiscoveryService([
        GeniusProvider(transport, token: 'synthetic-test-token'),
        LrclibProvider(transport),
      ]),
      'disabled',
    );
    addTearDown(() async {
      ui.dispose();
      app.dispose();
      await _closeTransportInFakeAsync(tester, 'disabled', transport);
    });
    await _initializeOnlineUi(tester, repository, ui, 'disabled');
    expect(ui.state.searchIncludesOtherSources, isTrue);
    await _runRealAsync(
      tester,
      'disabled provider preference writes',
      () async {
        await app.setProviderEnabled('genius', false);
        await app.setProviderEnabled('lrclib', false);
      },
    );
    ui.setQuery('Lonely Stranger');
    await _pumpOnlineHome(tester, ui);
    await ui.submitSearch();
    await tester.pump();
    expect(requests, isEmpty);
    expect(app.searching, isFalse);
    expect(ui.state.autocomplete, isEmpty);
    expect(ui.state.searchIncludesOtherSources, isFalse);
  });

  testWidgets('preferred-source selector copy follows eligible catalogs', (
    tester,
  ) async {
    final requests = <Uri>[];
    final transport = ProviderTransport(
      hostInterval: Duration.zero,
      client: MockClient((request) async {
        requests.add(request.url);
        throw StateError('Selector-only test must not search: ${request.url}');
      }),
    );
    final repository = await _openRealAsyncRepository(tester, 'selector');
    final (app, ui) = await _createFixtureController(
      tester,
      repository,
      SourceDiscoveryService([
        GeniusProvider(transport, token: 'synthetic-test-token'),
        LrclibProvider(transport),
        WikisourceProvider(transport),
        _PublicDomainFixtureProvider(),
      ]),
      'selector',
    );
    addTearDown(() async {
      ui.dispose();
      app.dispose();
      await _closeTransportInFakeAsync(tester, 'selector', transport);
    });
    await _initializeOnlineUi(tester, repository, ui, 'selector');
    await _pumpOnlineHome(tester, ui);
    _expectPreferredSourceSelector(tester, includesOtherSources: true);

    // LRCLIB remains the only ordinary source while historical text is enabled.
    await _runRealAsync(
      tester,
      'selector single ordinary source preferences',
      () async {
        await app.setProviderEnabled('genius', false);
        await app.setProviderEnabled('wikisource', true);
        await app.setSearchCatalog('lrclib');
      },
    );
    await _pumpOnlineHome(tester, ui);
    expect(ui.state.searchIncludesOtherSources, isFalse);
    _expectPreferredSourceSelector(tester, includesOtherSources: false);

    await _runRealAsync(
      tester,
      'selector historical primary preference',
      () async {
        await app.setSearchCatalog('wikisource');
      },
    );
    await _pumpOnlineHome(tester, ui);
    expect(ui.state.searchIncludesOtherSources, isFalse);
    _expectPreferredSourceSelector(tester, includesOtherSources: false);

    await _runRealAsync(
      tester,
      'selector custom public-domain preference',
      () async {
        await app.setProviderEnabled('synthetic-public-domain', true);
        await app.setSearchCatalog('synthetic-public-domain');
      },
    );
    await _pumpOnlineHome(tester, ui);
    expect(ui.state.searchIncludesOtherSources, isFalse);
    _expectPreferredSourceSelector(tester, includesOtherSources: false);

    await _runRealAsync(
      tester,
      'selector restore ordinary source preferences',
      () async {
        await app.setProviderEnabled('genius', true);
        await app.setProviderEnabled('wikisource', false);
        await app.setProviderEnabled('synthetic-public-domain', false);
        await app.setSearchCatalog('genius');
      },
    );
    await _pumpOnlineHome(tester, ui);
    expect(ui.state.searchIncludesOtherSources, isTrue);
    _expectPreferredSourceSelector(tester, includesOtherSources: true);
    expect(requests, isEmpty);
  });

  testWidgets('new query rejects both late old-provider responses', (
    tester,
  ) async {
    _clearTestImageCache();
    addTearDown(_clearTestImageCache);
    final previousOverrides = HttpOverrides.current;
    final imageRequests = <Uri>[];
    HttpOverrides.global = _ControlledImageOverrides(imageRequests);
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final oldGenius = Completer<dynamic>();
    final oldLrclib = Completer<dynamic>();
    final newGenius = Completer<dynamic>();
    final newLrclib = Completer<dynamic>();
    final oldRequests = <String>{};
    final oldRequestsReady = Completer<void>();
    final newRequests = <String>{};
    final newRequestsReady = Completer<void>();
    final transport = ProviderTransport(
      hostInterval: Duration.zero,
      client: MockClient((request) async {
        final query = request.url.queryParameters['q'];
        if (query == 'old query') {
          oldRequests.add(request.url.host);
          if (oldRequests.length == 2 && !oldRequestsReady.isCompleted) {
            oldRequestsReady.complete();
          }
          return httpResponse(
            request.url.host == 'api.genius.com'
                ? await oldGenius.future
                : await oldLrclib.future,
          );
        }
        newRequests.add(request.url.host);
        if (newRequests.length == 2 && !newRequestsReady.isCompleted) {
          newRequestsReady.complete();
        }
        return httpResponse(
          request.url.host == 'api.genius.com'
              ? await newGenius.future
              : await newLrclib.future,
        );
      }),
    );
    final repository = await _openRealAsyncRepository(tester, 'late-query');
    final (app, ui) = await _createFixtureController(
      tester,
      repository,
      SourceDiscoveryService([
        GeniusProvider(transport, token: 'synthetic-test-token'),
        LrclibProvider(transport),
      ]),
      'late-query',
    );
    addTearDown(() async {
      ui.dispose();
      app.dispose();
      if (!oldGenius.isCompleted) {
        oldGenius.complete({
          'response': {'hits': []},
        });
      }
      if (!oldLrclib.isCompleted) oldLrclib.complete([]);
      if (!newGenius.isCompleted) {
        newGenius.complete({
          'response': {'hits': []},
        });
      }
      if (!newLrclib.isCompleted) newLrclib.complete([]);
      await _closeTransportInFakeAsync(tester, 'late-query', transport);
    });
    await _initializeOnlineUi(tester, repository, ui, 'late-query');
    ui.setQuery('old query');
    await _pumpOnlineHome(tester, ui);
    final oldSearch = ui.submitSearch();
    await tester.runAsync(
      () => oldRequestsReady.future.timeout(const Duration(seconds: 5)),
    );

    ui.setQuery('new query');
    final newSearch = ui.submitSearch();

    oldGenius.complete({
      'response': {
        'hits': [
          {'type': 'song', 'result': _geniusRows[2]},
        ],
      },
    });
    oldLrclib.complete([_lrclibRows[1]]);
    await oldSearch;
    await tester.runAsync(
      () => newRequestsReady.future.timeout(const Duration(seconds: 5)),
    );
    expect(ui.state.query, 'new query');
    expect(ui.state.autocomplete, isEmpty);

    newGenius.complete({
      'response': {
        'hits': [
          {'type': 'song', 'result': _geniusRows[0]},
        ],
      },
    });
    newLrclib.complete([_lrclibRows[0]]);
    await newSearch;
    await tester.pump();
    final currentTile = find.byKey(
      const ValueKey('online-reference-genius:333411'),
    );
    await _scrollOnlineResultIntoView(tester, currentTile, 100);
    expect(await _precacheTileImage(tester, currentTile), isEmpty);
    expect(
      imageRequests,
      isNot(
        contains(Uri.parse('https://images.genius.com/synthetic-cynik.png')),
      ),
    );
    expect(ui.state.query, 'new query');
    expect(
      ui.state.autocomplete.map((row) => row.id),
      unorderedEquals(['genius:333411', 'lrclib:36984333']),
    );
    expect(app.songs, isEmpty);
    late Iterable<Object?> savedSongs;
    await _runRealAsync(tester, 'late-query verify empty library', () async {
      savedSongs = await repository.listSongs();
    });
    expect(savedSongs, isEmpty);
  });

  testWidgets('host capture: Online provider clarity variants', (tester) async {
    if (_captureOutput.isEmpty) return;
    _clearTestImageCache();
    addTearDown(_clearTestImageCache);
    final output = Directory(_captureOutput);
    if (output.existsSync()) {
      throw StateError(
        'Capture output must be a fresh, non-existing directory.',
      );
    }
    await _runRealAsync(tester, 'capture output directory create', () async {
      await output.create(recursive: true);
    });
    await _runRealAsync(tester, 'capture font load', _loadCaptureFonts);

    final imageRequests = <Uri>[];
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _ControlledImageOverrides(imageRequests);
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final transport = ProviderTransport(
      hostInterval: Duration.zero,
      client: MockClient((request) async {
        if (request.url.host == 'api.genius.com') {
          return httpResponse({
            'response': {
              'hits': [
                for (final row in _geniusRows) {'type': 'song', 'result': row},
              ],
            },
          });
        }
        if (request.url.host == 'lrclib.net') return httpResponse(_lrclibRows);
        throw StateError('Unexpected mock request: ${request.url}');
      }),
    );
    final repository = await _openRealAsyncRepository(tester, 'capture');
    final (app, ui) = await _createFixtureController(
      tester,
      repository,
      SourceDiscoveryService([
        GeniusProvider(transport, token: 'synthetic-test-token'),
        LrclibProvider(transport),
      ]),
      'capture',
    );
    addTearDown(() async {
      ui.dispose();
      app.dispose();
      await _closeTransportInFakeAsync(tester, 'capture', transport);
    });
    await _initializeOnlineUi(tester, repository, ui, 'capture');
    ui.setQuery('Lonely Stranger');

    const variants = [
      (name: 'compact-en', locale: Locale('en'), scale: 1.0),
      (name: 'compact-en-large-text', locale: Locale('en'), scale: 2.0),
      (name: 'compact-ar-rtl', locale: Locale('ar'), scale: 1.0),
    ];
    for (final variant in variants) {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(780, 1688);
      if (variant == variants.first) {
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
      }
      final boundary = GlobalKey();
      await _pumpOnlineHome(
        tester,
        ui,
        locale: variant.locale,
        textScale: variant.scale,
        boundaryKey: boundary,
      );
      await ui.submitSearch();
      await tester.pumpAndSettle();

      final resultsView = _onlineResultsView(tester);
      final resultsController = tester
          .widget<CustomScrollView>(resultsView)
          .controller;
      if (resultsController == null || !resultsController.hasClients) {
        throw StateError('The keyed Online results view is not attached.');
      }
      final minimumScrollExtent = resultsController.position.minScrollExtent;
      resultsController.jumpTo(minimumScrollExtent);
      await tester.pump();
      expect(
        resultsController.position.pixels,
        minimumScrollExtent,
        reason: '${variant.name}: reset the keyed results view to its top',
      );

      final geniusPreloadIds = ui.state.autocomplete
          .where((reference) => reference.providerId == 'genius')
          .map((reference) => reference.id)
          .toList();
      expect(geniusPreloadIds, hasLength(3));
      expect(geniusPreloadIds.toSet(), {
        'genius:333411',
        'genius:5796943',
        'genius:12940913',
      });
      for (final id in geniusPreloadIds) {
        debugPrintSynchronously(
          'SEARCH_PROVIDER_CAPTURE_PRELOAD: ${variant.name}: $id',
        );
        final tile = find.byKey(ValueKey('online-reference-$id'));
        await _scrollOnlineResultIntoView(tester, tile, 120);
        await _precacheTileImage(tester, tile);
      }
      await tester.drag(_onlineResultsView(tester), const Offset(0, 1000));
      await tester.pumpAndSettle();
      await _captureHostFrame(
        tester,
        boundary,
        output,
        '${variant.name}-top',
        variant.locale,
        variant.scale,
      );

      final lastLrclib = find.byKey(
        const ValueKey('online-reference-lrclib:36990105'),
      );
      await _scrollOnlineResultIntoView(tester, lastLrclib, 120);
      await tester.pumpAndSettle();
      await _captureHostFrame(
        tester,
        boundary,
        output,
        '${variant.name}-results',
        variant.locale,
        variant.scale,
      );
    }
    expect(imageRequests.map((url) => url.host).toSet(), {'images.genius.com'});
  });
}

void _clearTestImageCache() {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}

Finder _onlineResultsView(WidgetTester tester) {
  final view = find.byKey(const PageStorageKey<String>('songs-online-scroll'));
  expect(view, findsOneWidget);
  expect(tester.widget(view), isA<CustomScrollView>());
  return view;
}

Finder _onlineResultsScrollable(WidgetTester tester) {
  final view = _onlineResultsView(tester);
  final controller = tester.widget<CustomScrollView>(view).controller;
  if (controller == null) {
    throw StateError('The keyed Online results view needs its own controller.');
  }
  final scrollable = find.descendant(
    of: view,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          identical(widget.controller, controller) &&
          widget.axisDirection == AxisDirection.down,
    ),
  );
  expect(scrollable, findsOneWidget);
  return scrollable;
}

Future<void> _scrollOnlineResultIntoView(
  WidgetTester tester,
  Finder tile,
  double delta,
) async {
  final scrollable = _onlineResultsScrollable(tester);
  await tester.scrollUntilVisible(tile, delta, scrollable: scrollable);
}

Future<List<Object>> _precacheTileImage(
  WidgetTester tester,
  Finder tile,
) async {
  final imageFinder = find.descendant(of: tile, matching: find.byType(Image));
  final imageProvider = tester.widget<Image>(imageFinder.first).image;
  final errors = <Object>[];
  await tester.runAsync(
    () => precacheImage(
      imageProvider,
      tester.element(tile),
      onError: (error, _) => errors.add(error),
    ).timeout(const Duration(seconds: 5)),
  );
  await tester.pump();
  return errors;
}

Future<void> _pumpOnlineHome(
  WidgetTester tester,
  AppControllerAdapter ui, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  GlobalKey? boundaryKey,
}) async {
  final theme = verseTheme(
    brightness: Brightness.light,
    palette: 'navy',
    fontFamily: 'CatalogFixtureSans',
  );
  final captureTheme = theme.copyWith(
    textTheme: theme.textTheme.apply(
      fontFamily: 'CatalogFixtureSans',
      fontFamilyFallback: const ['CatalogFixtureArabic'],
    ),
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: singbookLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: captureTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: AnimatedBuilder(
          animation: ui,
          builder: (context, _) => Scaffold(
            body: VerseHomeScreen(controller: ui, state: ui.state),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _initializeOnlineUi(
  WidgetTester tester,
  LibraryRepository repository,
  AppControllerAdapter ui,
  String stage,
) async {
  // Starting in Online avoids a fire-and-forget last-view preference write
  // from setHomeListMode while still exercising the real adapter and screen.
  await _runRealAsync(
    tester,
    '$stage seed Online startup preference',
    () async {
      await repository.setSetting('app', {
        'startupSongsView': 'online',
        'lastSongsView': 'online',
        'lastSongsFavoritesOnly': false,
      });
    },
  );
  await _runRealAsync(tester, '$stage adapter initialize', ui.initialize);
}

Future<(AppController, AppControllerAdapter)> _createFixtureController(
  WidgetTester tester,
  LibraryRepository repository,
  SourceDiscoveryService discovery,
  String stage,
) async {
  late AppController app;
  late AppControllerAdapter ui;
  await _runRealAsync(
    tester,
    '$stage construct controller and adapter',
    () async {
      app = AppController(repository: repository, discovery: discovery);
      ui = AppControllerAdapter(app);
    },
  );
  return (app, ui);
}

Future<LibraryRepository> _openRealAsyncRepository(
  WidgetTester tester,
  String stage,
) async {
  LibraryRepository? opened;
  // Register before open so a failure still closes a repository if open
  // completed before test teardown begins.
  addTearDown(() async {
    final repository = opened;
    if (repository != null) {
      await _runRealAsync(tester, '$stage repository close', repository.close);
    }
  });
  await _runRealAsync(tester, '$stage repository open', () async {
    opened = await LibraryRepository.open(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  return opened!;
}

Future<void> _runRealAsync(
  WidgetTester tester,
  String stage,
  Future<void> Function() operation,
) async {
  var entered = false;
  (Object, StackTrace)? operationFailure;
  final completed = await tester.runAsync<bool>(() async {
    entered = true;
    debugPrintSynchronously('SEARCH_PROVIDER_REAL_ASYNC_START: $stage');
    try {
      await operation().timeout(const Duration(seconds: 20));
      debugPrintSynchronously('SEARCH_PROVIDER_REAL_ASYNC_DONE: $stage');
      return true;
    } catch (error, stack) {
      operationFailure = (error, stack);
      debugPrintSynchronously(
        'SEARCH_PROVIDER_REAL_ASYNC_FAILED: '
        '$stage (${error.runtimeType}): $error',
      );
      return false;
    }
  });
  if (!entered) {
    throw StateError('Real-async fixture callback was not entered: $stage');
  }
  final failure = operationFailure;
  if (failure != null) {
    Error.throwWithStackTrace(failure.$1, failure.$2);
  }
  if (completed != true) {
    throw StateError('Real-async fixture callback returned no result: $stage');
  }
}

Future<void> _closeTransportInFakeAsync(
  WidgetTester tester,
  String stage,
  ProviderTransport transport,
) async {
  // Call only after adapter/controller disposal and test-owned completers have
  // been resolved. Unmount first so the bounded pumps cannot rebuild the view.
  await tester.pumpWidget(const SizedBox.shrink());
  debugPrintSynchronously('SEARCH_PROVIDER_FAKE_CLEANUP_START: $stage');
  var completed = false;
  Object? closeError;
  StackTrace? closeStack;
  final closeFuture = transport.close();
  unawaited(
    closeFuture.then<void>(
      (_) {
        completed = true;
      },
      onError: (Object error, StackTrace stack) {
        closeError = error;
        closeStack = stack;
        completed = true;
      },
    ),
  );

  const pumpStep = Duration(milliseconds: 100);
  const cleanupBudget = Duration(seconds: 20);
  var elapsed = Duration.zero;
  await tester.pump();
  while (!completed && elapsed < cleanupBudget) {
    await tester.pump(pumpStep);
    elapsed += pumpStep;
  }
  if (!completed) {
    final timeout = TimeoutException(
      'Transport cleanup did not complete for $stage',
      cleanupBudget,
    );
    debugPrintSynchronously(
      'SEARCH_PROVIDER_FAKE_CLEANUP_FAILED: '
      '$stage (${timeout.runtimeType}): $timeout',
    );
    throw timeout;
  }
  if (closeError case final error?) {
    final stack = closeStack;
    if (stack == null) {
      throw StateError('Transport close failed without a stack trace: $stage');
    }
    debugPrintSynchronously(
      'SEARCH_PROVIDER_FAKE_CLEANUP_FAILED: '
      '$stage (${error.runtimeType}): $error',
    );
    Error.throwWithStackTrace(error, stack);
  }
  debugPrintSynchronously('SEARCH_PROVIDER_FAKE_CLEANUP_DONE: $stage');
}

void _expectPreferredSourceSelector(
  WidgetTester tester, {
  required bool includesOtherSources,
}) {
  final selector = find.byKey(const ValueKey('search-catalog-selector'));
  expect(selector, findsOneWidget);
  final decorator = tester.widget<InputDecorator>(selector);
  final l10n = AppLocalizations.of(tester.element(selector));
  expect(
    decorator.decoration.labelText,
    includesOtherSources
        ? l10n.searchPreferredSourceLabel
        : l10n.searchSourceLabel,
  );
  expect(
    decorator.decoration.helperText,
    includesOtherSources ? l10n.searchPreferredSourceHint : isNull,
  );
  if (includesOtherSources) {
    expect(decorator.decoration.helperMaxLines, 3);
  }
}

Future<void> _loadCaptureFonts() async {
  await (FontLoader('CatalogFixtureSans')
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/NotoSans-Bold.ttf')))
      .load();
  await (FontLoader('CatalogFixtureArabic')
        ..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

Future<void> _captureHostFrame(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Directory output,
  String name,
  Locale locale,
  double textScale,
) async {
  expect(tester.takeException(), isNull);
  await _runRealAsync(tester, 'capture frame $name', () async {
    final image =
        await (boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui_image.ImageByteFormat.png);
      expect(data, isNotNull);
      final png = File('${output.path}/$name.png');
      final sidecar = File('${output.path}/$name.json');
      if (png.existsSync() || sidecar.existsSync()) {
        throw StateError('Refusing to overwrite capture $name.');
      }
      await png.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      await sidecar.writeAsString(
        jsonEncode({
          'screen': 'online-provider-clarity-$name',
          'width': image.width,
          'height': image.height,
          'locale': locale.toLanguageTag(),
          'textScale': textScale,
          'devicePixelRatio': 2,
          'evidenceKind': 'host_widget_screenshot',
          'syntheticContentOnly': true,
          'nativeAndroidVerified': false,
        }),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

Map<String, Object?> _geniusRow({
  required int id,
  required String title,
  required String artist,
  required String artwork,
  String? album,
}) => {
  'id': id,
  'title': title,
  'url': 'https://genius.com/synthetic-song-$id-lyrics',
  'primary_artist': {'name': artist},
  'album': album == null ? null : {'name': album},
  'song_art_image_url': artwork,
};

final _geniusRows = [
  _geniusRow(
    id: 333411,
    title: 'Lonely Stranger (Acoustic Live)',
    artist: 'Eric Clapton',
    artwork: 'https://images.genius.com/synthetic-eric.png',
  ),
  _geniusRow(
    id: 5796943,
    title: 'Lonely Stranger',
    artist: 'Georgia Parker',
    artwork: 'https://images.genius.com/synthetic-georgia.png',
  ),
  _geniusRow(
    id: 12940913,
    title: 'Lonely Stranger',
    artist: 'Cynik',
    artwork: 'https://images.genius.com/synthetic-cynik.png',
  ),
];

final _lrclibRows = [
  _lrclibRow(id: 36984333, album: 'Eric Clapton Unplugged', duration: 351),
  _lrclibRow(
    id: 36990105,
    album: 'Eric Clapton - MTV Unplugged',
    duration: 327,
  ),
];

Map<String, Object?> _lrclibRow({
  required int id,
  required String album,
  required int duration,
}) => {
  'id': id,
  'trackName': 'Lonely Stranger',
  'artistName': 'Eric Clapton',
  'albumName': album,
  'duration': duration,
  'instrumental': false,
  'plainLyrics': 'Synthetic lyrics, locally supplied for this test.',
};

http.Response httpResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

class _DisabledProvider implements LyricsProvider {
  int searchCalls = 0;

  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'synthetic-disabled',
    name: 'Synthetic disabled source',
    capabilities: {'catalog', 'lyrics'},
    enabledByDefault: false,
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    searchCalls++;
    return const [];
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

class _PublicDomainFixtureProvider implements LyricsProvider {
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'synthetic-public-domain',
    name: 'Synthetic public-domain archive',
    capabilities: {'catalog', 'lyrics'},
    enabledByDefault: false,
    accessMode: 'publicDomainText',
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => const [];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

class _ControlledImageOverrides extends HttpOverrides {
  _ControlledImageOverrides(List<Uri> requests) {
    _ControlledImageClient.requests = requests;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ControlledImageClient();
}

class _ControlledImageClient implements HttpClient {
  static List<Uri> requests = <Uri>[];

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requests.add(url);
    final missing = url.path.contains('synthetic-georgia');
    return _ControlledImageRequest(
      status: missing ? HttpStatus.notFound : HttpStatus.ok,
      bytes: missing ? Uint8List(0) : _onePixelPng,
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControlledImageRequest implements HttpClientRequest {
  _ControlledImageRequest({required this.status, required this.bytes});
  final int status;
  final Uint8List bytes;
  @override
  final HttpHeaders headers = _NoopHeaders();

  @override
  Future<HttpClientResponse> close() async =>
      _ControlledImageResponse(status: status, bytes: bytes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControlledImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ControlledImageResponse({required this.status, required this.bytes});
  final int status;
  final Uint8List bytes;
  @override
  int get statusCode => status;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _NoopHeaders()
    ..set(HttpHeaders.contentLengthHeader, bytes.length)
    ..set(HttpHeaders.contentTypeHeader, 'image/png');
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_values[name.toLowerCase()] ??= <String>[]).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = <String>[value.toString()];
  }

  @override
  String? value(String name) {
    final values = _values[name.toLowerCase()];
    if (values == null || values.isEmpty) return null;
    if (values.length > 1) throw HttpException('Multiple values for $name');
    return values.single;
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _onePixelPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGPQqDjxHwAEnAJobhvlygAAAABJRU5ErkJggg==',
  ),
);
