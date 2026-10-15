import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/charts.dart';
import 'package:singbook/providers/core/common.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

Matcher errorCode(String code) =>
    isA<ProviderException>().having((e) => e.code, 'code', code);

/// Runs [body] and fails when it takes longer than [limit].
T bounded<T>(T Function() body, {Duration limit = const Duration(milliseconds: 500)}) {
  final watch = Stopwatch()..start();
  final result = body();
  expect(
    watch.elapsed,
    lessThan(limit),
    reason: 'hostile input must be handled in linear time',
  );
  return result;
}

const verse =
    '[Verse 1]\n'
    '[tab][ch]C[/ch]       [ch]F#m7[/ch]\n'
    'A paper satellite sails[/tab]\n'
    '[tab]     [ch]D[/ch]       [ch]G/B[/ch]\n'
    'Above an empty desk at night[/tab]';

String ugPage(String content) {
  final data = {
    'store': {
      'page': {
        'data': {
          'tab': {
            'id': 123,
            'song_name': 'Paper Satellites',
            'artist_name': 'Fixture Ensemble',
            'tab_url':
                'https://tabs.ultimate-guitar.com/tab/fixture/paper-chords-123',
            'type': 'Chords',
            'tab_access_type': 'public',
          },
          'tab_view': {
            'wiki_tab': {'content': content},
          },
        },
      },
    },
  };
  return '<div class="js-store" data-content="${const HtmlEscape(HtmlEscapeMode.attribute).convert(jsonEncode(data))}"></div>';
}

const ugPath = '/tab/fixture/paper-chords-123';

String chordSong(String chord) =>
    '[Verse 1]\n[ch]$chord[/ch]A paper satellite sails\n[ch]G[/ch]Above an empty desk at night';

class _Chart implements LyricsProvider {
  _Chart(this.bodies, {this.titles = const {}});
  final Map<String, String> bodies;
  final Map<String, String> titles;
  final resolved = <String>[];
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'chart',
    name: 'chart',
    capabilities: {'catalog', 'lyrics', 'chords'},
  );
  SongCandidate _c(String id) => SongCandidate(
    providerId: 'chart',
    id: id,
    title: titles[id] ?? 'Paper Satellites',
    artist: 'Fixture Ensemble',
  );
  @override
  Future<List<SongCandidate>> search(
    String q, {
    CancellationToken? cancel,
  }) async => [for (final id in bodies.keys) _c(id)];
  @override
  Future<SourceResult> resolve(
    SongCandidate c, {
    CancellationToken? cancel,
  }) async {
    resolved.add(c.id);
    // A wrong-title result simulates an identity mismatch for that chart.
    final returned = titles.containsKey(c.id) && c.id == 'bad'
        ? SongCandidate(
            providerId: 'chart',
            id: c.id,
            title: 'Something Else',
            artist: 'Fixture Ensemble',
          )
        : c;
    return SourceResult(candidate: returned, body: bodies[c.id]!);
  }
}

/// First chart is truncated; the alternative lookups then hang until their
/// cancellation token fires (as a slow network retry would).
class _HangingAlternatives implements LyricsProvider {
  final resolved = <String>[];
  final released = Completer<bool>();
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'chart',
    name: 'chart',
    capabilities: {'catalog', 'lyrics', 'chords'},
  );
  SongCandidate _c(String id) => SongCandidate(
    providerId: 'chart',
    id: id,
    title: 'Paper Satellites',
    artist: 'Fixture Ensemble',
  );
  @override
  Future<List<SongCandidate>> search(
    String q, {
    CancellationToken? cancel,
  }) async => [_c('short'), _c('slow-1'), _c('slow-2')];
  @override
  Future<SourceResult> resolve(
    SongCandidate c, {
    CancellationToken? cancel,
  }) async {
    resolved.add(c.id);
    if (c.id == 'short') {
      return SourceResult(candidate: c, body: '[C]A paper satellite');
    }
    await cancel!.cancelled; // blocks until the caller cancels it
    if (!released.isCompleted) released.complete(true);
    throw const ProviderException('cancelled');
  }
}

