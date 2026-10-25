import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/source_contributions.dart';
import 'package:singbook/providers/core/service.dart';
import 'package:singbook/providers/provider.dart';

// Invented lyrics. The recording includes two interjections omitted by its
// otherwise complete chord chart; shared vocabulary alone is insufficient.
const _line = 'Silver lanterns guide our quiet boat across blue water';
const _reference = '$_line\noh\n$_line\n$_line\nah\n$_line';
const _chart = '[C]$_line\n[C]$_line\n[C]$_line\n[C]$_line';
const _selection = SongCandidate(
  providerId: 'genius',
  id: 'original',
  title: 'Río de Luz',
  artist: 'María del Sol',
  metadata: {'identityScope': 'recording', 'version': 'studio'},
);

class _Provider implements LyricsProvider {
  _Provider(this.candidate, this.body, {this.charts = false});
  final SongCandidate candidate;
  final String body;
  final bool charts;
  var resolves = 0;

  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: candidate.providerId,
    name: candidate.providerId,
    capabilities: {'catalog', 'lyrics', if (charts) 'chords'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [candidate];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    resolves++;
    cancel?.throwIfCancelled();
    return SourceResult(candidate: candidate, body: body);
  }
}

_Provider _donor({String body = _chart, String? title, String? artist}) =>
    _Provider(
      SongCandidate(
        providerId: 'ultimateguitar',
        id: 'chart',
        title: title ?? 'Rio de Luz',
        artist: artist ?? 'Maria del Sol',
      ),
      body,
      charts: true,
    );

