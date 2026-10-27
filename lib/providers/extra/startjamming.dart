import 'dart:convert';

import '../../domain/arrangement.dart' show chordPattern;
import '../../domain/models.dart';
import '../core/common.dart' show clean, plainToChordPro;
import '../extra/common.dart' show directive, isYoutubeId;
import '../provider.dart';

/// Native read-only access to Start Jamming's documented Songbook endpoints.
///
/// Chords and lyrics are independent source fields. The rendered chord block is
/// intentionally kept separate from lyric text because the API does not map
/// lyric lines to chord measures.
class StartJammingProvider implements LyricsProvider {
  StartJammingProvider(
    this.transport, {
    DateTime Function()? clock,
    this.cacheLifetime = const Duration(minutes: 15),
  }) : _clock = clock ?? DateTime.now;

  final ProviderTransport transport;
  final DateTime Function() _clock;
  final Duration cacheLifetime;

  static const _host = 'www.startjamming.com';
  static const _maxResponseBytes = 512 * 1024;
  static const _maxSearchRows = 8;
  static const _maxSections = 64;
  static const _maxMeasures = 1000;
  static const _maxBeatsPerMeasure = 32;
  static const _maxLyrics = 16;
  static const _maxLyricsCharacters = 200 * 1024;
  static const _maxBodyCharacters = 512 * 1024;
  static final _idPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final _chorusTag = RegExp(r'<(/?)chorus\s*>', caseSensitive: false);

  final Map<String, _CachedJson> _cache = {};

  @override
  final definition = const ProviderDefinition(
    id: 'startjamming',
    name: 'Start Jamming',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    accessMode: 'public',
    website: 'https://www.startjamming.com',
    enabledByDefault: true,
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final cleanQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanQuery.isEmpty || cleanQuery.length > 200) {
      throw const ProviderException('invalid_query');
    }
    final uri = Uri.https(_host, '/api/songs/search', {
      'for': 'agent',
      'q': cleanQuery,
      'limit': '$_maxSearchRows',
    });
    final response = await _getJson(uri, cancel: cancel);
    final root = _map(response.value);
    final Object? rawRows;
    if (root.containsKey('results')) {
      rawRows = root['results'];
      if (rawRows is! List || rawRows.length > _maxSearchRows) {
        throw const ProviderException('invalid_response');
      }
    } else if (root.containsKey('id')) {
      // Exact normalized title matches are returned as a top-level song.
      rawRows = [root];
    } else {
      throw const ProviderException('invalid_response');
    }

    final rows = rawRows as List;
    if (rows.isEmpty) return const [];
    final results = <SongCandidate>[];
    for (final raw in rows) {
      cancel?.throwIfCancelled();
      final row = _map(raw);
      _validateJsonShape(row);
      results.add(_candidateFromSearch(row));
    }
    return results;
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (candidate.providerId != definition.id) {
      throw const ProviderException('unavailable');
    }
    cancel?.throwIfCancelled();
    final selected = _candidateIdentity(candidate);
    final response = await _getJson(selected.apiUrl, cancel: cancel);
    final detail = _map(response.value);
    _validateJsonShape(detail);
    final found = _validateDetail(detail, selected);
    final chart = _arrangement(
      detail['arrangement'],
      found.songId,
      found.title,
    );
    final lyricVariants = _lyrics(
      detail['lyrics'],
      detail['lyrics_alternates'],
    );
    if (chart.sections.isEmpty && lyricVariants.isEmpty) {
      throw const ProviderException('unavailable');
    }