class _Reference implements LyricsProvider {
  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'reference',
    name: 'reference',
    capabilities: {'lyrics'},
  );
  @override
  Future<List<SongCandidate>> search(
    String q, {
    CancellationToken? cancel,
  }) async => [
    const SongCandidate(
      providerId: 'reference',
      id: '1',
      title: 'Paper Satellites',
      artist: 'Fixture Ensemble',
    ),
  ];
  @override
  Future<SourceResult> resolve(
    SongCandidate c, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: SongCandidate(
      providerId: 'reference',
      id: '1',
      title: c.title,
      artist: c.artist,
    ),
    body: _lyrics,
  );
}

const _lyrics =
    'A paper satellite sails above the desk tonight\n'
    'Our quiet room remembers all the stories from the rain\n'
    'The morning light returns again slowly\n'
    'We sing along until the end';

String _chart(String text) => text
    .split('\n')
    .map((l) => '[C]$l')
    .join('\n');

void main() {
  group('Ultimate Guitar hostile input', () {
    test('58-digit [ch] chord is rejected quickly (no backtracking)', () {
      final hostile = 'A${'1' * 58}x';
      bounded(() {
        expect(
          () => UltimateGuitarProvider.parseText(chordSong(hostile)),
          throwsA(errorCode('invalid_response')),
        );
      });
      // Near-miss variants of the original catastrophic shape.
      for (final shape in ['A${'1' * 40}!', 'C${'#1' * 25}x', 'D${'b1' * 25}']) {
        bounded(() {
          try {
            UltimateGuitarProvider.parseText(chordSong(shape));
          } on ProviderException {
            /* Rejected or accepted, but never slow. */
          }
        });
      }
    });

    test('chord grammar still accepts real chords and rejects non-chords', () {
      for (final chord in [
        'C',
        'Am7',
        'F#m7',
        'Bb',
        'G/B',
        'Dsus4',
        'Cadd9',
        'C7/9',
        'E7#9',
        'A7(b9)',
        'Dm7b5',
        'Cmaj7',
        'Bbmaj7/D',
        'C13',
        'N.C.',
        'NC',
      ]) {
        expect(
          () => UltimateGuitarProvider.parseText(chordSong(chord)),
          returnsNormally,
          reason: chord,
        );
      }
      for (final chord in ['H', 'C!', 'Cx', 'C/', 'C/H', 'C()', 'c', 'Am7 x']) {
        expect(
          () => UltimateGuitarProvider.parseText(chordSong(chord)),
          throwsA(errorCode('invalid_response')),
          reason: chord,
        );
      }
    });

    test('"capo" followed by a long whitespace run is skipped quickly', () {
      final page = ugPage('capo${' ' * 30000}x\n$verse');
      final result = bounded(
        () => UltimateGuitarProvider.parsePage(page, ugPath),
      );
      expect(result.metadata.containsKey('capo'), false);
      final short = bounded(
        () => UltimateGuitarProvider.parsePage(
          ugPage('capo${' ' * 150}x\n$verse'),
          ugPath,
        ),
      );
      expect(short.metadata.containsKey('capo'), false);
    });

    test('capo, key and tuning preamble facts are still read', () {
      final result = UltimateGuitarProvider.parsePage(
        ugPage('Capo: 3rd fret\nKey: Am\n$verse'),
        ugPath,
      );
      expect(result.metadata['capo'], 3);
      expect(result.metadata['key'], 'Am');
    });

    test('absurdly long lines are rejected before any per-character work', () {
      final line = 'a' * 150000;
      bounded(() {
        expect(
          () => UltimateGuitarProvider.parseText('$verse\n$line'),
          throwsA(errorCode('invalid_response')),
        );
      });
    });

    test('tab expansion of a long tabbed line is linear', () {
      final tabs = '\t' * 5000;
      bounded(() {
        try {
          UltimateGuitarProvider.parseText('$tabs[ch]C[/ch]\n$verse');
        } on ProviderException {
          /* Any typed outcome is fine; only the time matters. */
        }
      });
    });
  });

  group('Genius nesting', () {
    test('20k nested elements fail as a typed error, not a stack overflow', () {
      final html =
          '<div data-lyrics-container="true">${'<span>' * 20000}text</div>';
      bounded(() {
        expect(
          () => GeniusProvider.extractLyrics(html),
          throwsA(errorCode('extraction_failed')),
        );
      }, limit: const Duration(seconds: 3));
    });
  });

  group('text hygiene', () {
    test('clean strips control and bidi characters', () {
      final rlo = String.fromCharCode(0x202e);
      final nul = String.fromCharCode(0);
      expect(clean('Ti${rlo}tle$nul!'), 'Title!');
      expect(clean('a\rb'), 'a\nb');
      expect(requiredText('Line one\nline two'), 'Line one line two');
    });

    test('over-length lyrics are a size error, not "unavailable"', () {
      expect(
        () => meaningfulLyrics('word ' * 50000),
        throwsA(
          isA<ProviderException>()
              .having((e) => e.code, 'code', 'invalid_response')
              .having((e) => e.message, 'message', 'too_large'),
        ),
      );
    });

    test('a zero duration means unknown', () {
      expect(durationValue(0), isNull);
      expect(durationValue(183), 183);
    });
  });

  group('chart candidates', () {
    SongCandidate selection() => const SongCandidate(
      providerId: 'genius',
      id: '9',
      title: 'Paper Satellites',
      artist: 'Fixture Ensemble',
    );

    test('a truncated first chart falls through to the next candidate', () async {
      final chart = _Chart({
        'short': '[C]A paper satellite',
        'full': _chart(_lyrics),
      });
      final results = await SourceDiscoveryService([
        chart,
        _Reference(),
      ]).discover(selection());
      final found = results.firstWhere((r) => r.candidate.providerId == 'chart');
      expect(found.matchKind, isNot(MatchKind.rejected));
      expect(found.candidate.id, 'full');
      expect(chart.resolved, ['short', 'full']);
    });

    test('a timed-out alternative lookup is cancelled, not abandoned', () async {
      final chart = _HangingAlternatives();
      final results = await SourceDiscoveryService([
        chart,
        _Reference(),
      ]).discover(
        selection(),
        alternativeTimeout: const Duration(milliseconds: 60),
      );
      // The source is reported rejected (no usable alternative) ...
      expect(
        results.firstWhere((r) => r.candidate.providerId == 'chart').matchKind,
        MatchKind.rejected,
      );
      // ... the blocked lookup was released by cancellation ...
      expect(
        await chart.released.future.timeout(const Duration(seconds: 2)),
        isTrue,
      );
      // ... and no further candidate was requested after the timeout.
      final before = List<String>.of(chart.resolved);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(chart.resolved, before);
      expect(chart.resolved, ['short', 'slow-1']);
    });

    test('when no chart agrees the source is still rejected', () async {
      final chart = _Chart({
        'a': '[C]A paper satellite',
        'b': '[C]Another short one',
      });
      final results = await SourceDiscoveryService([
        chart,
        _Reference(),
      ]).discover(selection());
      expect(
        results.firstWhere((r) => r.candidate.providerId == 'chart').matchKind,
        MatchKind.rejected,
      );
    });

    test('an identity mismatch does not stop the search', () async {
      final chart = _Chart(
        {'bad': _chart(_lyrics), 'good': _chart(_lyrics)},
        titles: {'bad': 'Paper Satellites'},
      );
      final found = await findMatchingSource(chart, selection());
      expect(found.matchKind, isNot(MatchKind.rejected));
      expect(found.candidate.id, 'good');
    });

    test('the identity rejection is returned once every candidate failed', () async {
      final chart = _Chart(
        {'bad': _chart(_lyrics)},
        titles: {'bad': 'Paper Satellites'},
      );
      final found = await findMatchingSource(chart, selection());
      expect(found.matchKind, MatchKind.rejected);
      expect(found.matchReason, 'identity_mismatch');
    });
  });

  group('transport timeout override', () {
    test('a per-call timeout replaces the default', () async {
      final transport = ProviderTransport(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          return http.Response('ok', 200);
        }),
        hostInterval: Duration.zero,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        transport.getText(Uri.parse('https://example.org/a')),
        throwsA(errorCode('timeout')),
      );
      expect(
        await transport.getText(
          Uri.parse('https://example.org/b'),
          timeout: const Duration(seconds: 2),
        ),
        'ok',
      );
      await transport.close();
    });
  });
}
