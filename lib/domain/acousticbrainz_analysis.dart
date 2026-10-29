/// A small display projection of publisher-submitted analysis, never canonical
/// key, tempo, recording duration or alignment. Raw upload tags stay archived.
class AcousticBrainzAnalysis {
  const AcousticBrainzAnalysis._(
    this.recordingId,
    this.submissionCount,
    this.samples,
  );

  final String recordingId;
  final int submissionCount;
  final List<AcousticBrainzSample> samples;
  bool get allSubmissionsShown => submissionCount == samples.length;

  static AcousticBrainzAnalysis? fromMetadata(
    String providerId,
    Map<String, Object?> metadata,
  ) {
    if (providerId != 'acousticbrainz') return null;
    final raw = metadata['acousticbrainz'];
    if (raw is! Map || raw['musicalAccuracy'] != 'unverified') return null;
    final id = raw['recordingMbid'];
    final count = raw['submissionCount'];
    final samples = raw['samples'];
    if (id is! String ||
        !_mbid.hasMatch(id) ||
        count is! int ||
        count < 1 ||
        count > 1000000 ||
        samples is! List ||
        samples.isEmpty ||
        samples.length > 2 ||
        samples.length > count) {
      return null;
    }
    final parsed = <AcousticBrainzSample>[];
    final offsets = <int>{};
    for (final sample in samples) {
      if (sample is! Map || sample['estimateStatus'] != 'unverified') {
        return null;
      }
      final offset = sample['submissionOffset'];
      final bpm = sample['estimatedBpm'];
      final key = sample['estimatedKey'];
      if (offset is! int ||
          offset < 0 ||
          offset > 1 ||
          offset >= count ||
          !offsets.add(offset) ||
          key is! Map ||
          !_number(bpm, 0, 1000) ||
          !_keys.contains(key['tonic']) ||
          !const {'major', 'minor'}.contains(key['scale']) ||
          !_number(key['strength'], -1, 1)) {
        return null;
      }
      final strength = (key['strength'] as num).toDouble();
      if (strength < 0) return null;
      parsed.add(
        AcousticBrainzSample._(
          offset,
          (bpm as num).toDouble(),
          key['tonic'] as String,
          key['scale'] as String,
          strength,
        ),
      );
    }
    return AcousticBrainzAnalysis._(
      id.toLowerCase(),
      count,
      List.unmodifiable(parsed),
    );
  }

  /// Safe storage in UI view models. Deliberately excludes uploaded filenames,
  /// tags, arbitrary URLs/HTML, and any executable extractor configuration.
  Map<String, Object?> toMetadata() => {
    'recordingMbid': recordingId,
    'submissionCount': submissionCount,
    'musicalAccuracy': 'unverified',
    'samples': [for (final sample in samples) sample.toMetadata()],
  };
}

class AcousticBrainzSample {
  const AcousticBrainzSample._(
    this.offset,
    this.bpm,
    this.tonic,
    this.scale,
    this.keyStrength,
  );
  final int offset;
  final double bpm, keyStrength;
  final String tonic, scale;

  Map<String, Object?> toMetadata() => {
    'submissionOffset': offset,
    'estimatedBpm': bpm,
    'estimatedKey': {'tonic': tonic, 'scale': scale, 'strength': keyStrength},
    'estimateStatus': 'unverified',
  };
}

bool _number(Object? value, num minimumExclusive, num maximumInclusive) =>
    value is num &&
    value.isFinite &&
    value > minimumExclusive &&
    value <= maximumInclusive;

final _mbid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
const _keys = {
  'A',
  'A#',
  'Bb',
  'B',
  'C',
  'C#',
  'Db',
  'D',
  'D#',
  'Eb',
  'E',
  'F',
  'F#',
  'Gb',
  'G',
  'G#',
  'Ab',
};