    final body = _renderBody(lyricVariants, chart.sections);
    if (body.trim().isEmpty || body.length > _maxBodyCharacters) {
      throw const ProviderException('invalid_response');
    }
    final canonicalUrl = found.url;
    final attribution = 'Start Jamming — $canonicalUrl';
    final mediaLinks = _mediaLinks(detail);
    final metadata = <String, dynamic>{
      'identityScope': 'arrangement',
      'rightsStatus': 'unknown',
      if (found.key != null) 'key': found.key,
      if (found.signature != null) 'timeSignature': found.signature,
      if (found.tempo != null) 'tempo': found.tempo,
      if (found.type != null) 'sourceType': found.type,
      if (mediaLinks.isNotEmpty) 'mediaLinks': mediaLinks,
    };
    final extra = <String, dynamic>{
      'parserVersion': 'startjamming-native-1',
      'sourceDocumentId': 'startjamming:${found.id}',
      'rights': {
        'source': definition.id,
        'sourceId': found.id,
        'sourceUrl': canonicalUrl,
        'license': 'unknown',
        'attribution': attribution,
        'evidenceUrl': 'https://www.startjamming.com/api',
        'permissions': {'status': 'unknown'},
        'provenanceNote':
            'Public agent-mode read data; no per-work reuse license was supplied. '
            'Use the returned canonical song URL as source attribution.',
      },
      'originalPayload': {
        'contentType': response.contentType ?? 'application/json',
        'encoding': 'as-received',
        'base64': base64Encode(response.bytes),
        'httpBodyBytesExact': true,
        'wireExact': false,
        'note':
            'Exact HTTP-client response body bytes; may be content-decoded.',
      },
      'startjamming': {
        'id': found.id,
        'canonical_id': found.id,
        'slug': found.id,
        'song_id': found.songId,
        'apiUrl': found.apiUrl,
        'responseEtag': response.etag,
        'retrievedAt': response.retrievedAt.toIso8601String(),
        'validatedAt': response.validatedAt.toIso8601String(),
        'artist': found.detailArtist,
        'type': found.type,
        'sourceSignature': found.rawSignature,
        'lyricsVariants': [
          for (final variant in lyricVariants)
            {
              'index': variant.index,
              if (variant.label != null) 'label': variant.label,
              'text': variant.text,
            },
        ],
        'arrangement': chart.raw,
        'rawFullJson': detail,
      },
    };

