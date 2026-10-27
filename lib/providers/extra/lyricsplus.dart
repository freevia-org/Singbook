import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';

import '../../domain/arrangement.dart' show lyricOrderHash;
import '../../domain/edition_identity.dart' show explicitEditionsCompatible;
import '../../domain/models.dart';
import '../provider.dart';
import '../sanitize.dart' show queryText, safeHttpsUrl, throwIfBlocked;

/// LyricsPlus searches several catalogs, which need not identify the lyric
/// winner. Its own IDs below identify title/artist lyric lookups, not recordings.
/// The initial resolver supports Apple winners with independently checked IDs.
class LyricsPlusProvider implements LyricsProvider {
  LyricsPlusProvider(this.transport);

  final ProviderTransport transport;
  static const _host = 'lyricsplus.prjktla.my.id';
  static const _appleHost = 'itunes.apple.com';
  static const _maxBytes = 512 * 1024;
  final Map<String, ({JsonMap value, List<int> bytes})> _apple = {};
  final Map<String, SourceResult> _documents = {};

  @override
  final definition = const ProviderDefinition(
    id: 'lyricsplus',
    name: 'LyricsPlus',
    capabilities: {'catalog', 'lyrics', 'metadata', 'lineTiming', 'wordTiming'},
    accessMode: 'publicApi',
    website: 'https://github.com/ibratabian17/LyricsPlus',
    enabledByDefault: false,
  );

