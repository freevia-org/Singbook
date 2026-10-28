import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/extra/acousticbrainz.dart';
import 'package:singbook/providers/provider.dart';

const mbid = 'b5d7d380-f43a-4c1f-a5de-694150b093ac';
const otherMbid = '099b148e-fe99-4b79-be6e-5078e4bb7415';

// Authored contract fixtures, not a live HTTP capture or musical validation.
JsonMap document({String title = 'Mysterons', double bpm = 164.02}) => {
  'metadata': {
    'tags': {
      'musicbrainz_recordingid': [mbid],
      'title': [title],
      'artist': ['Portishead'],
      'album': ['Dummy'],
      'genre': ['Trip-Hop'],
      'file_name': 'uploaded-analysis-input.flac',
    },
    'audio_properties': {'length': 306.973327637},
    'version': {'essentia': '2.1-beta1', 'extractor': 'music 1.0'},
  },
  'rhythm': {'bpm': bpm},
  'tonal': {'key_key': 'D#', 'key_scale': 'minor', 'key_strength': 0.616},
};

SongCandidate selection({
  String title = 'Mysterons',
  String artist = 'Portishead',
  String? album,
  double? duration,
  String recording = mbid,
}) => SongCandidate(
  providerId: 'musicbrainz',
  id: recording,
  title: title,
  artist: artist,
  album: album,
  durationSeconds: duration,
  recordingIds: {'musicbrainz': recording},
);

Matcher code(String expected) => isA<ProviderException>().having(
  (error) => error.code, 'code', expected,
);

