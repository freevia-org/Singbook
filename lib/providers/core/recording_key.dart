import '../../domain/models.dart';
import '../provider.dart';

/// The key of one recording, measured from its audio by ReccoBeats.
///
/// This is recording-level evidence, not ground truth: algorithmic keys are
/// usually right about the tonic but can confuse a key with its relative
/// major or minor (D for B minor). Callers weigh it against chord charts.
class RecordingKey {
  const RecordingKey({
    required this.key,
    required this.ids,
    this.tempo,
    this.alternatives = const [],
    this.observations = const [],
  });

  /// The key name, such as "A" or "F#m".
  final String key;

  /// The ISRCs or Spotify track IDs that gave this key.
  final List<String> ids;

  /// Beats per minute, when the analyses agree on it.
  final double? tempo;

  /// Other valid keys returned for the same requested recordings, ranked by
  /// distinct recording count, then by key name. Empty for legacy lookups.
  final List<RecordingKey> alternatives;

  /// Actual ReccoBeats rows supporting this key group, when retained.
  final List<JsonMap> observations;

  JsonMap toJson() => {
    'key': key,
    'ids': ids,
    'tempo': ?tempo,
    'source': 'ReccoBeats',
    if (alternatives.isNotEmpty)
      'alternatives': alternatives.map((value) => value.toJson()).toList(),
    if (observations.isNotEmpty) 'observations': observations,
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
    bool retainAlternatives = false,
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
    // Rows must name a requested recording: its ISRC, or the Spotify track
    // its link points to.
    final requested = ids.toSet();
    bool asked(Map raw) {
      final isrc = raw['isrc'];
      if (isrc is String && requested.contains(isrc.trim().toUpperCase())) {
        return true;
      }
      final href = raw['href'];
      final uri = href is String ? Uri.tryParse(href) : null;
      return uri != null &&
          uri.host == 'open.spotify.com' &&
          uri.pathSegments.length == 2 &&
          uri.pathSegments.first == 'track' &&
          requested.contains(uri.pathSegments.last);
    }

    final byRecording = <String, ({String key, double? tempo})>{};
    final byKey =
        <
          String,
          ({List<String> ids, Set<String> identities, List<JsonMap> rows})
        >{};
    for (final raw in content) {
      if (raw is! Map || !asked(raw)) continue;
      final key = raw['key'], mode = raw['mode'];
      if (key is! int || key < 0 || key > 11 || (mode != 0 && mode != 1)) {
        continue;
      }
      final id = raw['isrc'] is String && (raw['isrc'] as String).isNotEmpty
          ? raw['isrc'] as String
          : '${raw['id']}';
      final tempo = raw['tempo'];
      final keyName = '${_names[key]}${mode == 1 ? '' : 'm'}';
      byRecording.putIfAbsent(
        id,
        () => (
          key: keyName,
          tempo: tempo is num && tempo > 0 && tempo < 400
              ? tempo.toDouble()
              : null,
        ),
      );
      if (retainAlternatives) {
        final href = raw['href'];
        final uri = href is String ? Uri.tryParse(href) : null;
        final spotifyId =
            uri != null &&
                uri.host == 'open.spotify.com' &&
                uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'track'
            ? uri.pathSegments.last
            : null;
        final rawIsrc = raw['isrc'];
        final normalizedIsrc = rawIsrc is String
            ? rawIsrc.trim().toUpperCase()
            : '';
        final validIsrc = _isrc.hasMatch(normalizedIsrc);
        final rawRowId = raw['id'];
        final rowId = rawRowId is String && rawRowId.trim().isNotEmpty
            ? rawRowId.trim()
            : null;
        final groupId = validIsrc ? rawIsrc as String : spotifyId ?? rowId;
        final identity = validIsrc
            ? 'isrc:$normalizedIsrc'
            : spotifyId != null
            ? 'spotify:$spotifyId'
            : 'id:$rowId';
        final group = byKey.putIfAbsent(
          keyName,
          () => (ids: <String>[], identities: <String>{}, rows: <JsonMap>[]),
        );
        if (groupId != null && group.identities.add(identity)) {
          group.ids.add(groupId);
        }
        group.rows.add(Map<String, dynamic>.from(raw));
        // A single ISRC can have contradictory rows. It is one vote in each
        // observed key group, while repeated rows remain available as raw
        // evidence. `identity` is deliberately resolved above so rows without
        // an ISRC can still be associated with their requested Spotify ID.
      }
    }
    if (byRecording.isEmpty) return null;
    final votes = <String, List<String>>{};
    for (final entry in byRecording.entries) {
      votes.putIfAbsent(entry.value.key, () => []).add(entry.key);
    }
    final ranked = votes.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (retainAlternatives) {
      final groups = byKey.entries.toList()
        ..sort((a, b) {
          final count = b.value.ids.length.compareTo(a.value.ids.length);
          return count != 0 ? count : a.key.compareTo(b.key);
        });
      if (groups.isEmpty) return null;
      RecordingKey makeGroup(
        MapEntry<
          String,
          ({List<String> ids, Set<String> identities, List<JsonMap> rows})
        >
        group,
      ) {
        final tempos = {
          for (final row in group.value.rows)
            if (row['tempo'] is num &&
                (row['tempo'] as num) > 0 &&
                (row['tempo'] as num) < 400)
              (row['tempo'] as num).round(),
        };
        return RecordingKey(
          key: group.key,
          ids: List.unmodifiable(group.value.ids),
          tempo: tempos.length == 1 ? tempos.single.toDouble() : null,
          observations: List.unmodifiable(group.value.rows),
        );
      }

      final primary = makeGroup(groups.first);
      return RecordingKey(
        key: primary.key,
        ids: primary.ids,
        tempo: primary.tempo,
        observations: primary.observations,
        alternatives: List.unmodifiable(groups.skip(1).map(makeGroup)),
      );
    }
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