    return SourceResult(
      candidate: candidate,
      body: body,
      metadata: metadata,
      attribution: attribution,
      retrievedAt: response.retrievedAt,
      extra: extra,
    );
  }

  Future<_FetchedJson> _getJson(Uri uri, {CancellationToken? cancel}) async {
    // Search constructs the fixed endpoint; resolve validates the returned
    // canonical full-song URL before reaching this private cache operation.
    cancel?.throwIfCancelled();
    final key = uri.toString();
    final prior = _cache.remove(key);
    if (prior != null && _clock().isBefore(prior.expiresAt)) {
      _cache[key] = prior;
      return _FetchedJson(
        value: prior.value,
        etag: prior.etag,
        bytes: prior.bytes,
        contentType: prior.contentType,
        retrievedAt: prior.retrievedAt,
        validatedAt: prior.validatedAt,
      );
    }

    final response = await transport.getConditionalJson(
      uri,
      etag: prior?.etag,
      cancel: cancel,
      maxBytes: _maxResponseBytes,
      allowedHosts: const {_host},
    );
    cancel?.throwIfCancelled();
    if (response.notModified) {
      if (prior == null ||
          prior.etag == null ||
          response.value != null ||
          response.bytes != null) {
        throw const ProviderException('invalid_response');
      }
      final validatedAt = _clock().toUtc();
      final refreshed = _CachedJson(
        value: prior.value,
        etag: response.etag ?? prior.etag,
        bytes: prior.bytes,
        contentType: prior.contentType,
        retrievedAt: prior.retrievedAt,
        expiresAt: _clock().add(cacheLifetime),
        validatedAt: validatedAt,
      );
      _putCache(key, refreshed);
      return _FetchedJson(
        value: refreshed.value,
        etag: refreshed.etag,
        bytes: refreshed.bytes,
        contentType: refreshed.contentType,
        retrievedAt: refreshed.retrievedAt,
        validatedAt: refreshed.validatedAt,
      );
    }
    if (response.value == null || response.bytes == null) {
      throw const ProviderException('invalid_response');
    }
    final value = response.value;
    _validateJsonShape(value);
    final now = _clock().toUtc();
    final entry = _CachedJson(
      value: value,
      etag: response.etag,
      bytes: response.bytes!,
      contentType: response.contentType,
      retrievedAt: now,
      expiresAt: _clock().add(cacheLifetime),
      validatedAt: now,
    );
    _putCache(key, entry);
    return _FetchedJson(
      value: value,
      etag: entry.etag,
      bytes: entry.bytes,
      contentType: entry.contentType,
      retrievedAt: entry.retrievedAt,
      validatedAt: entry.validatedAt,
    );
  }

  void _putCache(String key, _CachedJson value) {
    _cache.remove(key);
    _cache[key] = value;
    while (_cache.length > 32) {
      _cache.remove(_cache.keys.first);
    }
  }

  SongCandidate _candidateFromSearch(JsonMap row) {
    final id = _canonicalId(row['id']);
    _validateIdentityFields(row, id);
    final title = _requiredString(row['title'], max: 200);
    final apiUrl = _validatedApiUrl(row['api_url'], id);
    final humanUrl = _validatedHumanUrl(row['url'], id);
    final artist = _optionalString(row['artist'], max: 300) ?? '';
    final key = _optionalSourceKey(row['key']);
    final type = _optionalString(row['type'], max: 80);
    final score = row['score'];
    if (score != null &&
        (score is! num || !score.isFinite || score < 0 || score > 1)) {
      throw const ProviderException('invalid_response');
    }
    final metadata = <String, dynamic>{
      'identityScope': 'arrangement',
      'key': ?key,
      'sourceType': ?type,
      if (row['has_lyrics'] is bool) 'hasLyrics': row['has_lyrics'],
    };
    return SongCandidate(
      providerId: definition.id,
      id: id,
      title: title,
      artist: artist,
      url: humanUrl.toString(),
      metadata: metadata,
      extra: {
        'startjamming': {
          'id': id,
          'canonical_id': id,
          'slug': id,
          'song_id': row['song_id'],
          'apiUrl': apiUrl.toString(),
          'searchRecord': row,
          'matchType': row['match_type'],
          'score': score,
        },
      },
    );
  }

  _FoundSong _validateDetail(JsonMap detail, _SelectedIdentity selected) {
    final id = _canonicalId(detail['id']);
    _validateIdentityFields(detail, id);
    final title = _requiredString(detail['title'], max: 200);
    if (id != selected.id || _normalize(title) != _normalize(selected.title)) {
      throw const ProviderException('identity_mismatch');
    }
    final artist = _optionalString(detail['artist'], max: 300);
    if (selected.artist.isNotEmpty &&
        (artist == null || _normalize(artist) != _normalize(selected.artist))) {
      throw const ProviderException('identity_mismatch');
    }
    final songId = _requiredString(detail['song_id'], max: 200);
    if (songId != id.replaceAll('-', '_')) {
      throw const ProviderException('identity_mismatch');
    }
    final url = _validatedHumanUrl(detail['url'], id);
    if (url != selected.url) {
      throw const ProviderException('identity_mismatch');
    }
    final apiUrl = _validatedApiUrl(detail['api_url'], id);
    if (apiUrl != selected.apiUrl) {
      throw const ProviderException('identity_mismatch');
    }
    final arrangement = detail['arrangement'];
    if (arrangement is Map) {
      final arrangementMap = _map(arrangement);
      if (arrangementMap['song_id'] != songId ||
          arrangementMap['title'] is! String ||
          _normalize(arrangementMap['title'] as String) != _normalize(title)) {
        throw const ProviderException('identity_mismatch');
      }
    } else if (arrangement != null) {
      throw const ProviderException('invalid_response');
    }
    final rawKey = detail['key'];
    if (rawKey != null && rawKey is! String && rawKey is! List) {
      throw const ProviderException('invalid_response');
    }
    if (rawKey is List &&
        (rawKey.length > 16 || rawKey.any((item) => item is! String))) {
      throw const ProviderException('invalid_response');
    }
    final arrangementMap = arrangement is Map
        ? _map(arrangement)
        : const <String, dynamic>{};
    final arrangementKey = _optionalString(
      arrangementMap['target_key'] ?? arrangementMap['original_key'],
      max: 24,
    );
    final key =
        arrangementKey ??
        (rawKey is String ? _optionalString(rawKey, max: 24) : null);
    final rawSignature = _optionalString(detail['signature'], max: 32);
    final signature = _timeSignature(
      _optionalString(arrangementMap['signature'], max: 32) ?? rawSignature,
    );
    final type = _optionalString(detail['type'], max: 80);
    final tempo = _boundedTempo(detail['tempo']);
    return _FoundSong(
      id: id,
      songId: songId,
      title: title,
      url: url.toString(),
      apiUrl: apiUrl.toString(),
      detailArtist: artist,
      key: key,
      signature: signature,
      rawSignature: rawSignature,
      type: type,
      tempo: tempo,
    );
  }

  _Chart _arrangement(Object? raw, String id, String title) {
    if (raw == null) return const _Chart({}, []);
    if (raw is! Map) throw const ProviderException('invalid_response');
    final value = _map(raw);
    if (value['song_id'] != id ||
        value['title'] is! String ||
        _normalize(value['title'] as String) != _normalize(title)) {
      throw const ProviderException('identity_mismatch');
    }
    final rawSections = value['sections'];
    if (rawSections is! List || rawSections.length > _maxSections) {
      throw const ProviderException('invalid_response');
    }
    final sections = <_ChartSection>[];
    var totalMeasures = 0;
    for (final rawSection in rawSections) {
      if (rawSection is! Map) throw const ProviderException('invalid_response');
      final section = _map(rawSection);
      final name = _requiredString(section['name'], max: 80);
      final repeats = section['repeats'];
      if (repeats is! int || repeats < 1 || repeats > 32) {
        throw const ProviderException('invalid_response');
      }
      final rawMeasures = section['measures'];
      if (rawMeasures is! List || rawMeasures.isEmpty) {
        throw const ProviderException('invalid_response');
      }
      totalMeasures += rawMeasures.length;
      if (totalMeasures > _maxMeasures) {
        throw const ProviderException('invalid_response');
      }
      final measures = <List<String>>[];
      for (final rawMeasure in rawMeasures) {
        if (rawMeasure is! Map) {
          throw const ProviderException('invalid_response');
        }
        final measure = _map(rawMeasure);
        for (final field in ['source', 'display']) {
          if (measure[field] != null) {
            _requiredString(measure[field], max: 512);
          }
        }
        if (measure['index'] != null &&
            (measure['index'] is! int || (measure['index'] as int) < 0)) {
          throw const ProviderException('invalid_response');
        }
        final rawBeats = measure['beats'];
        if (rawBeats is! List ||
            rawBeats.isEmpty ||
            rawBeats.length > _maxBeatsPerMeasure) {
          throw const ProviderException('invalid_response');
        }
        final beatCount = measure['beat_count'];
        if (beatCount != null && beatCount != rawBeats.length) {
          throw const ProviderException('invalid_response');
        }
        final hasRest = rawBeats.any((beat) => beat == null);
        if (measure['has_rest'] != null && measure['has_rest'] != hasRest) {
          throw const ProviderException('invalid_response');
        }
        final beats = <String>[];
        for (final beat in rawBeats) {
          if (beat == null) {
            beats.add('N.C.');
          } else {
            if (beat is! String || beat != beat.trim()) {
              throw const ProviderException('invalid_response');
            }
            final chord = _requiredString(beat, max: 32);
            if (!_isFullChordToken(chord)) {
              throw const ProviderException('invalid_response');
            }
            beats.add(chord);
          }
        }
        measures.add(beats);
      }
      sections.add(_ChartSection(name, repeats, measures));
    }
    return _Chart(value, sections);
  }

  List<_LyricVariant> _lyrics(Object? rawLyrics, Object? rawAlternates) {
    if (rawLyrics == null) {
      if (rawAlternates != null &&
          rawAlternates is! List &&
          rawAlternates is! Map) {
        throw const ProviderException('invalid_response');
      }
      return const [];
    }
    final List<Object?> texts;
    if (rawLyrics is String) {
      if (rawLyrics.trim().isEmpty) return const [];
      texts = [rawLyrics];
    } else if (rawLyrics is List && rawLyrics.length <= _maxLyrics) {
      texts = rawLyrics.cast<Object?>();
    } else {
      throw const ProviderException('invalid_response');
    }
    if (texts.length > _maxLyrics) {
      throw const ProviderException('invalid_response');
    }
    final labels = _lyricLabels(rawAlternates, texts.length);
    final variants = <_LyricVariant>[];
    for (var i = 0; i < texts.length; i++) {
      if (texts[i] is String && (texts[i] as String).trim().isEmpty) continue;
      final text = clean(texts[i], _maxLyricsCharacters);
      if (text == null) throw const ProviderException('invalid_response');
      variants.add(
        _LyricVariant(
          index: i,
          label: texts.length == 1 && labels[i] == null
              ? null
              : labels[i] ?? 'Lyric variant ${i + 1}',
          text: text,
        ),
      );
    }
    return variants;
  }

  List<String?> _lyricLabels(Object? raw, int count) {
    final labels = List<String?>.filled(count, null);
    if (raw == null) return labels;
    if (raw is List) {
      if (raw.length > _maxLyrics) {
        throw const ProviderException('invalid_response');
      }
      for (var i = 0; i < raw.length; i++) {
        final value = raw[i];
        final index = value is Map ? _alternateIndex(value, i) : i;
        if (index < 0 || index >= count) continue;
        final label = value is Map
            ? _optionalString(
                value['label'] ?? value['name'] ?? value['language'],
                max: 80,
              )
            : _optionalString(value, max: 80);
        labels[index] = label;
      }
      return labels;
    }
    if (raw is Map) {
      if (raw.length > _maxLyrics) {
        throw const ProviderException('invalid_response');
      }
      for (final entry in raw.entries) {
        final index = int.tryParse(entry.key.toString());
        if (index == null || index < 0 || index >= count) continue;
        final value = entry.value;
        labels[index] = value is Map
            ? _optionalString(
                value['label'] ?? value['name'] ?? value['language'],
                max: 80,
              )
            : _optionalString(value, max: 80);
      }
      return labels;
    }
    throw const ProviderException('invalid_response');
  }

  int _alternateIndex(Map value, int fallback) {
    final raw = value['index'];
    if (raw == null) return fallback;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? -1;
  }

  String _renderBody(List<_LyricVariant> lyrics, List<_ChartSection> sections) {
    final out = StringBuffer();
    for (var i = 0; i < lyrics.length; i++) {
      final variant = lyrics[i];
      if (lyrics.length > 1) {
        out.writeln(
          directive(
            'comment',
            'Lyrics variant ${i + 1}: ${variant.label ?? 'unlabeled'}',
          ).trim(),
        );
      }
      out.writeln(_lyricsToChordPro(variant.text));
    }
    if (sections.isNotEmpty) {
      out.writeln(
        directive(
          'comment',
          'Chord progression (not aligned to lyrics)',
        ).trim(),
      );
      for (final section in sections) {
        final repeat = section.repeats > 1
            ? ' (repeat ${section.repeats}x)'
            : '';
        out.writeln(
          directive('comment', 'Section ${section.name}$repeat').trim(),
        );
        for (var i = 0; i < section.measures.length; i++) {
          out.writeln(directive('comment', 'Measure ${i + 1}').trim());
          out.writeln(section.measures[i].map((chord) => '[$chord]').join(' '));
        }
      }
    }
    return out.toString().trim();
  }

  String _lyricsToChordPro(String text) {
    final blocks = <({int open, int content, int close, int end})>[];
    var opening = 0;
    var content = 0;
    var inChorus = false;
    for (final match in _chorusTag.allMatches(text)) {
      final closing = match[1] == '/';
      if (closing ? !inChorus : inChorus) {
        throw const ProviderException('invalid_response');
      }
      if (closing) {
        blocks.add((
          open: opening,
          content: content,
          close: match.start,
          end: match.end,
        ));
      } else {
        opening = match.start;
        content = match.end;
      }
      inChorus = !closing;
    }
    if (inChorus) throw const ProviderException('invalid_response');

    final out = StringBuffer();
    var cursor = 0;
    for (final block in blocks) {
      out.write(plainToChordPro(text.substring(cursor, block.open)));
      final wholeLines =
          _lineBoundary(text, block.open - 1, -1) &&
          _lineBoundary(text, block.end, 1);
      // ChordPro section directives must occupy their own lines. Inline tags
      // inside a lyric line cannot become directives without changing its order.
      // Keep that text intact; the original tagged version remains in source facts.
      if (wholeLines) out.writeln('{start_of_chorus}');
      out.write(plainToChordPro(text.substring(block.content, block.close)));
      if (wholeLines) {
        out.writeln();
        out.writeln('{end_of_chorus}');
      }
      cursor = block.end;
    }
    out.write(plainToChordPro(text.substring(cursor)));
    return out.toString();
  }

  bool _lineBoundary(String text, int position, int step) {
    for (var i = position; i >= 0 && i < text.length; i += step) {
      final code = text.codeUnitAt(i);
      if (code == 10) return true;
      if (String.fromCharCode(code).trim().isNotEmpty) return false;
    }
    return true;
  }

  _SelectedIdentity _candidateIdentity(SongCandidate candidate) {
    final id = _canonicalId(candidate.id);
    final start = candidate.extra['startjamming'];
    if (start is! Map) throw const ProviderException('invalid_selection');
    final data = _map(start);
    if (data['id'] != id ||
        data['canonical_id'] != id ||
        data['slug'] != id ||
        data['song_id'] != id.replaceAll('-', '_')) {
      throw const ProviderException('invalid_selection');
    }
    final apiUrl = _validatedApiUrl(data['apiUrl'], id);
    final humanUrl = _validatedHumanUrl(candidate.url, id);
    if (candidate.title.isEmpty || !_idPattern.hasMatch(id)) {
      throw const ProviderException('invalid_selection');
    }
    return _SelectedIdentity(
      id: id,
      title: candidate.title,
      artist: candidate.artist,
      apiUrl: apiUrl,
      url: humanUrl,
    );
  }

  void _validateIdentityFields(JsonMap value, String id) {
    for (final field in ['canonical_id', 'slug']) {
      if (value[field] != id) throw const ProviderException('invalid_response');
    }
    if (value['song_id'] != id.replaceAll('-', '_')) {
      throw const ProviderException('invalid_response');
    }
    _validatedApiUrl(value['api_url'], id);
    _validatedHumanUrl(value['url'], id);
  }

  String _canonicalId(Object? value) {
    final id = _requiredString(value, max: 160);
    if (!_idPattern.hasMatch(id)) {
      throw const ProviderException('invalid_response');
    }
    return id;
  }

  Uri _validatedApiUrl(Object? raw, [String? expectedId]) {
    if (raw is! String || raw.length > 2048) {
      throw const ProviderException('invalid_url');
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != _host ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        uri.fragment.isNotEmpty ||
        uri.pathSegments.length != 4 ||
        uri.pathSegments[0] != 'api' ||
        uri.pathSegments[1] != 'songs' ||
        uri.pathSegments[3] != 'full' ||
        expectedId != null && uri.pathSegments[2] != expectedId ||
        uri.queryParametersAll.keys.length != 1 ||
        uri.queryParametersAll['for']?.length != 1 ||
        uri.queryParameters['for'] != 'agent') {
      throw const ProviderException('invalid_url');
    }
    _canonicalId(uri.pathSegments[2]);
    return uri;
  }

  Uri _validatedHumanUrl(Object? raw, String expectedId) {
    if (raw is! String || raw.length > 2048) {
      throw const ProviderException('invalid_url');
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != _host ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        uri.fragment.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.path != '/song/$expectedId') {
      throw const ProviderException('invalid_url');
    }
    return uri;
  }

  static String _requiredString(Object? value, {required int max}) {
    final text = clean(value, max);
    if (text == null) throw const ProviderException('invalid_response');
    return text;
  }

  static String? _optionalString(Object? value, {required int max}) {
    if (value == null) return null;
    if (value is! String) throw const ProviderException('invalid_response');
    if (value.length > max) throw const ProviderException('invalid_response');
    final text = clean(value, max);
    return text;
  }

  static String? _optionalSourceKey(Object? value) {
    if (value is! List) return _optionalString(value, max: 24);
    if (value.length > 16) throw const ProviderException('invalid_response');
    for (final key in value) {
      _requiredString(key, max: 24);
    }
    // Search can report multiple arrangements, without identifying a default.
    // The full response's normalized arrangement supplies its selected key.
    return null;
  }

  static double? _boundedTempo(Object? value) {
    if (value == null) return null;
    if (value is! num || !value.isFinite || value <= 0 || value > 500) {
      throw const ProviderException('invalid_response');
    }
    return value.toDouble();
  }

  static String? _timeSignature(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'waltz':
        return '3/4';
      case 'common':
        return '4/4';
      default:
        return RegExp(r'^\d{1,2}/\d{1,2}$').hasMatch(value) ? value : null;
    }
  }

  static List<JsonMap> _mediaLinks(JsonMap detail) {
    final links = <JsonMap>[];
    final seen = <String>{};
    for (final source in [
      ('demo', 'Demo video'),
      ('featured_demo', 'Featured demo video'),
    ]) {
      final raw = detail[source.$1];
      if (raw == null) continue;
      if (raw is! List || raw.length > 64) {
        throw const ProviderException('invalid_response');
      }
      for (final item in raw.take(30)) {
        final url = _youtubeUrl(item);
        if (url != null && seen.add(url)) {
          links.add({'kind': 'youtube', 'label': source.$2, 'url': url});
        }
      }
    }
    return links;
  }

  static String? _youtubeUrl(Object? value) {
    if (value is! String || value.length > 2048) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        uri.fragment.isNotEmpty) {
      return null;
    }
    String? id;
    if (uri.host == 'www.youtube.com' || uri.host == 'youtube.com') {
      if (uri.path == '/watch') {
        id = uri.queryParameters['v'];
      } else if (uri.pathSegments.length == 2 &&
          const {'embed', 'shorts', 'live'}.contains(uri.pathSegments.first)) {
        id = uri.pathSegments.last;
      }
    } else if (uri.host == 'youtu.be' && uri.pathSegments.length == 1) {
      id = uri.pathSegments.single;
    }
    return id != null && isYoutubeId(id) ? uri.toString() : null;
  }

  static JsonMap _map(Object? value) {
    if (value is! Map) throw const ProviderException('invalid_response');
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      throw const ProviderException('invalid_response');
    }
  }

  static bool _isFullChordToken(String value) {
    final source = '[$value]';
    final match = chordPattern.matchAsPrefix(source);
    return match != null && match.start == 0 && match.end == source.length;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp("['‘’]"), '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  static void _validateJsonShape(Object? root) {
    var entries = 0;
    void visit(Object? value, int depth) {
      if (depth > 12 || entries > 30000) {
        throw const ProviderException('invalid_response');
      }
      if (value is String) {
        entries++;
        if (value.length > _maxLyricsCharacters) {
          throw const ProviderException('invalid_response');
        }
      } else if (value is Map) {
        if (value.length > 256) {
          throw const ProviderException('invalid_response');
        }
        entries += value.length;
        for (final entry in value.entries) {
          if (entry.key is! String || (entry.key as String).length > 128) {
            throw const ProviderException('invalid_response');
          }
          visit(entry.value, depth + 1);
        }
      } else if (value is List) {
        if (value.length > _maxMeasures) {
          throw const ProviderException('invalid_response');
        }
        entries += value.length;
        for (final item in value) {
          visit(item, depth + 1);
        }
      } else if (value is num && !value.isFinite) {
        throw const ProviderException('invalid_response');
      }
    }

    visit(root, 0);
  }
}