void main() {
  late ProviderTransport transport;
  late AcousticBrainzProvider provider;
  late List<Uri> requests;
  late JsonMap counts;
  late JsonMap analyses;
  late List<List<int>> responseBytes;
  late DateTime now;

  setUp(() {
    requests = [];
    responseBytes = [];
    now = DateTime.utc(2026, 10, 28);
    counts = {mbid: {'count': 148}, 'mbid_mapping': {}};
    analyses = {
      mbid: {'0': document(), '1': document(bpm: 163.975)},
      'mbid_mapping': {},
    };
    transport = ProviderTransport(
      client: MockClient((request) async {
        requests.add(request.url);
        final bytes = utf8.encode(
          const JsonEncoder.withIndent('  ').convert(
            request.url.path.endsWith('/count') ? counts : analyses,
          ),
        );
        responseBytes.add(bytes);
        return http.Response.bytes(bytes, 200);
      }),
      hostInterval: Duration.zero,
      maxRetries: 0,
    );
    provider = AcousticBrainzProvider(
      transport,
      clock: () => now,
      requestInterval: Duration.zero,
    );
  });
  tearDown(() async => transport.close());

  test('candidate is metadata-only and off by default', () {
    expect(provider.definition.enabledByDefault, isFalse);
    expect(provider.definition.capabilities, {'metadata'});
  });

  test('title searches and missing recording context cause no HTTP', () async {
    expect(await provider.search('Mysterons Portishead'), isEmpty);
    expect(
      await provider.searchForSelection(
        const SongCandidate(providerId: 'genius', id: '1',
          title: 'Mysterons', artist: 'Portishead'),
        fallbackQuery: 'Mysterons',
      ),
      isEmpty,
    );
    expect(requests, isEmpty);
  });

  test('documented fixed-host bulk API bounds submission offsets', () async {
    final candidates = await provider.search(mbid.toUpperCase());
    expect(candidates.single.title, 'Mysterons');
    expect(candidates.single.artist, 'Portishead');
    expect(requests, hasLength(2));
    expect(requests.every((uri) => uri.host == 'acousticbrainz.org'), isTrue);
    expect(requests.first.path, '/api/v1/count');
    expect(requests.last.path, '/api/v1/low-level');
    expect(requests.last.queryParameters['recording_ids'], '$mbid:0;$mbid:1');
    expect(requests.last.queryParameters['features'], contains('metadata.tags'));
    expect(requests.last.queryParameters['features'], isNot(contains('beats_position')));
  });

  test('keeps both conflicting estimates without canonical key or timing', () async {
    final result = await provider.resolve(selection(album: 'Dummy', duration: 306.2));
    final analysis = result.metadata['acousticbrainz'] as Map;
    final samples = analysis['samples'] as List;
    expect(analysis['submissionCount'], 148);
    expect(analysis['sampledOffsets'], [0, 1]);
    expect(analysis['allSubmissionsRetrieved'], false);
    expect(samples.map((sample) => sample['estimatedBpm']), [164.02, 163.975]);
    expect(samples.first['estimateStatus'], 'unverified');
    expect(result.metadata.containsKey('key'), false);
    expect(result.metadata.containsKey('bpm'), false);
    expect(result.metadata.containsKey('tempo'), false);
    expect(result.body, isEmpty);
    expect(result.candidate.album, isNull);
    expect(result.candidate.durationSeconds, isNull);
    expect(result.candidate.recordingIds, {'musicbrainz': mbid});
    expect(result.extra['metadataOnly'], true);
  });

  test('exact original count and analysis bytes survive portable metadata', () async {
    final source = await provider.resolve(selection());
    final payloads = source.extra['originalPayloads'] as List;
    expect(base64Decode(payloads[0]['base64']), responseBytes[0]);
    expect(base64Decode(payloads[1]['base64']), responseBytes[1]);
    final rights = source.extra['rights'] as Map;
    expect(rights['license'], 'CC0');
    expect(rights['scope'], contains('publisher analysis corpus'));
    final song = SongDocument(id: 'test-analysis', title: 'Mysterons',
      artist: 'Portishead', body: '', sources: [source]);
    final roundtrip = ChordProCodec().decode(ChordProCodec().encode(song));
    expect(roundtrip.sources.single.extra, source.extra);
    expect(roundtrip.sources.single.metadata, source.metadata);
  });

  for (final wrong in [
    selection(title: 'Mysterons (Live)'),
    selection(artist: 'Another Artist'),
    selection(album: 'An Unrelated Album'),
    selection(duration: 400),
  ]) {
    test('rejects supplied context contradiction: ${wrong.toJson()}', () async {
      await expectLater(provider.resolve(wrong), throwsA(code('identity_mismatch')));
    });
  }

  test('a missing submitted album cannot satisfy supplied edition context', () async {
    for (final sample in (analyses[mbid] as Map).values) {
      (sample['metadata']['tags'] as Map).remove('album');
    }
    await expectLater(provider.resolve(selection(album: 'Dummy')),
      throwsA(code('identity_mismatch')));
  });

  test('forged own URL and conflicting or invalid MBIDs fail before HTTP', () async {
    for (final candidate in [
      const SongCandidate(providerId: 'acousticbrainz', id: mbid,
        title: 'Mysterons', artist: 'Portishead', url: 'https://evil.example/'),
      const SongCandidate(providerId: 'acousticbrainz', id: mbid,
        title: 'Mysterons', artist: 'Portishead', recordingIds: {'musicbrainz': otherMbid}),
      selection(recording: 'not-a-recording'),
      selection(artist: ''),
    ]) {
      await expectLater(provider.resolve(candidate), throwsA(code('invalid_selection')));
    }
    expect(requests, isEmpty);
  });

  test('submitted MusicBrainz tag must match requested ID', () async {
    analyses[mbid]['0']['metadata']['tags']['musicbrainz_recordingid'] = [otherMbid];
    await expectLater(provider.resolve(selection()), throwsA(code('identity_mismatch')));
  });

  test('contradictory submission titles are not silently relabelled', () async {
    analyses[mbid]['1'] = document(title: 'Another Song');
    await expectLater(provider.resolve(selection()), throwsA(code('identity_mismatch')));
  });

  test('multiple submitted artist tags are not arbitrarily selected', () async {
    analyses[mbid]['0']['metadata']['tags']['artist'] = ['Portishead', 'Someone Else'];
    await expectLater(provider.resolve(selection()), throwsA(code('invalid_response')));
  });

  test('only observed file_name allows a scalar tag, without fetching it', () async {
    analyses[mbid]['0']['metadata']['tags']['file_name'] = 'https://evil.example/audio';
    final result = await provider.resolve(selection());
    final samples = (result.metadata['acousticbrainz'] as Map)['samples'] as List;
    expect(samples.first['tags']['file_name'], 'https://evil.example/audio');
    expect(requests.every((uri) => uri.host == 'acousticbrainz.org'), isTrue);
    analyses[mbid]['0']['metadata']['tags']['artist'] = 'Portishead';
    now = now.add(const Duration(minutes: 16));
    await expectLater(provider.resolve(selection()), throwsA(code('invalid_response')));
  });

  test('omitted recordings are unavailable rather than guessed', () async {
    counts.remove(mbid);
    await expectLater(provider.resolve(selection()), throwsA(code('unavailable')));
    expect(requests, hasLength(1));
  });

  test('one-submission corpus has one offset and complete sampling', () async {
    counts[mbid]['count'] = 1;
    analyses[mbid].remove('1');
    final result = await provider.resolve(selection());
    expect((result.metadata['acousticbrainz'] as Map)['allSubmissionsRetrieved'], true);
    expect(requests.last.queryParameters['recording_ids'], '$mbid:0');
  });

  test('missing requested offset is a schema failure', () async {
    analyses[mbid].remove('1');
    await expectLater(provider.resolve(selection()), throwsA(code('invalid_response')));
  });

  test('invalid submission count is rejected before low-level request', () async {
    counts[mbid]['count'] = '148';
    await expectLater(provider.resolve(selection()), throwsA(code('invalid_response')));
    expect(requests, hasLength(1));
  });

  for (final bpm in [0.0, -1.0, 1001.0]) {
    test('invalid BPM $bpm is not accepted as musical data', () async {
      analyses[mbid]['0'] = document(bpm: bpm);
      await expectLater(provider.resolve(selection()), throwsA(code('invalid_response')));
    });
  }

  test('cache is bounded by expiry and revalidates supplied identity', () async {
    final result = await provider.resolve(selection());
    ((result.metadata['acousticbrainz'] as Map)['samples'] as List).clear();
    final again = await provider.resolve(selection());
    expect((again.metadata['acousticbrainz'] as Map)['samples'], hasLength(2));
    await expectLater(provider.resolve(selection(artist: 'Different')),
      throwsA(code('identity_mismatch')));
    expect(requests, hasLength(2));
    now = now.add(const Duration(minutes: 16));
    await provider.resolve(selection());
    expect(requests, hasLength(4));
  });

  test('cancellation before lookup never requests or caches', () async {
    final cancel = CancellationToken()..cancel();
    await expectLater(provider.resolve(selection(), cancel: cancel),
      throwsA(code('cancelled')));
    expect(requests, isEmpty);
  });

  test('cancellation during pacing prevents the next API request', () async {
    provider = AcousticBrainzProvider(
      transport,
      requestInterval: const Duration(seconds: 1),
    );
    final cancel = CancellationToken();
    final pending = provider.resolve(selection(), cancel: cancel);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    cancel.cancel();
    await expectLater(pending, throwsA(code('cancelled')));
    expect(requests, hasLength(1));
  });
}
