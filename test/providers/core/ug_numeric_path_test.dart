import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/charts.dart';

// Invented song text; models the provider's observed numeric canonical URLs.
Map<String, Object?> tab({String path = '/tab/123'}) => {
  'id': 123,
  'song_id': 456,
  'artist_id': 789,
  'artist_name': 'Harbor Band',
  'song_name': 'Paper Lanterns',
  'type': 'Chords',
  'tab_access_type': 'public',
  'tab_url': 'https://tabs.ultimate-guitar.com$path',
};

String page(Map<String, Object?> data, {String canonical = '/tab/123'}) {
  final encoded = jsonEncode({
    'store': {
      'page': {'data': data},
    },
  }).replaceAll('&', '&amp;').replaceAll('"', '&quot;');
  return '<link rel="canonical" href="https://tabs.ultimate-guitar.com$canonical">'
      '<div class="js-store" data-content="$encoded"></div>';
}

Map<String, Object?> detail({
  Map<String, Object?>? record,
  bool blocked = false,
}) => {
  'tab': record ?? tab(),
  'tab_view': {
    'blocked': blocked,
    'wiki_tab': {
      'content':
          '[ch]C[/ch]                 [ch]G[/ch]\n'
          'Paper lanterns drift across the quiet harbor water\n'
          '[ch]F[/ch]                 [ch]C[/ch]\n'
          'Every window glows beneath the softly falling rain',
    },
  },
};

void main() {
  test('observed numeric canonical and Unicode credits survive resolution', () {
    // Public metadata observed on chart 1643189; the lyric body is invented.
    final record = {
      ...tab(path: '/tab/1643189'),
      'id': 1643189,
      'song_id': 4155044,
      'artist_id': 325614,
      'artist_name': 'Los Panchos (Trio Los Panchos)',
      'song_name': 'Bésame Mucho',
    };
    final result = UltimateGuitarProvider.parsePage(
      page(detail(record: record), canonical: '/tab/1643189'),
      '/tab/1643189',
    );
    expect(result.candidate.id, '/tab/1643189');
    expect(result.candidate.artist, 'Los Panchos (Trio Los Panchos)');
    expect(result.candidate.title, 'Bésame Mucho');
  });

  test(
    'numeric search and resolved canonical URL retain exact chart identity',
    () {
      final candidates = UltimateGuitarProvider.parseSearch(
        page({
          'results': [tab()],
        }),
      );
      expect(candidates.single.id, '/tab/123');
      final result = UltimateGuitarProvider.parsePage(
        page(detail()),
        candidates.single.id,
      );
      expect(result.candidate.id, '/tab/123');
      expect(result.candidate.url, 'https://tabs.ultimate-guitar.com/tab/123');
      expect(result.body, contains('Paper lanterns'));
      expect(result.body, contains('[C]'));
    },
  );

  test(
    'numeric request permits same-ID legacy canonical but rejects mismatches',
    () {
      const legacy = '/tab/harbor-band/paper-lanterns-chords-123';
      final result = UltimateGuitarProvider.parsePage(
        page(
          detail(record: tab(path: legacy)),
          canonical: legacy,
        ),
        '/tab/123',
      );
      expect(result.candidate.id, '/tab/123');
      for (final source in [
        page(detail(record: {...tab(), 'id': 124})),
        page(detail(record: tab(path: '/tab/124'))),
        page(detail(), canonical: '/tab/124'),
      ]) {
        expect(
          () => UltimateGuitarProvider.parsePage(source, '/tab/123'),
          throwsException,
        );
      }
    },
  );

  test(
    'numeric format does not accept hostile URLs or unsupported chart types',
    () {
      for (final path in [
        '/tab/0',
        '/tab/0123',
        '/tab/-123',
        '/tab/123/extra',
        '/tab/123?x=1',
        '/tab/123#part',
        '/tab/%2f123',
        '//evil.example/tab/123',
        'https://evil.example/tab/123',
        '/tab/1234567890123456',
      ]) {
        expect(
          UltimateGuitarProvider.parseSearch(
            page({
              'results': [tab(path: path)],
            }),
          ),
          isEmpty,
        );
        expect(
          () => UltimateGuitarProvider.parsePage(page(detail()), path),
          throwsException,
        );
      }
      for (final change in [
        {'type': 'Ukulele Chords'},
        {'type': 'Official'},
        {'tab_access_type': 'private'},
      ]) {
        final record = {...tab(), ...change};
        expect(
          UltimateGuitarProvider.parseSearch(
            page({
              'results': [record],
            }),
          ),
          isEmpty,
        );
        expect(
          () => UltimateGuitarProvider.parsePage(
            page(detail(record: record)),
            '/tab/123',
          ),
          throwsException,
        );
      }
      expect(
        () => UltimateGuitarProvider.parsePage(
          page(detail(blocked: true)),
          '/tab/123',
        ),
        throwsException,
      );
    },
  );
}
