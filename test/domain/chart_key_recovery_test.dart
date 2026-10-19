import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/source_contributions.dart';

const _candidate = SongCandidate(
  providerId: 'catalog',
  id: 'song',
  title: 'Song',
  artist: 'Artist',
);
const _body =
    '[F#m]Amber lanterns glow\n[Bm]Silver rain returns\n'
    '[D]Across the sleepy water\n[C#]Morning brings a melody';
const _donorBody =
    '[F#m]Amber lanterns glow\n[Bm]Silver rain returns\n'
    '[D]Across the sleepy water\n[C#7]Morning brings a melody';

SourceResult _source(
  String id,
  String body, {
  JsonMap metadata = const {},
  JsonMap candidateMetadata = const {},
  MatchKind kind = MatchKind.sameSong,
}) => SourceResult(
  candidate: SongCandidate(
    providerId: id,
    id: 'song',
    title: 'Song',
    artist: 'Artist',
    metadata: candidateMetadata,
  ),
  body: body,
  metadata: metadata,
  matchKind: kind,
);

SongDocument _saved({
  String body = _body,
  JsonMap metadata = const {},
  List<SourceResult>? sources,
}) => SongDocument(
  id: 'saved',
  title: 'Song',
  artist: 'Artist',
  body: body,
  metadata: metadata,
  sources:
      sources ??
      [
        _source('donor', _donorBody, metadata: {'key': 'F#m'}),
      ],
  selectedRecording: _candidate,
);

