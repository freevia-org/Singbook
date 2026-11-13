import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:characters/characters.dart';
import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

/// Catalog ids may be strings or numbers; anything else is not an id.
String _rowId(Object? value) =>
    value is String ? value.trim() : (value is int ? value.toString() : '');

/// Mirrors the transport's JSON text handling (UTF-8, optional BOM).
Object? _decodeJsonBytes(Uint8List bytes) {
  final text = utf8.decode(bytes, allowMalformed: true);
  return jsonDecode(text.startsWith('\uFEFF') ? text.substring(1) : text);
}

/// The registry is several MB: decode it off the calling isolate. The closure
/// captures only [bytes].
Future<Object?> _decodeJsonInBackground(Uint8List bytes) =>
    Isolate.run(() => _decodeJsonBytes(bytes));

class WorshipCommonsProvider implements LyricsProvider {
  WorshipCommonsProvider(this.transport);
  final ProviderTransport transport;
  final _catalog = CatalogLoader<({List<JsonMap> rows, List<String> text})>();
  /// Full commit SHA of ChurchApps/WorshipCommonsContent the catalog, song
  /// files and license links are read from, so content and licenses cannot
  /// change without an app update. Resolved 2026-10-15 (the `main` commit
  /// committed 2026-10-13T14:34:05Z); its catalog.json is about 3.5 MB, within
  /// the 12 MB cap. To bump: run
  /// `gh api repos/ChurchApps/WorshipCommonsContent/commits/main --jq .sha`,
  /// confirm catalog.json at that SHA still parses (`flutter test
  /// test/providers/extra`), then update this constant and docs/sources.md.
  static const contentRef = 'd3362e1d7c7f4d3f98b9310bb07aa480453508c7';
  static const _repositoryPath = '/ChurchApps/WorshipCommonsContent';
  static const _catalogLimit = 12 * 1024 * 1024;
  static final base = Uri.parse(
    'https://raw.githubusercontent.com$_repositoryPath/$contentRef/',
  );
  @override
  final definition = const ProviderDefinition(
    id: 'worshipcommons',
    name: 'WorshipCommons',
    capabilities: {'catalog', 'lyrics', 'chords', 'timing', 'metadata'},
    website: 'https://github.com/ChurchApps/WorshipCommonsContent',
    description: 'licensedCatalog',
  );

  Future<({List<JsonMap> rows, List<String> text})> _load(
    CancellationToken? cancel,
  ) => _catalog.load(() async {
    final bytes = await transport.getBytes(
      base.resolve('catalog.json'),
      headers: const {'Accept': 'application/json'},
      cancel: cancel,
      // The registry is large; an oversized file fails as invalid_response
      // (never a truncated catalog).
      maxBytes: _catalogLimit,
      // Several MB on a slow link; still inside discover's 30 s ceiling.
      timeout: const Duration(seconds: 28),
    );
    cancel?.throwIfCancelled();
    final Object? decoded;
    try {
      decoded = await _decodeJsonInBackground(bytes);
    } catch (_) {
      throw const ProviderException('invalid_response', 'Invalid JSON');
    }
    cancel?.throwIfCancelled();
    final data = jsonMap(decoded);
    if (data['rows'] is! List) {
      throw const ProviderException('invalid_response');
    }
    // The registry is heterogeneous. Restricted worship-only or custom licenses
    // remain on the source website, rather than being silently made unrestricted.
    final rows = maps(data['rows'])
        .where(
          (r) =>
              {'PD', 'CC-BY', 'CC-BY-SA'}.contains(r['license']) &&
              r['status'] == 'approved' &&
              _rowId(r['id']).isNotEmpty &&
              stringValue(r['title']).isNotEmpty,
        )
        .toList();
    return (
      rows: rows,
      // Search text is normalised once per catalog, not once per query.
      text: [
        for (final r in rows)
          normalized('${stringValue(r['title'])} ${stringValue(r['writer'])}'),
      ],
    );
  }, cancel);

  Future<List<JsonMap>> _rows(CancellationToken? cancel) async =>
      (await _load(cancel)).rows;