class _VotingProvider implements LyricsProvider {
  _VotingProvider(this.id, this.bodies);
  final String id;
  final List<String> bodies;
  @override
  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: id,
    capabilities: const {'catalog', 'lyrics', 'chords'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [
    for (var i = 0; i < bodies.length; i++)
      SongCandidate(
        providerId: id,
        id: '$i',
        title: _selection.title,
        artist: _selection.artist,
      ),
  ];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async =>
      SourceResult(candidate: candidate, body: bodies[int.parse(candidate.id)]);
}

void main() {
  test(
    'long unanchored lyrics cannot publish a mismatching short donor',
    () async {
      final published = <SourceResult>[];
      final results =
          await SourceDiscoveryService([
            _Provider(_selection, _reference),
            _Provider(
              const SongCandidate(
                providerId: 'lrclib',
                id: 'longer',
                title: 'Río de Luz',
                artist: 'María del Sol',
              ),
              '$_reference\nDistant bells awaken',
            ),
            _donor(body: _chart.replaceFirst('guide our', 'our guide')),
          ]).discover(
            _selection,
            onProgress: (check) {
              final source = check.result;
              if (source != null &&
                  source.hasChords &&
                  source.matchKind != MatchKind.rejected) {
                published.add(source);
              }
            },
          );
      expect(published, isEmpty);
      expect(
        results.where((r) => r.hasChords && r.matchKind != MatchKind.rejected),
        isEmpty,
      );
    },
  );

  test('ordinary stored short-reference donors also require word order', () {
    final sources = [
      SourceResult(
        candidate: _selection,
        body: _reference,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: const SongCandidate(
          providerId: 'ultimateguitar',
          id: 'ordinary',
          title: 'Río de Luz',
          artist: 'María del Sol',
        ),
        body: _chart.replaceFirst('guide our', 'our guide'),
        matchKind: MatchKind.sameSong,
      ),
    ];
    final combined = combineSources(_selection, sources);
    expect(plainLyrics(combined.body), _reference);
    expect(
      contributingProviderIds(combined),
      isNot(contains('ultimateguitar')),
    );
    final chosen = combineSources(
      _selection,
      sources,
      preferredSourceId: sources.last.id,
    );
    expect(plainLyrics(chosen.body), plainLyrics(sources.last.body));
  });

  test(
    'unanchored long lyrics cannot override short recording corroboration',
    () {
      final combined = combineSources(_selection, [
        SourceResult(
          candidate: _selection,
          body: _reference,
          matchKind: MatchKind.sameRecording,
        ),
        const SourceResult(
          candidate: SongCandidate(
            providerId: 'lrclib',
            id: 'another-performance',
            title: 'Río de Luz',
            artist: 'María del Sol',
          ),
          body:
              'A different performance tells another story beside the harbor\n'
              'Morning birds awaken distant sailors under unfamiliar skies',
          matchKind: MatchKind.sameSong,
        ),
        SourceResult(
          candidate: _donor().candidate,
          body: _chart.replaceFirst('guide our', 'our guide'),
          matchKind: MatchKind.sameSong,
          extra: const {'requiresLyricsAgreement': true},
        ),
      ]);
      expect(plainLyrics(combined.body), _reference);
      expect(
        contributingProviderIds(combined),
        isNot(contains('ultimateguitar')),
      );
    },
  );

  test(
    'short chart words cannot supply key votes without a recording reference',
    () async {
      String chart(List<String> chords) => [
        for (var i = 0; i < 4; i++)
          '[${chords[i * 2]}]Silver lanterns guide our '
              '[${chords[i * 2 + 1]}]quiet boat across blue water',
      ].join('\n');
      final g = chart(['G', 'C', 'Em', 'A', 'Bm', 'D', 'C', 'G']);
      final e = chart(['E', 'A', 'C#m', 'F#', 'G#m', 'B', 'A', 'E']);
      final e2 = chart(['E', 'A', 'C#m7', 'F#7', 'G#m', 'B7', 'A', 'E']);
      final results = await SourceDiscoveryService([
        _VotingProvider('first-charts', [g, e, e2]),
        _VotingProvider('second-charts', [e]),
      ]).discover(_selection);
      expect(results.where((r) => r.hasChords), hasLength(2));
      expect(
        results.every((r) => !r.extra.containsKey('keyConsensus')),
        isTrue,
      );
    },
  );

  test('stored flags cannot bypass short-reference word order at combine', () {
    final combined = combineSources(_selection, [
      SourceResult(
        candidate: _selection,
        body: _reference,
        matchKind: MatchKind.sameRecording,
      ),
      SourceResult(
        candidate: _donor().candidate,
        body: _chart.replaceFirst('guide our', 'our guide'),
        matchKind: MatchKind.sameSong,
        extra: const {'requiresLyricsAgreement': true},
      ),
    ]);
    expect(plainLyrics(combined.body), _reference);
    expect(
      contributingProviderIds(combined),
      isNot(contains('ultimateguitar')),
    );
  });

  test(
    'conflicting recording IDs defeat accent-only arrangement aliases',
    () async {
      const selected = SongCandidate(
        providerId: 'genius',
        id: 'identified',
        title: 'Río de Luz',
        artist: 'María del Sol',
        metadata: {'identityScope': 'recording'},
        recordingIds: {'isrc': 'original-recording'},
      );
      const other = SongCandidate(
        providerId: 'ultimateguitar',
        id: 'other-recording',
        title: 'Rio de Luz',
        artist: 'Maria del Sol',
        recordingIds: {'isrc': 'different-recording'},
      );
      final provider = _Provider(other, _chart, charts: true);
      expect(sameArrangement(selected, other, provider), isFalse);
      final result = combineSources(selected, [
        SourceResult(
          candidate: selected,
          body: _reference,
          matchKind: MatchKind.sameRecording,
        ),
        SourceResult(
          candidate: other,
          body: _chart,
          matchKind: MatchKind.sameSong,
          extra: const {'requiresLyricsAgreement': true},
        ),
      ]);
      expect(
        contributingProviderIds(result),
        isNot(contains('ultimateguitar')),
      );
    },
  );

  test(
    'ambiguous harmony on repeated identical words is not guessed',
    () async {
      final results = await SourceDiscoveryService([
        _Provider(_selection, _reference),
        _donor(body: '[C]$_line\n[G]$_line\n[Am]$_line\n[F]$_line'),
      ]).discover(_selection);
      final combined = combineSources(_selection, results);
      expect(plainLyrics(combined.body), _reference);
      expect(
        parseArrangement(combined.body).every((line) => line.chords.isEmpty),
        isTrue,
      );
    },
  );

  test(
    'unverified stored short lyrics cannot authorize automatic chart use',
    () {
      final combined = combineSources(_selection, [
        SourceResult(
          candidate: _selection,
          body: _reference,
          matchKind: MatchKind.unverified,
        ),
        SourceResult(
          candidate: _donor().candidate,
          body: _chart,
          matchKind: MatchKind.sameSong,
          extra: const {'requiresLyricsAgreement': true},
        ),
      ]);
      expect(plainLyrics(combined.body), _reference);
      expect(
        parseArrangement(combined.body).every((line) => line.chords.isEmpty),
        isTrue,
      );
    },
  );

  test(
    'accent-only chart title/credit needs full recording lyric evidence',
    () async {
      final donor = _donor();
      expect(sameSong(_selection, donor.candidate), isFalse);
      final results = await SourceDiscoveryService([
        _Provider(_selection, _reference),
        donor,
      ]).discover(_selection);
      final chart = results.singleWhere((r) => r.hasChords);
      expect(chart.matchKind, MatchKind.sameSong);
      expect(chart.extra['requiresLyricsAgreement'], isTrue);
      final combined = combineSources(_selection, results);
      expect(plainLyrics(combined.body), _reference);
      expect(contributingProviderIds(combined), contains('ultimateguitar'));
      expect(
        parseArrangement(combined.body).any((l) => l.chords.isNotEmpty),
        isTrue,
      );
    },
  );

  test(
    'a same-song-only short reference cannot authorize an alias chart',
    () async {
      final results = await SourceDiscoveryService([
        _Provider(
          const SongCandidate(
            providerId: 'lrclib',
            id: 'unanchored',
            title: 'Río de Luz',
            artist: 'María del Sol',
          ),
          _reference,
        ),
        _donor(),
      ]).discover(_selection);
      expect(
        results.where((r) => r.hasChords && r.matchKind != MatchKind.rejected),
        isEmpty,
      );
    },
  );

  test(
    'short matching refrain cannot authorize a chart with a different verse',
    () async {
      final results = await SourceDiscoveryService([
        _Provider(
          _selection,
          '$_reference\nDistant morning winds awaken every sleeping sailor',
        ),
        _donor(),
      ]).discover(_selection);
      expect(
        results.where((r) => r.hasChords && r.matchKind != MatchKind.rejected),
        isEmpty,
      );
    },
  );

  test(
    'accent aliases do not erase ñ or recording edition qualifiers',
    () async {
      for (final title in ['Rino de Luz', 'Rio de Luz (Live)']) {
        final donor = _donor(title: title);
        final results = await SourceDiscoveryService([
          _Provider(_selection, _reference),
          donor,
        ]).discover(_selection);
        final combined = combineSources(_selection, results);
        expect(
          contributingProviderIds(combined),
          isNot(contains('ultimateguitar')),
        );
      }
      const enie = SongCandidate(
        providerId: 'genius',
        id: 'enie',
        title: 'Peña Azul',
        artist: 'María del Sol',
      );
      expect(
        sameArrangement(enie, _donor(title: 'Pena Azul').candidate, _donor()),
        isFalse,
      );
    },
  );

  test(
    'disabling a short recording reference withdraws its chart donor',
    () async {
      final cancelled = CancellationToken();
      var published = false;
      final results =
          await SourceDiscoveryService([
            _Provider(_selection, _reference),
            _donor(),
          ]).discover(
            _selection,
            providerCancellation: {'genius': cancelled},
            onProgress: (check) {
              if (!published &&
                  check.result?.hasChords == true &&
                  check.result?.matchKind != MatchKind.rejected) {
                published = true;
                cancelled.cancel();
              }
            },
          );
      expect(published, isTrue);
      expect(
        results.where((r) => r.hasChords && r.matchKind != MatchKind.rejected),
        isEmpty,
      );
    },
  );
}