void main() {
  test(
    'fully chorded chosen chart recovers supplied key without an overlay',
    () {
      final chart = _source('chosen', _body);
      final donor = _source('donor', _donorBody, metadata: {'key': 'F#m'});
      final song = combineSources(_candidate, [
        chart,
        donor,
      ], preferredSourceId: chart.id);
      expect(song.metadata['key'], 'F#m');
      expect(song.body, _body);
      expect(song.extra['chordSourceIds'], [chart.id]);
      expect(song.extra['fieldOrigins']['key'], donor.id);
      expect(song.extra['fieldContributors']['key'], [donor.id]);
      expect(contributingProviderIds(song), contains('donor'));
    },
  );

  test(
    'old saved chart resolves without rewriting metadata or source facts',
    () {
      final song = _saved(metadata: {'x_verse_player_transpose': 2});
      final before = jsonEncode(song.toJson());
      final key = corroboratedArrangementKey(song);
      expect(key?.key, 'F#m');
      expect(key?.sourceIds, ['donor:song']);
      expect(jsonEncode(song.toJson()), before);
    },
  );

  test('lyrics-only source key is usable without selecting its lyrics', () {
    const lyrics = 'Amber lanterns glow\nSilver rain returns';
    final song = _saved(
      body: lyrics,
      sources: [
        _source('lyrics', lyrics),
        _source('key-provider', lyrics, metadata: {'key': 'E'}),
      ],
    );

    expect(sourcedArrangementKey(song)?.key, 'E');
    expect(sourcedArrangementKey(song)?.sourceIds, ['key-provider:song']);
  });

  test('lyrics-only source conflicts and unverified claims do not win', () {
    const lyrics = 'Amber lanterns glow\nSilver rain returns';
    expect(
      sourcedArrangementKey(
        _saved(
          body: lyrics,
          sources: [
            _source('a', lyrics, metadata: {'key': 'E'}),
            _source('b', lyrics, metadata: {'key': 'G'}),
          ],
        ),
      ),
      isNull,
    );
    expect(
      sourcedArrangementKey(
        _saved(
          body: lyrics,
          sources: [
            _source(
              'unverified',
              lyrics,
              metadata: {'key': 'E'},
              kind: MatchKind.unverified,
            ),
          ],
        ),
      ),
      isNull,
    );
  });

  test('lyrics-only key source must match edition and arrangement setup', () {
    const lyrics = 'Amber lanterns glow\nSilver rain returns';
    final wrongEdition = _source(
      'acoustic',
      lyrics,
      metadata: {'key': 'E'},
    ).candidate;
    final acoustic = SourceResult(
      candidate: SongCandidate(
        providerId: wrongEdition.providerId,
        id: wrongEdition.id,
        title: 'Song (Acoustic)',
        artist: wrongEdition.artist,
      ),
      body: lyrics,
      metadata: {'key': 'E'},
      matchKind: MatchKind.sameSong,
    );
    final capoMismatch = _source(
      'capo',
      lyrics,
      metadata: {'key': 'E', 'capo': 3},
    );

    expect(
      sourcedArrangementKey(_saved(body: lyrics, sources: [acoustic])),
      isNull,
    );
    expect(
      sourcedArrangementKey(_saved(body: lyrics, sources: [capoMismatch])),
      isNull,
    );
  });

  test(
    'shortened chart warning does not erase independently corroborated key',
    () {
      final donor = SourceResult(
        candidate: _source('donor', '').candidate,
        body: _donorBody,
        metadata: {
          'key': 'F#m',
          'tuning': ['E', 'A', 'D', 'G', 'B', 'E'],
        },
        matchKind: MatchKind.rejected,
        matchReason: 'incomplete_or_different_lyrics',
      );
      final song = _saved(
        metadata: {'tuning': '[E, A, D, G, B, E]'},
        sources: [donor],
      );
      expect(corroboratedArrangementKey(song)?.key, 'F#m');
      expect(donor.matchKind, MatchKind.rejected);
      expect(donor.matchReason, 'incomplete_or_different_lyrics');
      final chosen = _source('chosen', _body, metadata: song.metadata);
      final combined = combineSources(_candidate, [
        chosen,
        donor,
      ], preferredSourceId: chosen.id);
      expect(combined.metadata['key'], 'F#m');
      expect(combined.extra['fieldOrigins']['key'], donor.id);
      expect(combined.extra['corroboratedKeySourceIds'], [donor.id]);
      expect(contributingProviderIds(combined), contains('donor'));
      final identityMismatch = SourceResult(
        candidate: donor.candidate,
        body: donor.body,
        metadata: donor.metadata,
        matchKind: MatchKind.rejected,
        matchReason: 'identity_mismatch',
      );
      expect(
        corroboratedArrangementKey(
          _saved(metadata: song.metadata, sources: [identityMismatch]),
        ),
        isNull,
      );
    },
  );

  test('enharmonic chords and compatible extensions corroborate one key', () {
    final song = _saved(
      sources: [
        _source(
          'a',
          _donorBody.replaceAll('F#m', 'Gbm'),
          metadata: {'key': 'F#m'},
        ),
        _source('b', _donorBody, candidateMetadata: {'key': 'Gb minor'}),
      ],
    );
    expect(corroboratedArrangementKey(song)?.sourceIds, ['a:song', 'b:song']);
  });

  test('different provider line breaks can still corroborate key', () {
    final donor = _donorBody.replaceFirst('glow\n', 'glow ');
    expect(
      corroboratedArrangementKey(
        _saved(
          sources: [
            _source('donor', donor, metadata: {'key': 'F#m'}),
          ],
        ),
      )?.key,
      'F#m',
    );
  });

  test('explicit saved key always wins', () {
    expect(corroboratedArrangementKey(_saved(metadata: {'key': 'A'})), isNull);
    final chosen = _source('chosen', _body, metadata: {'key': 'A'});
    expect(
      combineSources(_candidate, [
        chosen,
        ..._saved().sources,
      ], preferredSourceId: chosen.id).metadata['key'],
      'A',
    );
  });

  test(
    'deliberate key removal remains unknown despite retained source facts',
    () {
      final saved = _saved();
      final removed = saved.copyWith(
        extra: {
          'fieldOrigins': {'key': 'user'},
        },
      );
      expect(corroboratedArrangementKey(saved)?.key, 'F#m');
      expect(corroboratedArrangementKey(removed), isNull);
    },
  );

  test('flat and double-accidental pitches compare enharmonically', () {
    for (final (body, donor, key) in [
      (
        '[B]Amber lanterns glow\n[E]Silver rain returns\n[F#]Across the sleepy water',
        '[Cb]Amber lanterns glow\n[E]Silver rain returns\n[F#]Across the sleepy water',
        'Cb',
      ),
      (
        '[C]Amber lanterns glow\n[F]Silver rain returns\n[G]Across the sleepy water',
        '[Dbb]Amber lanterns glow\n[F]Silver rain returns\n[G]Across the sleepy water',
        'Dbb',
      ),
    ]) {
      expect(
        corroboratedArrangementKey(
          _saved(
            body: body,
            sources: [
              _source('donor', donor, metadata: {'key': key}),
            ],
          ),
        )?.key,
        key,
      );
    }
  });

  for (final (name, body) in [
    ('transposed', _donorBody.replaceAll('F#m', 'Em').replaceAll('Bm', 'Am')),
    ('minor versus major', _donorBody.replaceAll('F#m', 'F#')),
    ('altered fifth', _donorBody.replaceAll('F#m', 'F#m7b5')),
    ('slash bass', _donorBody.replaceAll('F#m', 'F#m/A')),
    ('one shared chord', '[F#m]Amber lanterns glow'),
    (
      'one repeated root',
      _donorBody
          .replaceAll('Bm', 'F#m')
          .replaceAll('D]', 'F#m]')
          .replaceAll('C#7', 'F#m'),
    ),
    (
      'unrelated lyrics',
      '[F#m]Quiet hills remain\n[Bm]Different stars arise\n[D]An unfamiliar journey',
    ),
    (
      'ambiguous repeated phrase',
      '[F#m]Amber lanterns glow\n[A]Amber lanterns glow\n[Bm]Silver rain returns\n[D]Across the sleepy water',
    ),
  ]) {
    test('$name does not supply a missing key', () {
      expect(
        corroboratedArrangementKey(
          _saved(
            sources: [
              _source('donor', body, metadata: {'key': 'F#m'}),
            ],
          ),
        ),
        isNull,
      );
    });
  }

  for (final key in ['F#m garbage', 'C#7', '', 'unknown', 'A']) {
    test('invalid or uncorroborated tonic "$key" is not borrowed', () {
      expect(
        corroboratedArrangementKey(
          _saved(
            sources: [
              _source('donor', _donorBody, metadata: {'key': key}),
            ],
          ),
        ),
        isNull,
      );
    });
  }

  test('conflicting supplied keys stay unresolved', () {
    expect(
      corroboratedArrangementKey(
        _saved(
          sources: [
            _source('a', _donorBody, metadata: {'key': 'F#m'}),
            _source('b', _donorBody, metadata: {'key': 'D'}),
          ],
        ),
      ),
      isNull,
    );
  });

  for (final field in ['capo', 'tuning', 'timeSignature']) {
    test(
      'incompatible or unknown $field cannot corroborate an arrangement',
      () {
        final donor = _source(
          'donor',
          _donorBody,
          metadata: {'key': 'F#m', field: 'one'},
        );
        expect(corroboratedArrangementKey(_saved(sources: [donor])), isNull);
        expect(
          corroboratedArrangementKey(
            _saved(metadata: {field: 'two'}, sources: [donor]),
          ),
          isNull,
        );
        expect(
          corroboratedArrangementKey(
            _saved(metadata: {field: 'one'}, sources: [donor]),
          )?.key,
          'F#m',
        );
      },
    );
  }

  test(
    'catalog-only key, unverified facts, or lyrics alone are insufficient',
    () {
      for (final kind in [MatchKind.unverified, MatchKind.rejected]) {
        expect(
          corroboratedArrangementKey(
            _saved(
              sources: [
                _source(
                  'donor',
                  _donorBody,
                  metadata: {'key': 'F#m'},
                  kind: kind,
                ),
              ],
            ),
          ),
          isNull,
        );
      }
      expect(
        corroboratedArrangementKey(_saved(body: 'Amber lanterns glow')),
        isNull,
      );
      final chosen = _source('chosen', _body);
      final song = combineSources(
        const SongCandidate(
          providerId: 'catalog',
          id: 'song',
          title: 'Song',
          artist: 'Artist',
          metadata: {'key': 'F#m'},
        ),
        [chosen],
      );
      expect(song.metadata.containsKey('key'), isFalse);
    },
  );
}