  SongCandidate _candidate(JsonMap r) => SongCandidate(
    providerId: definition.id,
    id: _rowId(r['id']),
    title: boundedText(r['title']),
    artist: boundedText(r['writer']),
    url: '${base}catalog.json',
    metadata: sanitizeExtraMetadata({
      'identityScope': 'composition',
      'writer': r['writer'],
      if (r['language'] != null) 'language': r['language'],
      if (r['year'] != null) 'compositionYear': r['year'],
    }),
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final catalog = await _load(cancel);
    final tokens = queryTokens(query);
    return [
      for (var i = 0; i < catalog.rows.length; i++)
        if (tokensMatch(tokens, catalog.text[i])) catalog.rows[i],
    ].take(12).map(_candidate).toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    var rows = await _rows(cancel);
    rows = candidate.providerId == definition.id
        ? rows.where((r) => _rowId(r['id']) == candidate.id).toList()
        : rows
              .where(
                (r) =>
                    normalized(stringValue(r['title'])) ==
                        normalized(candidate.title) &&
                    normalized(stringValue(r['writer'])) ==
                        normalized(candidate.artist),
              )
              .toList();
    if (rows.isEmpty) throw const ProviderException('unavailable');
    final r = rows.first;
    final found = _candidate(r);
    // Providers must not inject Singbook provenance/rights/timing directives.
    final body = remoteChordPro(stringValue(r['chordPro']));
    requireSongText(body);
    final metadata = <String, dynamic>{
      ...found.metadata,
      if (r['songKey'] != null) 'key': r['songKey'],
      if (r['bpm'] != null) 'tempo': r['bpm'],
      if (r['timeSignature'] != null) 'timeSignature': r['timeSignature'],
      if (r['meter'] != null) 'meter': r['meter'],
      if (r['themes'] != null) 'themes': r['themes'],
      if (r['scripture'] != null) 'scripture': r['scripture'],
      if (r['ccli'] != null) 'ccli': r['ccli'],
    };
    final media = <JsonMap>[];
    for (final key in [
      'videoUrl',
      'demoAudioUrl',
      'previewUrl',
      'instrumentalUrl',
      'midiUrl',
      'abcUrl',
      'sheetPdfUrl',
    ]) {
      final link = resolvedLink(base, r[key]);
      if (link != null) media.add({'type': key, 'url': link});
    }
    if (media.isNotEmpty) metadata['mediaLinks'] = media;
    // Catalog art can be illustrative; do not silently call it recording artwork.
    final illustration = resolvedLink(base, r['artUrl']);
    if (illustration != null) metadata['sourceIllustrationUrl'] = illustration;
    final tracks = <TimingTrack>[];
    final timingUrl = stringValue(r['lyricsUrl']);
    String? timingFailure;
    if (timingUrl.isNotEmpty) {
      try {
        final url = checkedUrl(
          base.resolve(timingUrl).toString(),
          {base.host},
          prefix: '$_repositoryPath/$contentRef/songs/',
        );
        final raw = await transport.getText(url, cancel: cancel);
        tracks.add(parseWorshipTiming(raw, found.identity));
      } on ProviderException catch (e) {
        if (e.code == 'cancelled') rethrow;
        timingFailure = e.code;
      }
    }
    final license = stringValue(r['license']);
    final attribution = stringValue(r['attribution']).isEmpty
        ? found.artist
        : stringValue(r['attribution']);
    return SourceResult(
      candidate: found,
      body:
          directive('title', found.title) +
          directive('artist', found.artist) +
          body,
      metadata: sanitizeExtraMetadata(metadata),
      timingTracks: tracks,
      attribution: attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          license: license,
          attribution: attribution,
          licenseUrl:
              httpsLink(r['licenseUrl']) ??
              'https://github.com/ChurchApps/WorshipCommonsContent/blob/$contentRef/LICENSE.md',
          original: body,
          permissions: {
            'status': 'source_declared',
            'offline': true,
            'attributionRequired': license != 'PD',
            'shareAlike': license == 'CC-BY-SA',
          },
        ),
        'timingFailure': ?timingFailure,
      },
    );
  }
}

