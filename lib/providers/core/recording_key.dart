import '../../domain/models.dart';
import '../provider.dart';

/// The key of one recording, measured from its audio by ReccoBeats.
///
/// This is recording-level evidence, not ground truth: algorithmic keys are
/// usually right about the tonic but can confuse a key with its relative
/// major or minor (D for B minor). Callers weigh it against chord charts.
class RecordingKey {
  const RecordingKey({required this.key, required this.ids, this.tempo});

  /// The key name, such as "A" or "F#m".
  final String key;

  /// The ISRCs or Spotify track IDs that gave this key.
  final List<String> ids;

  /// Beats per minute, when the analyses agree on it.
  final double? tempo;

  JsonMap toJson() => {
    'key': key,
    'ids': ids,
    'tempo': ?tempo,
    'source': 'ReccoBeats',
  };
}

const _names = [
  'C',
  'C#',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

final _isrc = RegExp(r'^[A-Z]{2}[A-Z0-9]{3}\d{7}$');
final _spotifyId = RegExp(r'^[A-Za-z0-9]{22}$');

/// Spotify track IDs and ISRCs that identify [result]'s recording: Spotify
/// links in its media links, and ISRCs from recording metadata.
({List<String> spotify, List<String> isrcs}) recordingIdentifiers(
  SourceResult result,
) {
  final spotify = <String>{}, isrcs = <String>{};
  for (final metadata in [result.candidate.metadata, result.metadata]) {
    final links = metadata['mediaLinks'];
    if (links is List) {
      for (final link in links) {
        final url = link is Map ? link['url'] : null;
        final uri = url is String ? Uri.tryParse(url) : null;
        if (uri == null ||
            uri.host != 'open.spotify.com' ||
            uri.pathSegments.length < 2 ||
            uri.pathSegments[uri.pathSegments.length - 2] != 'track') {
          continue;
        }
        final id = uri.pathSegments.last;
        if (_spotifyId.hasMatch(id)) spotify.add(id);
      }
    }
    for (final value in [
      metadata['isrc'],
      if (metadata['isrcs'] is List) ...metadata['isrcs'] as List,
    ]) {
      if (value is String && _isrc.hasMatch(value.trim().toUpperCase())) {
        isrcs.add(value.trim().toUpperCase());
      }
    }
  }
  final recorded = result.candidate.recordingIds['isrc'];
  if (recorded != null && _isrc.hasMatch(recorded.toUpperCase())) {
    isrcs.add(recorded.toUpperCase());
  }
  return (spotify: spotify.toList(), isrcs: isrcs.toList());
}

/// Looks up recording keys at ReccoBeats (https://reccobeats.com): free, no
/// account, permitted for personal and commercial use, provided as is.
class RecordingKeyService {
  RecordingKeyService(this.http);

  final ProviderTransport http;
  static const host = 'api.reccobeats.com';

  /// The key most distinct recordings among [spotifyIds] and [isrcs] agree
  /// on, or null when none is found or no key has a strict majority. One
  /// request covers up to 20 identifiers.
  Future<RecordingKey?> lookup({
    List<String> spotifyIds = const [],
    List<String> isrcs = const [],
    CancellationToken? cancel,
  }) async {
    final ids = <String>{
      ...spotifyIds.where(_spotifyId.hasMatch),
      ...isrcs.map((id) => id.toUpperCase()).where(_isrc.hasMatch),
    }.take(20).toList();
    if (ids.isEmpty) return null;
    final data = await http.requestJson(
      Uri.https(host, '/v1/audio-features', {'ids': ids.join(',')}),
      cancel: cancel,
      maxBytes: 512 * 1024,
      timeout: const Duration(seconds: 12),
    );
    final content = data is Map ? data['content'] : null;
    if (content is! List) return null;
    // One vote per distinct recording (ISRC): the same audio is often listed
    // under several catalog entries, which must not outvote other audio.
    final byRecording = <String, ({String key, double? tempo})>{};
    for (final raw in content) {
      if (raw is! Map) continue;
      final key = raw['key'], mode = raw['mode'];
      if (key is! int || key < 0 || key > 11 || (mode != 0 && mode != 1)) {
        continue;
      }
      final id = raw['isrc'] is String && (raw['isrc'] as String).isNotEmpty
          ? raw['isrc'] as String
          : '${raw['id']}';
      final tempo = raw['tempo'];
      byRecording.putIfAbsent(
        id,
        () => (
          key: '${_names[key]}${mode == 1 ? '' : 'm'}',
          tempo: tempo is num && tempo > 0 && tempo < 400
              ? tempo.toDouble()
              : null,
        ),
      );
    }
    if (byRecording.isEmpty) return null;
    final votes = <String, List<String>>{};
    for (final entry in byRecording.entries) {
      votes.putIfAbsent(entry.value.key, () => []).add(entry.key);
    }
    final ranked = votes.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (ranked.length > 1 &&
        ranked.first.value.length * 2 <= byRecording.length) {
      return null;
    }
    final winner = ranked.first;
    final tempos = {
      for (final id in winner.value)
        if (byRecording[id]!.tempo case final double tempo) tempo.round(),
    };
    return RecordingKey(
      key: winner.key,
      ids: winner.value,
      tempo: tempos.length == 1 ? tempos.single.toDouble() : null,
    );
  }
}
