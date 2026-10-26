import '../../domain/models.dart';
import '../../domain/timing.dart';
import '../provider.dart';
import '../transport.dart' show singbookVersion;
import '../core/common.dart'
    show
        clean,
        requiredText,
        object,
        array,
        parseRows,
        durationValue,
        lyricsResult;
import 'common.dart' show normalized, queryText, sanitizeExtraMetadata;

/// Public API contract: https://lrc.red/api. Identification and visible source
/// credit are required; access does not grant redistribution rights in lyrics.
class LrcRedProvider implements LyricsProvider {
  LrcRedProvider(
    this.transport, {
    this.requestInterval = const Duration(seconds: 1),
  });
  final ProviderTransport transport;
  final Duration requestInterval;
  Future<void> _queue = Future.value();
  DateTime _next = DateTime.fromMillisecondsSinceEpoch(0);
  static final _isrc = RegExp(r'^[A-Z]{2}[A-Z0-9]{3}[0-9]{7}$');
  static const _headers = {
    'User-Agent':
        'Singbook/$singbookVersion (+https://freevia.org/singbook/; support@freevia.org)',
  };
  @override
  final definition = const ProviderDefinition(
    id: 'lrcred',
    name: 'lrc.red',
    capabilities: {'catalog', 'lyrics', 'metadata', 'lineTiming', 'wordTiming'},
    accessMode: 'publicApi',
    website: 'https://lrc.red/',
    enabledByDefault: false,
  );

  Future<T> _request<T>(Future<T> Function() send, CancellationToken? cancel) {
    final result = _queue.then((_) async {
      cancel?.throwIfCancelled();
      final wait = _next.difference(DateTime.now());
      if (wait > Duration.zero) {
        if (cancel == null) {
          await Future<void>.delayed(wait);
        } else {
          await Future.any([Future<void>.delayed(wait), cancel.cancelled]);
        }
      }
      cancel?.throwIfCancelled();
      try {
        return await send();
      } finally {
        _next = DateTime.now().add(requestInterval);
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  SongCandidate _candidate(dynamic input) {
    final data = object(input);
    final id = requiredText(data['isrc']);
    if (!_isrc.hasMatch(id)) throw const ProviderException('invalid_response');
    final metadata = sanitizeExtraMetadata({
      'identityScope': 'recording',
      'isrcs': [id],
      'album': ?clean(data['album']),
      'durationSeconds': ?durationValue(data['duration']),
      if (data['year'] is int && data['year'] >= 1000 && data['year'] <= 9999)
        'year': data['year'],
      'language': ?clean(data['language'], 30),
      'releaseDate': ?clean(data['released'], 30),
      if (data['genres'] is List)
        'genres': (data['genres'] as List)
            .map((g) => clean(g, 100))
            .nonNulls
            .take(30)
            .toList(),
      if (data['songwriters'] is List)
        'credits': [
          for (final name
              in (data['songwriters'] as List)
                  .map((s) => clean(s))
                  .nonNulls
                  .take(100))
            {'role': 'songwriter', 'name': name},
        ],
      if (data['featured'] is List)
        'featuredArtists': (data['featured'] as List)
            .map((s) => clean(s))
            .nonNulls
            .take(30)
            .toList(),
      if (_asset(data['cover'], id, 'webp') case final Uri cover)
        'artworkUrl': cover.toString(),
      'mediaLinks': [
        {'kind': 'source', 'label': 'lrc.red', 'url': 'https://lrc.red/s/$id'},
      ],
    });
    return SongCandidate(
      providerId: definition.id,
      id: id,
      title: requiredText(data['title']),
      artist: requiredText(data['artist']),
      album: clean(data['album']),
      durationSeconds: durationValue(data['duration']),
      url: 'https://lrc.red/s/$id',
      recordingIds: {'isrc': id},
      metadata: metadata,
    );
  }

  static Uri? _asset(dynamic value, String isrc, String extension) {
    if (value is! String) return null;
    final url = Uri.tryParse(value);
    return url != null &&
            url.scheme == 'https' &&
            url.host == 'lrc.red' &&
            url.userInfo.isEmpty &&
            (!url.hasPort || url.port == 443) &&
            url.path == '/s/$isrc.$extension' &&
            url.query.isEmpty &&
            url.fragment.isEmpty
        ? url
        : null;
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final data = object(
      await _request(
        () => transport.requestJson(
          Uri.https('lrc.red', '/search.json', {'q': queryText(query)}),
          headers: _headers,
          cancel: cancel,
        ),
        cancel,
      ),
    );
    // Missing hits is a schema failure, never an empty-search success.
    return parseRows(array(data['hits']).take(30), _candidate);
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    var selected = candidate;
    if (candidate.providerId != definition.id) {
      final id = candidate.recordingIds['isrc'];
      if (id == null || !_isrc.hasMatch(id)) {
        throw const ProviderException('identity_required');
      }
      selected = SongCandidate(
        providerId: definition.id,
        id: id,
        title: candidate.title,
        artist: candidate.artist,
        album: candidate.album,
        durationSeconds: candidate.durationSeconds,
        recordingIds: {'isrc': id},
      );
    }
    if (!_isrc.hasMatch(selected.id)) {
      throw const ProviderException('invalid_selection');
    }
    final data = object(
      await _request(
        () => transport.requestJson(
          Uri.https('lrc.red', '/s/${selected.id}.json'),
          headers: _headers,
          cancel: cancel,
        ),
        cancel,
      ),
    );
    final found = _candidate(data);
    if (found.id != selected.id ||
        normalized(found.title) != normalized(selected.title) ||
        normalized(found.artist) != normalized(selected.artist) ||
        selected.album != null &&
            normalized(found.album ?? '') != normalized(selected.album!) ||
        selected.durationSeconds != null &&
            (found.durationSeconds == null ||
                (found.durationSeconds! - selected.durationSeconds!).abs() >
                    2)) {
      throw const ProviderException('identity_mismatch');
    }
    final url = _asset(object(data['files'])['ttml'], found.id, 'ttml');
    if (url == null) throw const ProviderException('invalid_response');
    final raw = await _request(
      () => transport.getText(
        url,
        headers: _headers,
        cancel: cancel,
        maxBytes: 512 * 1024,
        allowedHosts: const {'lrc.red'},
      ),
      cancel,
    );
    final track = parseTtml(
      raw,
      sourceDocumentId: found.identity,
      recordingId: found.identity,
      profile: 'lrc-red',
    );
    if (track.status == TimingStatus.invalid ||
        track.status == TimingStatus.unsupported ||
        track.cues.isEmpty) {
      throw const ProviderException('invalid_response', 'unsupported_timing');
    }
    return lyricsResult(
      found,
      track.sourceLyrics,
      timing: [track],
      attribution: 'lrc.red — https://lrc.red/s/${found.id}',
    );
  }
}