/// Repository timing describes its own demonstration, never a selected cover.
/// Preserve the JSON even if a future schema cannot currently be normalized.
TimingTrack parseWorshipTiming(String raw, String sourceId) {
  final cues = <TimingCue>[];
  final lines = <String>[];
  var status = TimingStatus.unverified;
  try {
    final data = jsonMap(jsonDecode(raw));
    if (data['stanzas'] is! List) {
      throw const FormatException('Unknown timing schema');
    }
    for (final stanza in maps(data['stanzas'])) {
      for (final line in (stanza['lines'] as List? ?? [])) {
        final words = maps(line);
        if (words.isEmpty) continue;
        final occurrence = 'line-${lines.length}';
        var offset = 0;
        final parts = <String>[];
        for (final word in words) {
          final text = stringValue(word['text']);
          final start = word['t'];
          final duration = word['d'];
          if (text.isEmpty ||
              start is! num ||
              !start.isFinite ||
              start < 0 ||
              start > 86400 ||
              (duration != null &&
                  (duration is! num || !duration.isFinite || duration < 0))) {
            throw const FormatException('Invalid cue');
          }
          if (cues.length >= 100000) {
            throw const FormatException('Too many cues');
          }
          cues.add(
            TimingCue(
              id: '$sourceId:${cues.length}',
              occurrenceId: occurrence,
              text: text,
              startUs: (start * 1000000).round(),
              endUs: duration is num
                  ? ((start + duration) * 1000000).round()
                  : null,
              graphemeStart: offset,
              graphemeEnd: offset + text.characters.length,
              originalBegin: start.toString(),
              extra: {'duration': duration},
            ),
          );
          offset += text.characters.length + 1;
          parts.add(text);
        }
        lines.add(parts.join(' '));
      }
    }
    if (cues.isEmpty) status = TimingStatus.unsupported;
  } catch (_) {
    status = TimingStatus.invalid;
  }
  return TimingTrack(
    id: '$sourceId:timing',
    sourceDocumentId: sourceId,
    sourceLyrics: lines.join('\n'),
    format: 'worshipcommons-json',
    raw: raw,
    cues: status == TimingStatus.invalid ? [] : cues,
    status: status,
    granularity: 'word',
    extra: {
      'parserVersion': 'worshipcommons-1',
      'recordingEvidence': 'sourceDemonstrationOnly',
      'precision': 'seconds-decimal',
    },
  );
}