class _CachedJson {
  const _CachedJson({
    required this.value,
    required this.etag,
    required this.bytes,
    required this.contentType,
    required this.retrievedAt,
    required this.expiresAt,
    required this.validatedAt,
  });
  final dynamic value;
  final String? etag;
  final List<int> bytes;
  final String? contentType;
  final DateTime retrievedAt, expiresAt, validatedAt;
}

class _FetchedJson {
  const _FetchedJson({
    required this.value,
    required this.etag,
    required this.bytes,
    required this.contentType,
    required this.retrievedAt,
    required this.validatedAt,
  });
  final dynamic value;
  final String? etag;
  final List<int> bytes;
  final String? contentType;
  final DateTime retrievedAt, validatedAt;
}

class _SelectedIdentity {
  const _SelectedIdentity({
    required this.id,
    required this.title,
    required this.artist,
    required this.apiUrl,
    required this.url,
  });
  final String id, title, artist;
  final Uri apiUrl, url;
}

class _FoundSong {
  const _FoundSong({
    required this.id,
    required this.songId,
    required this.title,
    required this.url,
    required this.apiUrl,
    required this.detailArtist,
    required this.key,
    required this.signature,
    required this.rawSignature,
    required this.type,
    required this.tempo,
  });
  final String id, songId, title, url, apiUrl;
  final String? detailArtist, key, signature, rawSignature, type;
  final double? tempo;
}

class _LyricVariant {
  const _LyricVariant({
    required this.index,
    required this.label,
    required this.text,
  });
  final int index;
  final String? label;
  final String text;
}

class _Chart {
  const _Chart(this.raw, this.sections);
  final JsonMap raw;
  final List<_ChartSection> sections;
}

class _ChartSection {
  const _ChartSection(this.name, this.repeats, this.measures);
  final String name;
  final int repeats;
  final List<List<String>> measures;
}
