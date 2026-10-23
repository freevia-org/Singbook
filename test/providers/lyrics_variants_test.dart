import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/arrangement.dart';
import 'package:singbook/domain/lyrics_variants.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/transport.dart';

const partial =
    'silver lantern crosses the quiet harbor\n'
    'small rivers carry every message home';
const full =
    '$partial\n'
    'morning bells awaken the fields beyond\n'
    'a careful wind returns to shore';
const fuller =
    '$full\n'
    'stars gather above old harbor\n'
    'soft lights carry morning through streets';
const short =
    'silver lantern crosses the quiet harbor\n'
    'small rivers carry every message home';
const conflict =
    'another vessel circles the distant island\n'
    'bright windows scatter shadows across water';
const fullLrc =
    '[00:01.00]silver lantern crosses the quiet harbor\n'
    '[00:05.00]small rivers carry every message home\n'
    '[00:09.00]morning bells awaken the fields beyond\n'
    '[00:13.00]a careful wind returns to shore';
const shortLrc =
    '[00:01.00]silver lantern crosses the quiet harbor\n'
    '[00:05.00]small rivers carry every message home';
const fullKaraoke =
    '[00:01.00]<00:01.00>silver <00:01.50>lantern crosses the quiet harbor\n'
    '[00:05.00]<00:05.00>small rivers carry every message home\n'
    '[00:09.00]<00:09.00>morning bells awaken the fields beyond\n'
    '[00:13.00]<00:13.00>a careful wind returns to shore';

ProviderTransport _wire(Object Function(http.Request) response) =>
    ProviderTransport(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(response(request)),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      hostInterval: Duration.zero,
    );

Map<String, Object?> _lrclibRecord({
  required String plain,
  required String synced,
}) => {
  'id': 21,
  'trackName': 'Invented Harbor Song',
  'artistName': 'Fixture Artist',
  'albumName': 'Fixture Album',
  'duration': 100,
  'plainLyrics': plain,
  'syncedLyrics': synced,
};

Map<String, Object?> _syncRecord({
  required String plain,
  required String synced,
  required String karaoke,
}) => {
  'id': 'a' * 32,
  'track': 'Invented Harbor Song',
  'artist': 'Fixture Artist',
  'album': 'Fixture Album',
  'duration': 100,
  'lyrics': {'plain': plain, 'synced': synced, 'karaoke': karaoke},
};

String _oversizedText(int length) => List.filled(length, 'x').join();

Matcher _invalidResponse() => isA<ProviderException>().having(
  (error) => error.code,
  'code',
  'invalid_response',
);