  static String _identity(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _text(Object? value, {int max = 300, bool required = true}) {
    if (value == null && !required) return '';
    if (value is! String ||
        value.length > max ||
        value.contains('\u0000') ||
        required && value.trim().isEmpty) {
      throw const ProviderException('invalid_response');
    }
    return value.trim();
  }

  static JsonMap _map(Object? value) {
    if (value is! Map) throw const ProviderException('invalid_response');
    return Map<String, dynamic>.from(value);
  }

  static String _id(String title, String artist) =>
      'work-${sha256.convert(utf8.encode(jsonEncode([_identity(title), _identity(artist)])))}';

  static Uri _lyricUrl(String title, String artist) =>
      Uri.https(_host, '/v2/lyrics/get', {'title': title, 'artist': artist});

  Future<({JsonMap value, List<int> bytes})> _json(
    Uri uri,
    CancellationToken? cancel,
  ) async {
    final bytes = await transport.getBytes(
      uri,
      cancel: cancel,
      maxBytes: _maxBytes,
      allowedHosts: {uri.host},
    );
    cancel?.throwIfCancelled();
    String? text;
    try {
      text = utf8.decode(bytes);
      return (value: _map(jsonDecode(text)), bytes: bytes);
    } on ProviderException {
      rethrow;
    } catch (_) {
      if (text != null) throwIfBlocked(text);
      throw const ProviderException('invalid_response');
    }
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final q = queryText(query);
    if (q.isEmpty) return const [];
    final reply = await _json(
      Uri.https(_host, '/v1/songlist/search', {'q': q}),
      cancel,
    );
    final rows = reply.value['results'];
    if (rows is! List || rows.length > 200) {
      throw const ProviderException('invalid_response');
    }
    final groups = <String, List<JsonMap>>{};
    for (final raw in rows) {
      final row = _map(raw);
      final title = _text(row['title']);
      final artist = _text(row['artist']);
      groups.putIfAbsent(_id(title, artist), () => []).add(row);
    }
    return [
      for (final entry in groups.entries)
        SongCandidate(
          providerId: definition.id,
          id: entry.key,
          title: _text(entry.value.first['title']),
          artist: _text(entry.value.first['artist']),
          url: _lyricUrl(
            _text(entry.value.first['title']),
            _text(entry.value.first['artist']),
          ).toString(),
          metadata: const {
            'identityScope': 'arrangement',
            'documentKind': 'lyricDocument',
          },
          extra: {
            'lyricsplus': {
              'catalogRows': entry.value,
              'catalogResponseSha256': sha256.convert(reply.bytes).toString(),
              'catalogQuery': q,
              'catalogFieldsAreLookupHints': true,
            },
          },
        ),
    ];
  }

  Future<({JsonMap value, List<int> bytes})> _appleTrack(
    String id,
    CancellationToken? cancel,
  ) async {
    cancel?.throwIfCancelled();
    final cached = _apple[id];
    if (cached != null) return cached;
    final reply = await _json(
      Uri.https(_appleHost, '/lookup', {
        'id': id,
        'country': 'US',
        'entity': 'song',
      }),
      cancel,
    );
    final rows = reply.value['results'];
    if (rows is! List || rows.length > 10) {
      throw const ProviderException('invalid_response');
    }
    final matches = rows.whereType<Map>().where(
      (row) =>
          row['wrapperType'] == 'track' &&
          row['kind'] == 'song' &&
          row['trackId'].toString() == id,
    );
    if (matches.length != 1) {
      throw const ProviderException('identity_mismatch');
    }
    final result = (value: _map(matches.single), bytes: reply.bytes);
    _apple[id] = result;
    if (_apple.length > 32) _apple.remove(_apple.keys.first);
    return result;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.providerId != definition.id ||
        candidate.id != _id(candidate.title, candidate.artist) ||
        candidate.recordingIds.isNotEmpty ||
        candidate.metadata['identityScope'] != 'arrangement') {
      throw const ProviderException('invalid_selection');
    }
    final title = _text(candidate.title);
    final artist = _text(candidate.artist);
    final key = '${candidate.identity}:${jsonEncode(candidate.toJson())}';
    cancel?.throwIfCancelled();
    final cached = _documents[key];
    if (cached != null) return cached;
    // No platform ID, ISRC, album or duration is submitted. In particular a
    // Deezer catalog row cannot become an Apple lyric-recording claim by echo.
    final reply = await _json(_lyricUrl(title, artist), cancel);
    final data = reply.value;
    final metadata = _map(data['metadata']);
    final process = _map(data['processingTime']);
    final picked = _map(process['selectedSongMetadata']);
    if (_identity(_text(process['winnerSource'])) != 'apple' ||
        !{
          'apple',
          'apple music',
        }.contains(_identity(_text(metadata['source']))) ||
        !{
          'apple',
          'apple music',
        }.contains(_identity(_text(picked['source'])))) {
      throw const ProviderException('unavailable', 'unsupported_source');
    }
    final platformId = _text(
      picked['songPlatformId'],
      max: 16,
      required: false,
    );
    if (!RegExp(r'^[1-9]\d{0,14}$').hasMatch(platformId)) {
      throw const ProviderException('unavailable', 'missing_source_identity');
    }
    final appleReply = await _appleTrack(platformId, cancel);
    final apple = appleReply.value;
    final actualTitle = _text(apple['trackName']);
    final actualArtist = _text(apple['artistName']);
    final album = _text(apple['collectionName']);
    final duration = apple['trackTimeMillis'];
    if (duration is! int || duration <= 0 || duration > 86400000) {
      throw const ProviderException('invalid_response');
    }
    for (final map in [metadata, picked]) {
      for (final field in ['title', 'artist']) {
        final value = _text(map[field], required: false);
        if (value.isNotEmpty &&
            _identity(value) !=
                _identity(field == 'title' ? actualTitle : actualArtist)) {
          throw const ProviderException('identity_mismatch');
        }
      }
    }
    final sourceUrl = safeHttpsUrl(
      apple['trackViewUrl'],
      hostSuffixes: {'music.apple.com', 'itunes.apple.com'},
    );
    if (sourceUrl == null ||
        _identity(actualTitle) != _identity(title) ||
        _identity(actualArtist) != _identity(artist)) {
      throw const ProviderException('identity_mismatch');
    }
    final artworkUrl = safeHttpsUrl(
      apple['artworkUrl100'],
      hostSuffixes: {'mzstatic.com'},
    );
    final facts = <String, dynamic>{
      'identityScope': 'arrangement',
      'documentKind': 'lyricDocument',
      'album': album,
      'durationSeconds': duration / 1000,
      'appleMusicIds': [platformId],
      'artworkUrl': ?artworkUrl,
      if (apple['primaryGenreName'] is String)
        'genre': apple['primaryGenreName'],
      if (metadata['songWriters'] is List) 'writers': metadata['songWriters'],
      for (final field in ['primaryGenreName', 'releaseDate', 'country'])
        if (apple[field] is String) field: apple[field],
      for (final field in [
        'trackNumber',
        'discNumber',
        'trackCount',
        'discCount',
      ])
        if (apple[field] is int) field: apple[field],
      for (final field in ['language', 'songWriters', 'agents', 'songParts'])
        if (metadata.containsKey(field)) field: metadata[field],
      'mediaLinks': [
        {'kind': 'source', 'label': 'Apple Music', 'url': sourceUrl},
      ],
    };
    final found = SongCandidate(
      providerId: definition.id,
      id: candidate.id,
      title: actualTitle,
      artist: actualArtist,
      album: album,
      durationSeconds: duration / 1000,
      url: _lyricUrl(title, artist).toString(),
      metadata: facts,
      extra: candidate.extra,
    );
    if (candidate.album != null &&
            _identity(candidate.album!) != _identity(album) ||
        !explicitEditionsCompatible(candidate, found)) {
      throw const ProviderException('identity_mismatch');
    }
    final track = parseLyricsPlusV2(
      reply.bytes,
      sourceDocumentId: '${candidate.identity}:apple:$platformId',
      sourceDurationMs: duration,
    );
    final attribution =
        'LyricsPlus — Apple Music — $sourceUrl; underlying lyric rights unknown';
    final result = SourceResult(
      candidate: found,
      body: track.sourceLyrics
          .replaceAll('\\', '\\\\')
          .replaceAll('[', r'\[')
          .replaceAll(']', r'\]')
          .replaceAll('{', r'\{')
          .replaceAll('}', r'\}'),
      metadata: facts,
      timingTracks: [track],
      attribution: attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        'parserVersion': 'lyricsplus-native-1',
        'sourceDocumentId': track.sourceDocumentId,
        'rights': {
          'source': definition.id,
          'sourceUrl': found.url,
          'license': 'unknown',
          'attribution': attribution,
          'evidenceUrl': 'https://github.com/ibratabian17/LyricsPlus',
          'provenanceNote':
              'API code licensing does not establish rights in underlying lyrics.',
        },
        'originalPayload': {
          'contentType': 'application/json',
          'encoding': 'utf-8',
          'base64': base64Encode(reply.bytes),
        },
        'lyricsplus': {
          ...?_mapOrNull(candidate.extra['lyricsplus']),
          'winnerSource': 'apple',
          'sourcePlatformId': platformId,
          'claimedSelectedSongMetadata': picked,
          'independentAppleMetadata': apple,
          'independentAppleResponseBase64': base64Encode(appleReply.bytes),
          'requestHintsAreRecordingEvidence': false,
        },
      },
    );
    cancel?.throwIfCancelled();
    _documents[key] = result;
    if (_documents.length > 16) _documents.remove(_documents.keys.first);
    return result;
  }

  static JsonMap? _mapOrNull(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}

