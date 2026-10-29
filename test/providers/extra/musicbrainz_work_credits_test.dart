import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/metadata.dart';
import 'package:singbook/providers/extra/musicbrainz_work_credits.dart';
import 'package:singbook/providers/provider.dart';

const _recording = '11111111-1111-4111-8111-111111111111';
const _work = '22222222-2222-4222-8222-222222222222';
const _artist = '33333333-3333-4333-8333-333333333333';

JsonMap _credit({
  String role = 'writer',
  String name = 'Liora Fen',
  String id = _artist,
  String direction = 'backward',
  Object? attributes = const [],
}) => {
  'target-type': 'artist',
  'type': role,
  'direction': direction,
  'attributes': attributes,
  'artist': {'id': id, 'name': name},
};
JsonMap _relation({
  String id = _work,
  String title = 'Lantern Harbor',
  String direction = 'forward',
  String type = 'performance',
  Object? attributes = const [],
  List<JsonMap>? credits,
}) => {
  'target-type': 'work',
  'type': type,
  'direction': direction,
  'attributes': attributes,
  'work': {
    'id': id,
    'title': title,
    'iswcs': ['T-123.456.789-0'],
    'languages': ['eng'],
    'relations': credits ?? [_credit()],
  },
};
JsonMap _record({List<JsonMap>? relations}) => {
  'id': _recording,
  'title': 'Lantern Harbor',
  'length': 180000,
  'artist-credit': [
    {
      'name': 'Mira Vale',
      'artist': {'id': _artist, 'name': 'Mira Vale'},
    },
  ],
  'releases': [],
  'relations': relations ?? [_relation()],
};

void main() {
  test(
    'work authors stay separate from performers and recording technical roles',
    () {
      final facts = musicBrainzWorkMetadata(
        _record(
          relations: [
            _credit(role: 'producer', name: 'Studio Person'),
            _credit(role: 'writer', name: 'Recording Relation'),
            _relation(
              credits: [
                _credit(),
                _credit(role: 'composer', name: 'Taro Wren'),
                _credit(role: 'lyricist', name: 'Neri Fox'),
              ],
            ),
          ],
        ),
      );
      expect(facts['writers'], ['Liora Fen']);
      expect(facts['composers'], ['Taro Wren']);
      expect(facts['lyricists'], ['Neri Fox']);
      expect(
        (facts['credits'] as List).map((c) => c['scope']),
        everyElement('work'),
      );
      expect(jsonEncode(facts), isNot(contains('Studio Person')));
      expect(jsonEncode(facts), isNot(contains('Recording Relation')));
      final work = (facts['musicbrainzWorks'] as List).single;
      expect(work['musicbrainzWorkId'], _work);
      expect(work['iswcs'], ['T-123.456.789-0']);
      expect(work['languages'], ['eng']);
    },
  );

  for (final reason in [
    'multiple',
    'different title',
    'medley',
    'partial',
    'wrong direction',
    'wrong type',
    'malformed work',
  ]) {
    test(
      '$reason association retains scoped facts without flat authorship',
      () {
        final relation = _relation(
          title: reason == 'different title'
              ? 'Another Composition'
              : 'Lantern Harbor',
          direction: reason == 'wrong direction' ? 'backward' : 'forward',
          type: reason == 'wrong type' ? 'samples material' : 'performance',
          attributes: reason == 'medley' || reason == 'partial' ? [reason] : [],
        );
        final facts = musicBrainzWorkMetadata(
          _record(
            relations: [
              relation,
              if (reason == 'multiple')
                _relation(id: '44444444-4444-4444-8444-444444444444'),
              if (reason == 'malformed work') _relation(id: 'invalid'),
            ],
          ),
        );
        expect(facts['musicbrainzWorks'], isNotEmpty);
        expect(facts.containsKey('credits'), false);
        expect(facts.containsKey('writers'), false);
      },
    );
  }

  test(
    'missing or malformed credit attributes and reverse artist roles cannot donate',
    () {
      for (final credit in [
        _credit(attributes: null),
        _credit(attributes: 'invalid'),
        _credit(direction: 'forward'),
        _credit(id: 'invalid'),
      ]) {
        final facts = musicBrainzWorkMetadata(
          _record(
            relations: [
              _relation(credits: [credit]),
            ],
          ),
        );
        expect(facts.containsKey('credits'), false);
        expect(facts.containsKey('writers'), false);
      }
    },
  );

  test('bounded authors do not claim complete credits after truncation', () {
    final facts = musicBrainzWorkMetadata(
      _record(
        relations: [
          _relation(
            credits: [
              for (var i = 0; i < 31; i++)
                _credit(
                  id: '${i.toString().padLeft(8, '0')}-4444-4444-8444-444444444444',
                  name: 'Invented Writer $i',
                ),
            ],
          ),
        ],
      ),
    );
    final work = (facts['musicbrainzWorks'] as List).single;
    expect(work['artistCreditEntriesReported'], 31);
    expect(work['artistCreditEntriesRetained'], 30);
    expect(work['credits'], hasLength(30));
    expect(facts.containsKey('writers'), false);
    expect(facts.containsKey('credits'), false);
  });

  test(
    'malformed sibling relationships do not prove a complete work association',
    () {
      final data = _record();
      (data['relations'] as List).add('invalid relationship');
      final facts = musicBrainzWorkMetadata(data);
      expect(facts['musicbrainzWorks'], hasLength(1));
      expect(facts.containsKey('credits'), false);
      expect(facts.containsKey('writers'), false);
    },
  );

  test(
    'provider requests work-level roles in its single recording request and preserves portable credits',
    () async {
      final requests = <Uri>[];
      final transport = ProviderTransport(
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(jsonEncode(_record()), 200);
        }),
        hostInterval: Duration.zero,
        maxRetries: 0,
      );
      addTearDown(transport.close);
      final selected = const SongCandidate(
        providerId: 'musicbrainz',
        id: _recording,
        title: 'Lantern Harbor',
        artist: 'Mira Vale',
        durationSeconds: 180,
      );
      final result = await MusicBrainzProvider(transport).resolve(selected);
      expect(requests, hasLength(1));
      expect(
        requests.single.queryParameters['inc']!.split('+'),
        containsAll(['work-rels', 'artist-rels', 'work-level-rels']),
      );
      expect(result.metadata['writers'], ['Liora Fen']);
      expect(
        (result.metadata['musicbrainzWorks'] as List)
            .single['credits']
            .single['name'],
        'Liora Fen',
      );
      expect(result.candidate.artist, 'Mira Vale');
      expect(result.candidate.recordingIds, {'musicbrainz': _recording});
      expect(result.timingTracks, isEmpty);
      final lyricSelection = SongCandidate(
        providerId: 'genius',
        id: 'invented-song',
        title: selected.title,
        artist: selected.artist,
        durationSeconds: selected.durationSeconds,
        recordingIds: const {'musicbrainz': _recording},
      );
      final lyrics = SourceResult(
        candidate: lyricSelection,
        body:
            'Invented lanterns drift across the bay\nPaper gardens catch the evening rain',
      );
      final document = combineSources(lyricSelection, [lyrics, result]);
      expect(document.metadata['writers'], ['Liora Fen']);
      expect(document.metadata['credits'], result.metadata['credits']);
      final reopened = ChordProCodec().decode(ChordProCodec().encode(document));
      final retained = reopened.sources.singleWhere(
        (s) => s.candidate.providerId == 'musicbrainz',
      );
      expect(retained.metadata, result.metadata);
      expect(retained.extra['rights'], result.extra['rights']);
    },
  );
}