void main() {
  group('compatible lyric variants', () {
    test('promotes an ordered fuller same-work variant', () {
      expect(preferCompatibleLyrics(partial, [full]), full);
    });

    test('keeps the fullest ordered variant and ignores a later conflict', () {
      expect(preferCompatibleLyrics(partial, [full, fuller, conflict]), fuller);
    });

    test('does not truncate fuller plain lyrics to a shorter variant', () {
      expect(preferCompatibleLyrics(full, [short]), full);
    });

    test('does not replace text with a contradictory variant', () {
      expect(preferCompatibleLyrics(partial, [conflict]), partial);
    });

    test('does not promote a tiny common fragment into unrelated text', () {
      expect(
        preferCompatibleLyrics('hello there friend', [
          'hello there friend and strangers',
        ]),
        'hello there friend',
      );
    });
  });

  group('catalog variant retention', () {
    test(
      'LRCLIB promotes compatible synced lyrics and preserves exact binding',
      () async {
        final record = _lrclibRecord(plain: partial, synced: fullLrc);
        final transport = _wire((_) => record);
        try {
          final result = await LrclibProvider(transport).resolve(
            const SongCandidate(
              providerId: 'lrclib',
              id: '21',
              title: 'Invented Harbor Song',
              artist: 'Fixture Artist',
            ),
          );
          final track = result.timingTracks.single;
          expect(plainLyrics(result.body), full);
          expect(track.raw, fullLrc);
          expect(
            lyricOrderHash(result.body),
            lyricOrderHash(track.sourceLyrics),
          );
          expect(
            bindImportedTiming(track, result.body).status,
            TimingStatus.usable,
          );
          expect(result.extra['lyricsVariants'], {
            'plain': partial,
            'synced': fullLrc,
            'selected': 'synced',
          });
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'LRCLIB keeps fuller plain text when synced text is shorter',
      () async {
        final record = _lrclibRecord(plain: full, synced: shortLrc);
        final transport = _wire((_) => record);
        try {
          final result = await LrclibProvider(transport).resolve(
            const SongCandidate(
              providerId: 'lrclib',
              id: '21',
              title: 'Invented Harbor Song',
              artist: 'Fixture Artist',
            ),
          );
          expect(plainLyrics(result.body), full);
          expect(result.extra['lyricsVariants'], {
            'plain': full,
            'synced': shortLrc,
            'selected': 'plain',
          });
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'SyncLRC skips a short synced variant and selects compatible karaoke',
      () async {
        final row = _syncRecord(
          plain: partial,
          synced: shortLrc,
          karaoke: fullKaraoke,
        );
        final transport = _wire(
          (_) => {
            'results': [row],
          },
        );
        try {
          final provider = SyncLrcProvider(transport);
          final candidate = (await provider.search(
            'Invented Harbor Song',
          )).single;
          final result = await provider.resolve(candidate);
          expect(plainLyrics(result.body), full);
          expect(result.timingTracks.map((track) => track.raw), [
            shortLrc,
            fullKaraoke,
          ]);
          expect(result.timingTracks.last.granularity, 'word');
          expect(result.extra['lyricsVariants'], {
            'plain': partial,
            'synced': shortLrc,
            'karaoke': fullKaraoke,
            'selected': 'karaoke',
          });
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'SyncLRC labels karaoke when the earlier synced track is invalid',
      () async {
        const malformedSynced = '[00:99.00]invalid first track text';
        final row = _syncRecord(
          plain: partial,
          synced: malformedSynced,
          karaoke: fullKaraoke,
        );
        final transport = _wire(
          (_) => {
            'results': [row],
          },
        );
        try {
          final provider = SyncLrcProvider(transport);
          final candidate = (await provider.search(
            'Invented Harbor Song',
          )).single;
          final result = await provider.resolve(candidate);
          expect(plainLyrics(result.body), full);
          expect(result.timingTracks.map((track) => track.raw), [
            malformedSynced,
            fullKaraoke,
          ]);
          expect(result.timingTracks.first.status, TimingStatus.invalid);
          expect(
            lyricOrderHash(result.body),
            lyricOrderHash(result.timingTracks.last.sourceLyrics),
          );
          expect(
            bindImportedTiming(result.timingTracks.last, result.body).status,
            TimingStatus.usable,
          );
          expect(result.extra['lyricsVariants'], {
            'plain': partial,
            'synced': malformedSynced,
            'karaoke': fullKaraoke,
            'selected': 'karaoke',
          });
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'SyncLRC retains contradictory plain text and both raw tracks',
      () async {
        final row = _syncRecord(
          plain: partial,
          synced: '[00:01.00]${conflict.split('\n').first}',
          karaoke: '[00:01.00]${conflict.split('\n').last}',
        );
        final transport = _wire(
          (_) => {
            'results': [row],
          },
        );
        try {
          final provider = SyncLrcProvider(transport);
          final candidate = (await provider.search(
            'Invented Harbor Song',
          )).single;
          final result = await provider.resolve(candidate);
          expect(plainLyrics(result.body), partial);
          expect(result.timingTracks, hasLength(2));
          expect(result.extra['lyricsVariants'], {
            'plain': partial,
            'synced': (row['lyrics'] as Map)['synced'],
            'karaoke': (row['lyrics'] as Map)['karaoke'],
            'selected': 'plain',
          });
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'malformed LRC remains preserved but cannot supply candidate lyrics',
      () async {
        const malformed = '[00:99.00]untrusted timestamp text';
        final record = _lrclibRecord(plain: partial, synced: malformed);
        final transport = _wire((_) => record);
        try {
          final result = await LrclibProvider(transport).resolve(
            const SongCandidate(
              providerId: 'lrclib',
              id: '21',
              title: 'Invented Harbor Song',
              artist: 'Fixture Artist',
            ),
          );
          expect(plainLyrics(result.body), partial);
          expect(result.timingTracks.single.status, TimingStatus.invalid);
          expect(result.timingTracks.single.raw, malformed);
          expect(result.extra['lyricsVariants'], {
            'plain': partial,
            'synced': malformed,
            'selected': 'plain',
          });
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'LRCLIB rejects oversized plain lyrics instead of dropping their history',
      () async {
        final record = _lrclibRecord(plain: _oversizedText(200001), synced: '');
        final transport = _wire((_) => record);
        try {
          await expectLater(
            LrclibProvider(transport).resolve(
              const SongCandidate(
                providerId: 'lrclib',
                id: '21',
                title: 'Invented Harbor Song',
                artist: 'Fixture Artist',
              ),
            ),
            throwsA(_invalidResponse()),
          );
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'LRCLIB rejects oversized synced payload instead of dropping its raw timing',
      () async {
        final record = _lrclibRecord(
          plain: partial,
          synced: '[00:01.00]${_oversizedText(200001)}',
        );
        final transport = _wire((_) => record);
        try {
          await expectLater(
            LrclibProvider(transport).resolve(
              const SongCandidate(
                providerId: 'lrclib',
                id: '21',
                title: 'Invented Harbor Song',
                artist: 'Fixture Artist',
              ),
            ),
            throwsA(_invalidResponse()),
          );
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'SyncLRC rejects oversized plain lyrics carried by the selected record',
      () async {
        final row = _syncRecord(
          plain: _oversizedText(200001),
          synced: '',
          karaoke: '',
        );
        final transport = _wire(
          (_) => {
            'results': [row],
          },
        );
        try {
          final provider = SyncLrcProvider(transport);
          final candidate = (await provider.search(
            'Invented Harbor Song',
          )).single;
          await expectLater(
            provider.resolve(candidate),
            throwsA(_invalidResponse()),
          );
        } finally {
          await transport.close();
        }
      },
    );

    test(
      'SyncLRC rejects oversized synced payload instead of dropping its raw timing',
      () async {
        final oversizedTiming = List.filled(20001, '[00:01.00]x').join('\n');
        final row = _syncRecord(
          plain: partial,
          synced: oversizedTiming,
          karaoke: '',
        );
        final transport = _wire(
          (_) => {
            'results': [row],
          },
        );
        try {
          final provider = SyncLrcProvider(transport);
          final candidate = (await provider.search(
            'Invented Harbor Song',
          )).single;
          await expectLater(
            provider.resolve(candidate),
            throwsA(_invalidResponse()),
          );
        } finally {
          await transport.close();
        }
      },
    );
  });
}
