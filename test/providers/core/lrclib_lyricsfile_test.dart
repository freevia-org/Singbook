import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/provider.dart';

const _plain = 'A 👍🏽 light';
const _lrc = '[00:01.025]$_plain';
const _yaml =
    '''
version: '1.0'
lines:
  - text: '$_plain'
    start_ms: 1025
    end_ms: 3010
    words:
      - text: 'A '
        start_ms: 1025
      - text: '👍🏽 '
        start_ms: 1443
        end_ms: 1703
      - text: light
        start_ms: 1900
''';

Map<String, dynamic> _record(String yaml, {bool wordSync = true}) => {
  'id': 7,
  'artistName': 'Fixture Artist',
  'trackName': 'Fixture Track',
  'albumName': 'Fixture Album',
  'duration': 213,
  'hasWordSync': wordSync,
  'plainLyrics': _plain,
  'syncedLyrics': _lrc,
  'lyricsfile': yaml,
};

Future<SourceResult> _resolve(Map<String, dynamic> record) async {
  final transport = ProviderTransport(
    client: MockClient((request) async {
      expect(request.url.path, '/api/get/7');
      return http.Response(
        jsonEncode(record),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  try {
    final provider = LrclibProvider(transport);
    return await provider.resolve(LrclibProvider.parseSong(_record(_yaml)));
  } finally {
    await transport.close();
  }
}

void main() {
  test(
    'keeps exact raw YAML, microsecond cues, graphemes and record identity',
    () async {
      final source = await _resolve(_record(_yaml));
      expect(source.body, _plain);
      expect(source.attribution, 'LRCLIB');
      expect(source.candidate.album, 'Fixture Album');
      expect(source.candidate.durationSeconds, 213);
      expect(source.timingTracks.map((t) => t.format), ['lyricsfile', 'lrc']);
      final track = source.timingTracks.first;
      expect(track.raw, _yaml);
      expect(track.granularity, 'word');
      expect(track.sourceDocumentId, 'lrclib:7');
      expect(track.recordingId, 'lrclib:7');
      expect(track.status, TimingStatus.unverified);
      final emoji = track.cues.singleWhere((cue) => cue.text == '👍🏽');
      expect((emoji.startUs, emoji.endUs), (1443000, 1703000));
      expect((emoji.graphemeStart, emoji.graphemeEnd), (2, 3));
      final codec = ChordProCodec();
      final saved = SongDocument(
        id: 'fixture',
        title: source.candidate.title,
        artist: source.candidate.artist,
        body: source.body,
        selectedRecording: source.candidate,
        timingTracks: source.timingTracks,
        sources: [source],
      );
      final restored = codec.decode(codec.encode(saved));
      expect(restored.timingTracks.first.toJson(), track.toJson());
      expect(restored.selectedRecording?.identity, 'lrclib:7');
    },
  );

  test(
    'keeps LRC when word timing is malformed, oversized or unadvertised',
    () async {
      for (final record in [
        _record(_yaml.replaceFirst('1443', '-1')),
        _record(_yaml.replaceFirst('1703', '9999')),
        _record(_yaml.replaceFirst("text: '👍🏽 '", "text: 'different '")),
        _record(_yaml.replaceFirst("'1.0'", "'2.0'")),
        _record(_yaml.replaceFirst('words:', 'words: [broken')),
        _record('x' * (96 * 1024 + 1)),
        _record(_yaml, wordSync: false),
      ]) {
        final source = await _resolve(record);
        expect(source.body, _plain);
        expect(source.timingTracks.single.raw, _lrc);
      }
    },
  );

  test('does not attach timing from a different record id', () async {
    await expectLater(
      _resolve({..._record(_yaml), 'id': 8}),
      throwsA(isA<ProviderException>()),
    );
  });

  test(
    'resolves live LRCLIB editions from search and by exact ID',
    () async {
      final transport = ProviderTransport(maxRetries: 0);
      try {
        final provider = LrclibProvider(transport);
        for (final (id, title, artist, album, findViaSearch) in [
          (
            '7758306',
            'Billie Jean',
            'Michael Jackson',
            'Thriller (25th Anniversary)',
            false,
          ),
          (
            '7243962',
            'Creep',
            'Radiohead',
            'EMI Special Markets Presents a World of Music',
            false,
          ),
          ('3816781', 'Billie Jean', 'Michael Jackson', 'Billie Jean', true),
          ('1004644', 'Creep', 'Radiohead', 'Creep', true),
        ]) {
          final candidate = findViaSearch
              ? (await provider.search(
                  '$title $artist',
                )).singleWhere((row) => row.id == id)
              : SongCandidate(
                  providerId: 'lrclib',
                  id: id,
                  title: title,
                  artist: artist,
                );
          final source = await provider.resolve(candidate);
          expect(source.candidate.identity, 'lrclib:$id');
          expect(source.candidate.title, title);
          expect(source.candidate.artist, artist);
          expect(source.candidate.album, album);
          expect(source.body, isNotEmpty);
          final track = source.timingTracks.singleWhere(
            (t) => t.format == 'lyricsfile',
          );
          expect(track.granularity, 'word');
          expect(
            track.cues.where((c) => c.graphemeStart != null).length,
            greaterThan(100),
          );
          expect(track.recordingId, 'lrclib:$id');
          expect(track.status, TimingStatus.unverified);
        }
      } finally {
        await transport.close();
      }
    },
    skip: !const bool.fromEnvironment('SINGBOOK_LRCLIB_LIVE'),
  );
}
