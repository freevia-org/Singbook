import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';

const _selected = SongCandidate(
  providerId: 'catalog',
  id: 'selected',
  title: 'Lantern Song',
  artist: 'The Singers',
);

const _lyrics = '''
Amber lanterns glow above the quiet water
Silver rain returns beneath the evening sky
Every window keeps a little golden light
Morning carries every dream back home
''';

const _chart =
    '[G]Amber lanterns [D]glow above [Em]the quiet [C]water\n'
    '[G]Silver rain [D]returns beneath [Em]the evening [C]sky\n'
    '[G]Every window [D]keeps a [Em]little golden [C]light\n'
    '[G]Morning carries [D]every [Em]dream back [C]home';

SourceResult _source(
  String provider, {
  String body = _lyrics,
  Map<String, dynamic> metadata = const {},
  Map<String, dynamic> extra = const {},
}) => SourceResult(
  candidate: SongCandidate(
    providerId: provider,
    id: 'song',
    title: 'Lantern Song',
    artist: 'The Singers',
  ),
  body: body,
  metadata: metadata,
  matchKind: MatchKind.sameSong,
  extra: extra,
);

void main() {
  group('non-finite capo', () {
    // JSON has no infinity literal, but an overflowing number decodes to one.
    final overflowing = jsonDecode('1e999');

    test('an overflowing JSON number decodes to infinity', () {
      expect(overflowing, double.infinity);
    });

    for (final capo in [overflowing, double.nan, double.negativeInfinity]) {
      test('capo $capo combines like an unreadable capo', () {
        final combined = combineSources(_selected, [
          _source('lyrics'),
          _source('chords', body: _chart, metadata: {'capo': capo}),
        ]);
        expect(combined.body, contains('[G]Amber'));
      });

      test('capo $capo does not break key recovery or transposition', () {
        expect(soundingTransposition(_chart, capo, _chart, 0), 0);
        expect(soundingChartKey(_chart, capo), soundingChartKey(_chart, null));
        expect(
          declaredKeyFitsChords(_chart, 'G', capo),
          declaredKeyFitsChords(_chart, 'G', null),
        );
        final song = SongDocument(
          id: 'song',
          title: 'Lantern Song',
          artist: 'The Singers',
          body: _chart,
          sources: [
            _source('chords', body: _chart, metadata: {'capo': capo}),
          ],
        );
        expect(() => sourcedArrangementKey(song), returnsNormally);
        expect(() => arrangementKeySetupDiagnostics(song), returnsNormally);
      });
    }
  });

  group('malformed stored evidence', () {
    test('discovery envelope lists of another type are ignored', () {
      for (final malformed in <Object?>[
        'not a list',
        42,
        {'a': 1},
        true,
      ]) {
        final combined = combineSources(_selected, [
          _source(
            'lyrics',
            extra: {
              'sourceEvidenceSnapshots': malformed,
              'providerAlternatives': malformed,
              'discoveryEvidence': {
                'acceptedPayloads': malformed,
                'rejectedPayloads': malformed,
                'searchCandidates': malformed,
              },
            },
          ),
          _source('chords', body: _chart),
        ]);
        expect(combined.body, contains('[G]Amber'), reason: '$malformed');
      }
    });

    test('a rejected payload with a non-text reason keeps its rejection', () {
      final earlier = _source('chords', body: _chart.replaceAll('[C]', '[Am]'));
      for (final reason in <Object?>[
        42,
        {'code': 'x'},
        ['x'],
        null,
      ]) {
        final combined = combineSources(_selected, [
          _source('lyrics'),
          _source(
            'chords',
            body: _chart,
            extra: {
              'discoveryEvidence': {
                'rejectedPayloads': [
                  {'payload': earlier.toJson(), 'reason': reason},
                  'not a map',
                  {'payload': 7, 'reason': 'identity_mismatch'},
                ],
              },
            },
          ),
        ]);
        expect(combined.body, contains('[G]Amber'), reason: '$reason');
        expect(combined.body, isNot(contains('[Am]')), reason: '$reason');
      }
    });

    test('recording key analysis with malformed ids is not bound', () {
      for (final ids in <Object?>[
        'USRC17607839',
        42,
        {'isrc': 'USRC17607839'},
      ]) {
        final combined = combineSources(_selected, [
          _source('lyrics'),
          _source(
            'chords',
            body: _chart,
            extra: {
              'keyRecording': {
                'key': 'G',
                'ids': ids,
                'alternatives': 'not a list',
                'identifierSourceIds': 12,
              },
            },
          ),
        ]);
        expect(combined.body, contains('[G]Amber'), reason: '$ids');
      }
    });

    test('key recovery tolerates malformed ranking and chord source ids', () {
      for (final malformed in <Object?>[
        'not a list',
        42,
        {'a': 1},
      ]) {
        final song = SongDocument(
          id: 'song',
          title: 'Lantern Song',
          artist: 'The Singers',
          body: _chart,
          sources: [
            _source('chords', body: _chart, metadata: {'key': 'G'}),
          ],
          extra: {
            'chordSourceIds': malformed,
            'evidenceRanking': {'version': 1, 'claims': malformed},
          },
        );
        expect(sourcedArrangementKey(song)?.key, 'G', reason: '$malformed');
        expect(
          corroboratedArrangementKey(song)?.key,
          'G',
          reason: '$malformed',
        );
        expect(
          arrangementKeySetupDiagnostics(song),
          hasLength(1),
          reason: '$malformed',
        );
      }
    });
  });
}