class SeanMcGrathProvider implements LyricsProvider {
  SeanMcGrathProvider(this.transport);
  final ProviderTransport transport;
  final _catalog = CatalogLoader<List<SongCandidate>>();
  static final base = Uri.parse('https://seanmcgrathmusic.com/');
  @override
  final definition = const ProviderDefinition(
    id: 'seanmcgrathmusic',
    name: 'Sean McGrath Music',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    website: 'https://seanmcgrathmusic.com/',
    description: 'originalSongsCcBy',
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final catalog = await _catalog.load(() async {
      final source = await transport.getText(
        base.resolve('songs_and_poems/'),
        cancel: cancel,
      );
      final doc = parseHtml(source);
      final found = <String, SongCandidate>{};
      for (final a in doc.querySelectorAll('a[href]')) {
        final u = resolvedUri(base, a.attributes['href']);
        if (u == null ||
            u.scheme != 'https' ||
            u.host != base.host ||
            !RegExp(
              r'^/(?:songs|songs_and_poems)/[a-z0-9-]+/$',
            ).hasMatch(u.path) ||
            a.text.trim().isEmpty) {
          continue;
        }
        // The first (title) link wins; later 'Listen'/'More' anchors to the same
        // song must not rename it.
        // Keep identities from before the publisher's October 2026 path move.
        final stablePath = '/songs/${u.pathSegments[1]}/';
        found.putIfAbsent(
          stablePath,
          () => SongCandidate(
            providerId: definition.id,
            id: stablePath,
            title: boundedText(a.text),
            artist: 'Sean McGrath',
            url: u.toString(),
            metadata: const {'identityScope': 'composition'},
          ),
        );
      }
      // A bot wall or changed layout is a failure, never a cached empty catalog.
      if (found.isEmpty) {
        throwIfBlocked(source);
        throw const ProviderException('extraction_failed');
      }
      return found.values.toList();
    }, cancel);
    final tokens = queryTokens(query);
    return catalog
        .where((c) => tokensMatch(tokens, normalized('${c.title} ${c.artist}')))
        .take(12)
        .toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    SongCandidate found = candidate;
    if (candidate.providerId != definition.id) {
      if (normalized(candidate.artist) != 'sean mcgrath') {
        throw const ProviderException('unavailable');
      }
      final rows = await search(candidate.title, cancel: cancel);
      final exact = rows.where(
        (r) => normalized(r.title) == normalized(candidate.title),
      );
      if (exact.isEmpty) throw const ProviderException('unavailable');
      found = exact.first;
    }
    final supplied = checkedUrl(found.url ?? '', {base.host}, prefix: '/');
    if (!RegExp(
          r'^/(?:songs|songs_and_poems)/[a-z0-9-]+/$',
        ).hasMatch(supplied.path) ||
        supplied.hasQuery ||
        supplied.hasFragment) {
      throw const ProviderException('invalid_url');
    }
    // Resolve saved pre-migration candidates at the publisher's current URL.
    final url = base.resolve('songs_and_poems/${supplied.pathSegments[1]}/');
    found = SongCandidate.fromJson({...found.toJson(), 'url': url.toString()});
    final page = parseHtml(await transport.getText(url, cancel: cancel));
    final links = page
        .querySelectorAll('a[href]')
        .map((a) => resolvedUri(url, a.attributes['href']))
        .nonNulls
        .toList();
    final files = links.where(
      (u) =>
          u.host == base.host &&
          u.path.startsWith('/assets/chordpro/') &&
          u.path.endsWith('.pro'),
    );
    if (files.isEmpty) throw const ProviderException('unavailable');
    final original = remoteChordPro(
      await transport.getText(
        checkedUrl(files.first.toString(), {
          base.host,
        }, prefix: '/assets/chordpro/'),
        cancel: cancel,
      ),
    );
    requireSongText(original);
    final media = <JsonMap>[];
    for (final iframe in page.querySelectorAll('iframe[src]')) {
      final uri = Uri.tryParse(iframe.attributes['src']!);
      if (uri != null &&
          {'www.youtube.com', 'www.youtube-nocookie.com'}.contains(uri.host) &&
          uri.path.startsWith('/embed/') &&
          isYoutubeId(uri.pathSegments.last)) {
        media.add({
          'type': 'video',
          'url': 'https://www.youtube.com/watch?v=${uri.pathSegments.last}',
        });
      }
    }
    for (final link in links.where(
      (u) => u.host == 'drive.google.com' && u.path == '/uc',
    )) {
      final safe = httpsLink(link.toString());
      if (safe != null) media.add({'type': 'audio', 'url': safe});
    }
    return SourceResult(
      candidate: found,
      body: original,
      metadata: sanitizeExtraMetadata({
        ...found.metadata,
        ...chordProMetadata(original),
        if (media.isNotEmpty) 'mediaLinks': media,
      }),
      attribution: 'Sean McGrath Music / @seanmcgrathmusic',
      retrievedAt: DateTime.now().toUtc(),
      extra: sourceEvidence(
        found,
        license: 'CC BY 4.0',
        licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
        attribution: 'Sean McGrath Music / @seanmcgrathmusic',
        evidenceUrl: base.toString(),
        original: original,
        permissions: {
          'status': 'source_declared',
          'offline': true,
          'redistribute': true,
          'attributionRequired': true,
        },
      ),
    );
  }
}