/// Dedicated V2 millisecond profile. Original bytes and all extension fields
/// remain available; overlaps are source facts, not errors or recording proof.
TimingTrack parseLyricsPlusV2(
  List<int> bytes, {
  required String sourceDocumentId,
  required int sourceDurationMs,
}) {
  const maximumMs = 604800000;
  Never invalid() =>
      throw const ProviderException('invalid_response', 'unsupported_timing');
  int milliseconds(Object? value) {
    if (value is! int || value < 0 || value > maximumMs) invalid();
    return value;
  }

  if (bytes.isEmpty || bytes.length > LyricsPlusProvider._maxBytes) invalid();
  if (sourceDurationMs <= 0 || sourceDurationMs > 86400000) invalid();
  final String raw;
  final JsonMap data;
  try {
    raw = utf8.decode(bytes);
    data = LyricsPlusProvider._map(jsonDecode(raw));
  } catch (_) {
    invalid();
  }
  final type = data['type'];
  if (!{'Word', 'Line', 'syllable', 'None'}.contains(type)) invalid();
  final untimed = type == 'None';
  final rows = data['lyrics'];
  final metadata = LyricsPlusProvider._map(data['metadata']);
  if (rows is! List || rows.isEmpty || rows.length > 10000) invalid();
  final total = metadata['totalDuration'];
  if (total != null) {
    if (total is! String) invalid();
    final match = RegExp(r'^(\d+):(\d{2})(?:\.(\d{1,3}))?$').firstMatch(total);
    if (match == null || int.parse(match[2]!) > 59) invalid();
    final ms =
        int.parse(match[1]!) * 60000 +
        int.parse(match[2]!) * 1000 +
        int.parse((match[3] ?? '').padRight(3, '0'));
    if ((ms - sourceDurationMs).abs() > 3000) invalid();
  }
  final cues = <TimingCue>[];
  final lines = <String>[];
  var previous = -1;
  var characters = 0;
  var words = 0;
  for (var i = 0; i < rows.length; i++) {
    final line = LyricsPlusProvider._map(rows[i]);
    final text = line['text'];
    if (text is! String ||
        text.trim().isEmpty ||
        text.length > 20000 ||
        text.contains('\u0000')) {
      invalid();
    }
    if (text.contains('\n') || text.contains('\r')) invalid();
    characters += text.length;
    if (characters > 200000) invalid();
    lines.add(text);
    if (untimed) continue;
    final start = milliseconds(line['time']);
    final end = start + milliseconds(line['duration']);
    if (start < previous || end > sourceDurationMs + 3000) invalid();
    previous = start;
    final element = line['element'] == null
        ? <String, dynamic>{}
        : LyricsPlusProvider._map(line['element']);
    final voice = LyricsPlusProvider._text(element['singer'], required: false);
    final occurrence = 'line-$i';
    cues.add(
      TimingCue(
        id: '$occurrence:line',
        occurrenceId: occurrence,
        text: text,
        startUs: start * 1000,
        endUs: end * 1000,
        voice: voice.isEmpty ? null : voice,
        originalBegin: start.toString(),
        originalEnd: end.toString(),
        extra: {
          'lyricsplus': {
            for (final entry in line.entries)
              if (!{'text', 'syllabus'}.contains(entry.key))
                entry.key: entry.value,
          },
        },
      ),
    );
    final segments = line['syllabus'];
    if (segments == null && type == 'Line') continue;
    if (segments is! List || segments.isEmpty || segments.length > 2000) {
      invalid();
    }
    final boundaries = <int, int>{0: 0};
    var unit = 0, grapheme = 0;
    for (final cluster in text.characters) {
      unit += cluster.length;
      boundaries[unit] = ++grapheme;
    }
    var cursor = 0;
    // Background syllables can follow the main lyric in text order while
    // starting earlier on the source timeline. Ordering is meaningful within
    // each layer, not across the interleaved main/background sequence.
    final previousWord = <bool, int>{};
    final joined = StringBuffer();
    for (var j = 0; j < segments.length; j++) {
      final word = LyricsPlusProvider._map(segments[j]);
      final wordText = word['text'];
      if (wordText is! String || wordText.isEmpty) invalid();
      joined.write(wordText);
      for (final flag in ['isBackground', 'synthetic']) {
        if (word.containsKey(flag) && word[flag] is! bool) invalid();
      }
      final background = word['isBackground'] == true;
      final wordStart = milliseconds(word['time']);
      final wordEnd = wordStart + milliseconds(word['duration']);
      if (wordStart < start ||
          wordEnd > end ||
          wordStart < (previousWord[background] ?? -1) ||
          !boundaries.containsKey(cursor) ||
          !boundaries.containsKey(cursor + wordText.length)) {
        invalid();
      }
      previousWord[background] = wordStart;
      cues.add(
        TimingCue(
          id: '$occurrence:word-$j',
          occurrenceId: occurrence,
          text: wordText,
          startUs: wordStart * 1000,
          endUs: wordEnd * 1000,
          graphemeStart: boundaries[cursor],
          graphemeEnd: boundaries[cursor + wordText.length],
          voice: voice.isEmpty ? null : voice,
          originalBegin: wordStart.toString(),
          originalEnd: wordEnd.toString(),
          extra: {
            if (background) 'background': true,
            if (word['synthetic'] == true) 'synthetic': true,
            'lyricsplus': word,
          },
        ),
      );
      cursor += wordText.length;
      if (++words > 50000) invalid();
    }
    if (joined.toString() != text) invalid();
  }
  final lyrics = lines.join('\n');
  final hash = sha256.convert(bytes).toString();
  // Interleaved voices may overlap across lines. The portable cue contract
  // orders by start time while occurrence IDs retain the original line order.
  final order = {for (var i = 0; i < cues.length; i++) cues[i]: i};
  cues.sort((a, b) {
    final time = a.startUs.compareTo(b.startUs);
    return time != 0 ? time : order[a]!.compareTo(order[b]!);
  });
  return TimingTrack(
    id: '$sourceDocumentId:${hash.substring(0, 20)}',
    sourceDocumentId: sourceDocumentId,
    sourceLyrics: lyrics,
    format: 'lyricsplus-v2',
    raw: raw,
    language: metadata['language'] is String
        ? metadata['language'] as String
        : null,
    lyricHash: lyricOrderHash(lyrics),
    cues: cues,
    status: untimed ? TimingStatus.unsupported : TimingStatus.unverified,
    granularity: words > 0 ? 'word' : 'line',
    extra: {
      'parserVersion': 'lyricsplus-v2-1',
      'parserProfile': 'lyricsplus-v2-milliseconds',
      'sourceTimeUnit': 'millisecond',
      if (untimed) 'timingAvailability': 'none',
      'rawBytesBase64': base64Encode(bytes),
      'rawByteHash': hash,
      'rawEncoding': 'utf-8',
      'recordingEvidence': 'sourceDemonstrationOnly',
      'sourceTimeline':
          'LyricsPlus source document; audio alignment unverified',
      'metadata': metadata,
    },
  );
}
