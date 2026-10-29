import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/acousticbrainz_analysis.dart';

Map<String, Object?> _metadata() => {
  'acousticbrainz': {
    'recordingMbid': 'b5d7d380-f43a-4c1f-a5de-694150b093ac',
    'submissionCount': 148,
    'musicalAccuracy': 'unverified',
    'samples': [
      for (var i = 0; i < 2; i++)
        {
          'submissionOffset': i,
          'estimatedBpm': 108.25 + i,
          'estimatedKey': {'tonic': 'C#', 'scale': 'minor', 'strength': .75},
          'estimateStatus': 'unverified',
          'tags': {'file_name': '/private/uploaded-file.mp3'},
          'extractorVersion': {'unsafe': '<html>untrusted</html>'},
        },
    ],
  },
};

AcousticBrainzAnalysis? _parse(Map<String, Object?> metadata) =>
    AcousticBrainzAnalysis.fromMetadata('acousticbrainz', metadata);

void main() {
  test('sample offset must refer to an existing submission', () {
    final metadata = _metadata();
    final raw = metadata['acousticbrainz'] as Map;
    raw['submissionCount'] = 1;
    raw['samples'] = [(raw['samples'] as List).last];
    expect(_parse(metadata), isNull);
  });

  test(
    'preserves sample facts and labels while excluding private arbitrary data',
    () {
      final source = _metadata();
      final analysis = _parse(source)!;
      expect(analysis.submissionCount, 148);
      expect(analysis.allSubmissionsShown, isFalse);
      expect(analysis.samples.map((s) => s.bpm), [108.25, 109.25]);
      expect(analysis.samples.first.tonic, 'C#');
      expect(analysis.samples.first.scale, 'minor');
      expect(analysis.samples.first.keyStrength, .75);
      final safe = jsonEncode(analysis.toMetadata());
      expect(safe, isNot(contains('uploaded-file')));
      expect(safe, isNot(contains('untrusted')));
      expect(safe, isNot(contains('extractorVersion')));
      expect(source.toString(), contains('uploaded-file'));
      expect(
        _parse({'acousticbrainz': analysis.toMetadata()})!.toMetadata(),
        analysis.toMetadata(),
      );
    },
  );

  test(
    'never treats another provider or verified-accuracy assertion as this analysis',
    () {
      expect(
        AcousticBrainzAnalysis.fromMetadata('musicbrainz', _metadata()),
        isNull,
      );
      final metadata = _metadata();
      (metadata['acousticbrainz'] as Map)['musicalAccuracy'] = 'verified';
      expect(_parse(metadata), isNull);
    },
  );

  test('rejects invalid counts, recording IDs and unbounded sample lists', () {
    for (final patch in [
      {'submissionCount': 0},
      {'submissionCount': 1},
      {'recordingMbid': 'not-a-recording'},
      {
        'samples': [for (var i = 0; i < 100; i++) {}],
      },
    ]) {
      final metadata = _metadata();
      (metadata['acousticbrainz'] as Map).addAll(patch);
      expect(_parse(metadata), isNull);
    }
  });

  test('rejects malformed keys, non-finite tempo and duplicate offsets', () {
    for (final patch in [
      {'estimatedBpm': double.infinity},
      {'estimatedBpm': 0},
      {
        'estimatedKey': {'tonic': '<script>', 'scale': 'minor', 'strength': .5},
      },
      {
        'estimatedKey': {'tonic': 'C', 'scale': 'minor', 'strength': 1.1},
      },
      {'submissionOffset': 1},
    ]) {
      final metadata = _metadata();
      final samples = (metadata['acousticbrainz'] as Map)['samples'] as List;
      (samples.first as Map).addAll(patch);
      expect(_parse(metadata), isNull);
    }
  });
}