class OpenFilkProvider implements LyricsProvider {
  OpenFilkProvider(this.transport);
  final ProviderTransport transport;
  final _catalog = CatalogLoader<List<SongCandidate>>();
  static final index = Uri.parse(
    'https://filksongbook.com/songs/_index/by_title__en.html',
  );
  @override
  final definition = const ProviderDefinition(
    id: 'openfilksongbook',
    name: 'Open Filk Songbook',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    website: 'https://filksongbook.com/',
    description: 'perSongLicense',
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final catalog = await _catalog.load(() async {
      final source = await transport.getText(index, cancel: cancel);
      final doc = parseHtml(source);
      final found = <SongCandidate>[];
      for (final li in doc.querySelectorAll('li')) {
        // Each reference is resolved once; a malformed one is skipped.
        final anchors = [
          for (final a in li.querySelectorAll('a[href]'))
            if (resolvedUri(index, a.attributes['href']) case final target?)
              (element: a, target: target),
        ];
        final pages = anchors.where(
          (a) => a.target.path.startsWith('/songs/pages/'),
        );
        final files = anchors.where(
          (a) => a.target.path.startsWith('/songs/Chordpro/'),
        );
        if (pages.isEmpty || files.isEmpty) continue;
        final u = files.first.target;
        if (u.host != index.host || !u.path.endsWith('.pro')) continue;
        final artist =
            RegExp(r'\(([^)]+)\)').allMatches(li.text).lastOrNull?[1] ?? '';
        final links = <JsonMap>[
          for (final a in anchors)
            if (a.target.host != index.host)
              if (httpsLink(a.target.toString()) case final link?)
                {'type': 'recording', 'url': link},
        ];
        found.add(
          SongCandidate(
            providerId: definition.id,
            id: u.path,
            title: pages.first.element.text.trim(),
            artist: artist,
            url: u.toString(),
            metadata: {
              'identityScope': 'composition',
              'sourcePageUrl': pages.first.target.toString(),
              if (links.isNotEmpty) 'mediaLinks': links,
            },
          ),
        );
      }
      // A bot wall or changed layout is a failure, never a cached empty catalog.
      if (found.isEmpty) {
        throwIfBlocked(source);
        throw const ProviderException('extraction_failed');
      }
      return found;
    }, cancel);
    final tokens = queryTokens(query);
    return catalog
        .where((c) => tokensMatch(tokens, normalized('${c.title} ${c.artist}')))
        .take(12)
        .toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    var found = candidate;
    if (candidate.providerId != definition.id) {
      final results = await search(candidate.title, cancel: cancel);
      final matches = results.where(
        (r) =>
            normalized(r.title) == normalized(candidate.title) &&
            normalized(r.artist) == normalized(candidate.artist),
      );
      if (matches.isEmpty) throw const ProviderException('unavailable');
      found = matches.first;
    }
    final url = checkedUrl(found.url ?? '', {
      index.host,
    }, prefix: '/songs/Chordpro/');
    if (!url.path.endsWith('.pro')) {
      throw const ProviderException('invalid_url');
    }
    final original = remoteChordPro(
      await transport.getText(url, cancel: cancel),
    );
    requireSongText(original);
    final licenseLines = RegExp(
      r'^\{c:\s*License[^\r\n]*\}',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(original).map((m) => m[0]!).toList();
    // No blanket assumption: a file without its own license line is recorded as
    // undeclared (the site's default license is only noted as provenance).
    final license = licenseLines.isEmpty
        ? null
        : licenseLines.take(5).map((l) => boundedText(l, max: 200)).join('\n');
    return SourceResult(
      candidate: found,
      body: original,
      metadata: sanitizeExtraMetadata({
        ...found.metadata,
        ...chordProMetadata(original),
      }),
      attribution: found.artist,
      retrievedAt: DateTime.now().toUtc(),
      extra: sourceEvidence(
        found,
        license: license,
        licenseUrl: 'https://filksongbook.com/info/en/licenses/',
        attribution: found.artist,
        original: original,
        provenanceNote: license == null
            ? 'The source site states a default license at '
                  'https://filksongbook.com/info/en/licenses/; this file does '
                  'not declare one.'
            : null,
        permissions: {
          'status': license == null ? 'unknown' : 'per_file',
          'offline': true,
          'redistribute': 'see_original_license',
          'modifyLyrics': 'see_original_license',
        },
      ),
    );
  }
}
