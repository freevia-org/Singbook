import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;

import '../../domain/models.dart';
import '../../domain/source_text_variant.dart';
import '../provider.dart';
import 'common.dart';
import 'mutopia_lilypond.dart';

/// Inert source adapter for the small, evidenced Mutopia search/detail subset.
/// It fetches only HTML pages and the linked LilyPond text file. LilyPond,
/// Scheme, includes, scores, MIDI, PDF and other linked media are never run or
/// fetched.
class MutopiaProvider implements LyricsProvider {
  MutopiaProvider(this.transport);

  final ProviderTransport transport;

  static const _host = 'www.mutopiaproject.org';
  static const _htmlLimit = 512 * 1024;
  static const _lilypondLimit = 512 * 1024;
  static const _maxResults = 64;
  static const _maxEditionsPerSearch = 3;
  static const _license = 'Public Domain';
  static const _licenseUrl =
      'http://creativecommons.org/licenses/publicdomain/';

  @override
  final definition = const ProviderDefinition(
    id: 'mutopia',
    name: 'Mutopia Project',
    capabilities: {'catalog', 'lyrics', 'metadata'},
    enabledByDefault: false,
    accessMode: 'publicDomainText',
    website: 'https://www.mutopiaproject.org/',
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final q = queryText(query);
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(q)) {
      throw const ProviderException('invalid_query');
    }
    cancel?.throwIfCancelled();
    final uri = Uri.https(_host, '/cgibin/make-table.cgi', {'searchingfor': q});
    final searchBytes = await _getBytes(
      uri,
      maxBytes: _htmlLimit,
      cancel: cancel,
    );
    final searchHtml = _decodeText(searchBytes);
    cancel?.throwIfCancelled();
    final hits = _parseSearch(searchHtml);

    final candidates = <SongCandidate>[];
    final seenEditions = <String>{};
    var editionsDownloaded = 0;
    // Inspect explicit vocal listings first. Keep the publisher's order within
    // each group and the same request cap; instrumental editions must not
    // consume the whole budget before a known vocal result can be examined.
    final ordered = [
      ...hits.where((hit) => _explicitVocal(hit.instrument)),
      ...hits.where((hit) => !_explicitVocal(hit.instrument)),
    ];
    for (final hit in ordered) {
      cancel?.throwIfCancelled();
      if (hit.license.toLowerCase() != _license.toLowerCase()) continue;
      if (!seenEditions.add(hit.id)) {
        throw const ProviderException('extraction_failed');
      }
      if (editionsDownloaded >= _maxEditionsPerSearch) break;
      editionsDownloaded++;

      final lilyBytes = await _getBytes(
        hit.lilypondUrl,
        maxBytes: _lilypondLimit,
        cancel: cancel,
      );
      final document = _parseLilypond(lilyBytes);
      _validateHeader(
        document,
        editionId: hit.id,
        expectedTitle: hit.title,
        expectedComposer: hit.composer,
      );
      // Supported notation may legitimately contain no lyric words (or a
      // blank placeholder beside a complete text). That is unavailable text,
      // while unsupported vocal grammar still fails in _parseLilypond.
      for (final stream in document.lyricStreams.where(
        (stream) => stream.text.trim().isNotEmpty,
      )) {
        final variable = stream.publisherVariable;
        if (variable == null || !_validVariable(variable)) {
          throw const ProviderException('extraction_failed');
        }
        candidates.add(
          _candidate(
            editionId: hit.id,
            streamVariable: variable,
            title: document.mutopiatitle!,
            composer: document.composer!,
            url: hit.detailUrl,
            document: document,
            hit: hit,
          ),
        );
      }
    }
    cancel?.throwIfCancelled();
    return List.unmodifiable(candidates);
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    if (candidate.providerId != definition.id) {
      throw const ProviderException('user_selection_required');
    }
    final match = RegExp(
      r'^([1-9][0-9]{0,8}):([A-Za-z][A-Za-z0-9_]{0,63})$',
    ).firstMatch(candidate.id);
    if (match == null) throw const ProviderException('user_selection_required');
    final editionId = match.group(1)!;
    final streamVariable = match.group(2)!;
    final detailUrl = _detailUri(editionId);
    final detailBytes = await _getBytes(
      detailUrl,
      maxBytes: _htmlLimit,
      cancel: cancel,
    );
    final detail = _parseDetail(
      _decodeText(detailBytes),
      expectedId: editionId,
    );
    cancel?.throwIfCancelled();

    final detailTitle = detail.title;
    final detailComposer = detail.composer;
    if (_normalize(candidate.title) != _normalize(detailTitle) ||
        !_sameComposer(candidate.artist, detailComposer)) {
      throw const ProviderException('identity_mismatch');
    }
    if (detail.license.toLowerCase() != _license.toLowerCase()) {
      throw const ProviderException('unavailable');
    }

    final lilyBytes = await _getBytes(
      detail.lilypondUrl,
      maxBytes: _lilypondLimit,
      cancel: cancel,
    );
    final document = _parseLilypond(lilyBytes);
    _validateHeader(
      document,
      editionId: editionId,
      expectedTitle: detailTitle,
      expectedComposer: detailComposer,
    );
    if (detail.typesetUsing != 'LilyPond, version ${document.version}') {
      throw const ProviderException('extraction_failed');
    }
    cancel?.throwIfCancelled();
    final selected = document.lyricStreams
        .where((s) => s.publisherVariable == streamVariable)
        .toList();
    if (selected.length != 1) {
      throw const ProviderException('identity_mismatch');
    }

    final canonical = _candidate(
      editionId: editionId,
      streamVariable: streamVariable,
      title: document.mutopiatitle!,
      composer: document.composer!,
      url: detailUrl,
      document: document,
      detail: detail,
    );
    final selectedText = selected.single.text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final body = _literal(selectedText);
    requireSongText(body);

    final attribution = _attribution(document, detail);
    final source = sourceEvidence(
      canonical,
      license: _license,
      licenseUrl: _licenseUrl,
      attribution: attribution,
      evidenceUrl: detailUrl.toString(),
      permissions: const {
        'status': 'source_declared',
        'scope': 'Mutopia edition and publisher lyric text',
        'recording': 'not established',
      },
      provenanceNote:
          'Public Domain is the publisher declaration for this edition. '
          'No recording, performer, active score attachment, language, '
          'timing or chord data is inferred.',
    );
    source['sourceDocumentId'] = 'mutopia:$editionId';
    final rights = source['rights'] as Map<String, dynamic>;
    rights['sourceId'] = editionId;
    rights['sourceUrl'] = detailUrl.toString();

    final streams = <JsonMap>[
      for (final stream in document.lyricStreams)
        {
          'publisherVariable': stream.publisherVariable,
          if (stream.literalVoiceReference != null)
            'literalVoiceReference': stream.literalVoiceReference,
          'attachmentVerified': false,
          'text': stream.text,
          'sourceOffsetUnit': 'utf16CodeUnitsInDecodedTextWithoutBom',
          'sourceSpan': [stream.sourceSpan.start, stream.sourceSpan.end],
          'bodySpan': [stream.bodySpan.start, stream.bodySpan.end],
          'syllables': [
            for (final syllable in stream.syllables)
              {
                'text': syllable.text,
                'joinBefore': syllable.joinBefore.name,
                'sourceSpan': [syllable.span.start, syllable.span.end],
              },
          ],
        },
    ];
    final extra = <String, dynamic>{
      ...source,
      'parserVersion': 'mutopia-lilypond-inert-1',
      'originalPayloads': [
        _payload(detailBytes, 'text/html', detailUrl.toString()),
        _payload(lilyBytes, 'text/x-lilypond', detail.lilypondUrl.toString()),
      ],
      'mutopia': {
        'editionId': editionId,
        'detailUrl': detailUrl.toString(),
        'lilypondUrl': detail.lilypondUrl.toString(),
        'mutopiatitle': document.mutopiatitle,
        'title': document.title,
        'composer': document.composer,
        'detailComposer': detail.composer,
        'poet': document.poet,
        'arranger': document.arranger,
        'license': document.license,
        'footer': document.footer,
        'lilypondVersion': document.version,
        'sourceOffsetUnit': 'utf16CodeUnitsInDecodedTextWithoutBom',
        'originalBytesPreservedSeparately': true,
        'sourceCitation': detail.sourceCitation,
        'lilypondHeaderSourceCitation': document.source,
        'publisherMetadata': detail.toJson(),
        'streams': streams,
      },
    };
    cancel?.throwIfCancelled();
    return SourceResult(
      candidate: canonical,
      body: body,
      metadata: canonical.metadata,
      matchKind: MatchKind.sameSong,
      matchReason: 'same_song',
      attribution: attribution,
      retrievedAt: DateTime.now().toUtc(),
      extra: extra,
    );
  }

  Future<Uint8List> _getBytes(
    Uri uri, {
    required int maxBytes,
    CancellationToken? cancel,
  }) async {
    _validateRequestUri(uri);
    cancel?.throwIfCancelled();
    final bytes = await transport.getBytes(
      uri,
      allowedHosts: {_host},
      maxBytes: maxBytes,
      cancel: cancel,
    );
    cancel?.throwIfCancelled();
    return bytes;
  }

  static Uri _detailUri(String id) =>
      Uri.https(_host, '/cgibin/piece-info.cgi', {'id': id});

  static void _validateRequestUri(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host != _host ||
        uri.userInfo.isNotEmpty ||
        (uri.hasPort && uri.port != 443) ||
        uri.fragment.isNotEmpty ||
        uri.path.contains(RegExp(r'%2f|%5c|%2e', caseSensitive: false)) ||
        uri.toString().split('?').first.contains('%') ||
        uri.pathSegments.any((s) => s == '.' || s == '..' || s.contains('/')) ||
        !_validPath(uri.path)) {
      throw const ProviderException('invalid_url');
    }
    if (uri.path == '/cgibin/make-table.cgi') {
      if (uri.queryParametersAll.keys.toSet().difference({
            'searchingfor',
          }).isNotEmpty ||
          uri.queryParametersAll['searchingfor']?.length != 1) {
        throw const ProviderException('invalid_url');
      }
    } else if (uri.path == '/cgibin/piece-info.cgi') {
      if (uri.queryParametersAll.keys.toSet().difference({'id'}).isNotEmpty ||
          uri.queryParametersAll['id']?.length != 1 ||
          !RegExp(
            r'^[1-9][0-9]{0,8}$',
          ).hasMatch(uri.queryParametersAll['id']!.single)) {
        throw const ProviderException('invalid_url');
      }
    } else if (uri.query.isNotEmpty) {
      throw const ProviderException('invalid_url');
    }
  }

  static bool _validPath(String path) =>
      path == '/cgibin/make-table.cgi' ||
      path == '/cgibin/piece-info.cgi' ||
      RegExp(
        r'^/ftp/[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*/[A-Za-z0-9_-]+\.ly$',
      ).hasMatch(path);

  static List<_SearchHit> _parseSearch(String source) {
    if (source.length > _htmlLimit) {
      throw const ProviderException('invalid_response');
    }
    throwIfBlocked(source);
    final doc = parseHtml(source);
    final outer = doc.querySelectorAll('table.outer-table');
    if (outer.length != 1) throw const ProviderException('extraction_failed');
    final tables = outer.single.querySelectorAll('table.result-table');
    if (doc.querySelectorAll('table.result-table').length != tables.length) {
      throw const ProviderException('extraction_failed');
    }
    if (tables.isEmpty) {
      const emptyText =
          'Sorry, no matches were found for your search criteria.';
      final markers = doc
          .querySelectorAll('div.alert.alert-info[role="alert"]')
          .where((alert) => _cellText(alert, max: 200) == emptyText);
      if (markers.length == 1) {
        return const [];
      }
      throw const ProviderException('extraction_failed');
    }
    if (tables.length > _maxResults) {
      throw const ProviderException('invalid_response');
    }
    final hits = <_SearchHit>[];
    final seen = <String>{};
    for (final table in tables) {
      final rows = _rows(table);
      if (rows.length != 5) throw const ProviderException('extraction_failed');
      final cells = rows.map(_cells).toList();
      if (cells.any((row) => row.length != 4)) {
        throw const ProviderException('extraction_failed');
      }
      for (final cell in cells[4]) {
        _cellText(cell, max: 500);
      }
      final title = _cellText(cells[0][0], max: 300);
      final composer = _stripBy(_cellText(cells[0][1], max: 300));
      final instrument = _stripPrefix(_cellText(cells[1][0], max: 300), 'for ');
      final style = _cellText(cells[1][2], max: 100);
      final arranger = _cellText(cells[1][3], max: 300);
      final source = _cellText(cells[2][0], max: 5000);
      final license = _cellText(cells[2][1], max: 100);
      final infoLink = _singleLink(cells[2][2]);
      final updated = _cellText(cells[2][3], max: 30);
      final lilyLink = _singleLink(cells[3][0]);
      final date = _parseSlashDate(updated);
      if (title.isEmpty ||
          composer.isEmpty ||
          instrument.isEmpty ||
          style.isEmpty ||
          source.isEmpty ||
          date == null ||
          infoLink == null ||
          lilyLink == null ||
          !_linkLabel(infoLink, 'More Information') ||
          _cellText(cells[0][2], max: 100).isNotEmpty ||
          _cellText(cells[0][3], max: 100).isNotEmpty ||
          _cellText(cells[1][1], max: 100).isNotEmpty ||
          !_linkLabel(lilyLink, '.ly file')) {
        throw const ProviderException('extraction_failed');
      }
      final id = _detailIdFromLink(infoLink);
      if (id == null || !seen.add(id)) {
        throw const ProviderException('extraction_failed');
      }
      final lilyUrl = _checkedLilyUrl(lilyLink.attributes['href']);
      if (lilyUrl == null) throw const ProviderException('extraction_failed');
      final detailUrl = _checkedDetailLink(infoLink.attributes['href']);
      if (detailUrl == null || detailUrl != _detailUri(id)) {
        throw const ProviderException('extraction_failed');
      }
      hits.add(
        _SearchHit(
          id: id,
          title: title,
          composer: composer,
          sourceCitation: source,
          license: license,
          updated: updated,
          instrument: instrument,
          style: style,
          arranger: arranger,
          detailUrl: detailUrl,
          lilypondUrl: lilyUrl,
        ),
      );
    }
    return hits;
  }

  static _Detail _parseDetail(String source, {required String expectedId}) {
    if (source.length > _htmlLimit) {
      throw const ProviderException('invalid_response');
    }
    throwIfBlocked(source);
    final doc = parseHtml(source);
    final titleHeadings = doc.querySelectorAll('h2');
    final composerHeadings = doc.querySelectorAll('h4');
    if (titleHeadings.length != 1 || composerHeadings.length != 1) {
      throw const ProviderException('extraction_failed');
    }
    final title = _cellText(titleHeadings.single, max: 300);
    final composer = _stripBy(_cellText(composerHeadings.single, max: 300));
    final tables = doc.querySelectorAll('table.result-table');
    final metadataTables = tables.where((table) {
      final text = boundedText(table.text, max: _htmlLimit);
      return text.contains('Music ID Number:') && text.contains('Copyright:');
    }).toList();
    final downloadTables = tables
        .where(
          (table) => table
              .querySelectorAll('a')
              .any((a) => _cellText(a, max: 100) == 'LilyPond file'),
        )
        .toList();
    if (metadataTables.length != 1 || downloadTables.length != 1) {
      throw const ProviderException('extraction_failed');
    }

    final fields = <String, String>{};
    dom.Element? copyrightCell;
    for (final cell in metadataTables.single.querySelectorAll('td')) {
      final value = _cellText(cell, max: 8000);
      final key = const [
        'Instrument(s):',
        'Style:',
        'Arranger(s):',
        'Opus:',
        'Date of composition:',
        'Source:',
        'Copyright:',
        'Last updated:',
        'Music ID Number:',
        'Typeset using:',
      ].firstWhere((label) => value.startsWith(label), orElse: () => '');
      if (key.isEmpty) continue;
      final field = value.substring(key.length).trim();
      if (fields.containsKey(key) && fields[key] != field) {
        throw const ProviderException('extraction_failed');
      }
      fields[key] = field;
      if (key == 'Copyright:') copyrightCell = cell;
    }
    final musicId = fields['Music ID Number:'] ?? '';
    final idMatch = RegExp(
      r'^Mutopia-\d{4}/\d{2}/\d{2}-([1-9][0-9]{0,8})$',
    ).firstMatch(musicId);
    if (title.isEmpty ||
        composer.isEmpty ||
        idMatch?.group(1) != expectedId ||
        fields['Source:']?.isEmpty != false ||
        fields['Instrument(s):']?.isEmpty != false ||
        fields['Style:']?.isEmpty != false ||
        fields['Last updated:']?.isEmpty != false ||
        fields['Copyright:']?.toLowerCase() != _license.toLowerCase()) {
      throw const ProviderException('extraction_failed');
    }
    final licenseLinks = copyrightCell?.querySelectorAll('a') ?? const [];
    if (!licenseLinks.any((a) => a.attributes['href'] == _licenseUrl)) {
      throw const ProviderException('extraction_failed');
    }
    final lilyAnchors = downloadTables.single
        .querySelectorAll('a')
        .where((a) => _cellText(a, max: 100) == 'LilyPond file')
        .toList();
    if (lilyAnchors.length != 1) {
      throw const ProviderException('extraction_failed');
    }
    final lilyUrl = _checkedLilyUrl(lilyAnchors.single.attributes['href']);
    if (lilyUrl == null) throw const ProviderException('extraction_failed');
    return _Detail(
      id: expectedId,
      title: title,
      composer: composer,
      instrument: fields['Instrument(s):']!,
      style: fields['Style:']!,
      arranger: fields['Arranger(s):'] ?? '',
      opus: fields['Opus:'] ?? '',
      compositionDate: fields['Date of composition:'] ?? '',
      sourceCitation: fields['Source:']!,
      license: fields['Copyright:']!,
      updated: fields['Last updated:']!,
      musicId: musicId,
      typesetUsing: fields['Typeset using:'] ?? '',
      lilypondUrl: lilyUrl,
    );
  }

  static List<dom.Element> _rows(dom.Element table) {
    final result = <dom.Element>[];
    for (final child in table.children) {
      if (child.localName == 'tr') result.add(child);
      if (child.localName == 'tbody' || child.localName == 'thead') {
        result.addAll(child.children.where((e) => e.localName == 'tr'));
      }
    }
    return result;
  }

  static List<dom.Element> _cells(dom.Element row) => row.children
      .where((e) => e.localName == 'td' || e.localName == 'th')
      .toList();

  static String _cellText(dom.Element element, {required int max}) {
    final text = element.text;
    if (text.length > max) throw const ProviderException('invalid_response');
    return boundedText(text, max: max);
  }

  static dom.Element? _singleLink(dom.Element cell) {
    final links = cell.querySelectorAll('a');
    return links.length == 1 ? links.single : null;
  }

  static bool _linkLabel(dom.Element link, String expected) =>
      _cellText(link, max: 80) == expected;

  static String? _detailIdFromLink(dom.Element link) {
    final uri = _checkedDetailLink(link.attributes['href']);
    return uri?.queryParameters['id'];
  }

  static Uri? _checkedDetailLink(String? value) {
    if (value == null ||
        value.length > 512 ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(value)) {
      return null;
    }
    final ref = Uri.tryParse(value);
    if (ref == null ||
        ref.hasScheme ||
        ref.hasAuthority ||
        ref.hasFragment ||
        ref.path != 'piece-info.cgi' ||
        !RegExp(r'^id=[1-9][0-9]{0,8}$').hasMatch(ref.query)) {
      return null;
    }
    final id = ref.query.substring('id='.length);
    return _detailUri(id);
  }

  static Uri? _checkedLilyUrl(String? value) {
    if (value == null ||
        value.length > 2048 ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(value)) {
      return null;
    }
    final ref = Uri.tryParse(value);
    if (ref == null ||
        !ref.hasScheme ||
        !ref.hasAuthority ||
        ref.scheme != 'https' ||
        ref.host != _host ||
        ref.userInfo.isNotEmpty ||
        ref.hasQuery ||
        ref.hasFragment ||
        ref.path.contains('%') ||
        ref.pathSegments.any((s) => s == '.' || s == '..' || s.contains('/'))) {
      return null;
    }
    final uri = ref;
    try {
      _validateRequestUri(uri);
    } on ProviderException {
      return null;
    }
    if (!uri.path.endsWith('.ly') || !uri.path.startsWith('/ftp/')) {
      return null;
    }
    return uri;
  }

  static DateTime? _parseSlashDate(String value) {
    final match = RegExp(r'^(\d{4})/(\d{2})/(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static bool _explicitVocal(String instrumentation) => RegExp(
    r'\b(?:voice|voices|vocal|vocals|choir|chorus|satb)\b',
    caseSensitive: false,
  ).hasMatch(instrumentation);

  static String _stripBy(String value) =>
      value.replaceFirst(RegExp(r'^by\s+', caseSensitive: false), '').trim();

  static String _stripPrefix(String value, String prefix) =>
      value.toLowerCase().startsWith(prefix.toLowerCase())
      ? value.substring(prefix.length).trim()
      : '';

  static String _normalize(String value) => normalized(value);

  static bool _sameComposer(String first, String second) {
    final a = _nameParts(first);
    final b = _nameParts(second);
    if (a.isEmpty || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] == b[i]) continue;
      final explicitInitial =
          (a[i].length == 1 && b[i].startsWith(a[i])) ||
          (b[i].length == 1 && a[i].startsWith(b[i]));
      if (!explicitInitial) return false;
    }
    return true;
  }

  static List<String> _nameParts(String value) {
    final withoutYears = value.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    return normalized(
      withoutYears,
    ).split(' ').where((part) => part.isNotEmpty).toList();
  }

  static bool _validVariable(String value) =>
      RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}$').hasMatch(value);

  static MutopiaLilypondDocument _parseLilypond(Uint8List bytes) {
    final source = _decodeText(bytes);
    try {
      return parseMutopiaLilypond(source);
    } on MutopiaFormatException {
      throw const ProviderException('extraction_failed');
    }
  }

  static void _validateHeader(
    MutopiaLilypondDocument document, {
    required String editionId,
    required String expectedTitle,
    required String expectedComposer,
  }) {
    const textBounds = {
      'title': 300,
      'mutopiatitle': 300,
      'composer': 300,
      'poet': 300,
      'arranger': 300,
      'source': 8000,
      'license': 100,
      'footer': 100,
    };
    if (textBounds.entries.any(
      (bound) => (document.header[bound.key]?.length ?? 0) > bound.value,
    )) {
      throw const ProviderException('invalid_response');
    }
    final title = document.mutopiatitle;
    final composer = document.composer;
    final license = document.license;
    final footer = document.footer;
    if (title == null ||
        composer == null ||
        license == null ||
        footer == null ||
        _normalize(title) != _normalize(expectedTitle) ||
        !_sameComposer(composer, expectedComposer) ||
        license.toLowerCase() != _license.toLowerCase() ||
        !RegExp(
          r'^Mutopia-\d{4}/\d{2}/\d{2}-' + RegExp.escape(editionId) + r'$',
        ).hasMatch(footer)) {
      throw const ProviderException('extraction_failed');
    }
  }

  static SongCandidate _candidate({
    required String editionId,
    required String streamVariable,
    required String title,
    required String composer,
    required Uri url,
    required MutopiaLilypondDocument document,
    _SearchHit? hit,
    _Detail? detail,
  }) {
    final poet = document.poet;
    final arranger = document.arranger ?? detail?.arranger ?? hit?.arranger;
    final sourceCitation =
        detail?.sourceCitation ?? hit?.sourceCitation ?? document.source;
    final instrument = detail?.instrument ?? hit?.instrument;
    final style = detail?.style ?? hit?.style;
    final credits = <JsonMap>[
      {'role': 'Composer', 'name': composer},
      if (poet != null && poet.isNotEmpty) {'role': 'Poet', 'name': poet},
      if (arranger != null && arranger.isNotEmpty)
        {'role': 'Arranger', 'name': arranger},
    ];
    return SongCandidate(
      providerId: 'mutopia',
      id: '$editionId:$streamVariable',
      title: title,
      artist: composer,
      url: url.toString(),
      metadata: {
        'identityScope': 'arrangement',
        'artistCreditRole': 'composer',
        'composer': composer,
        if (hit != null) 'searchComposer': hit.composer,
        if (detail != null) 'detailComposer': detail.composer,
        'lilypondHeaderComposer': document.composer,
        if (poet != null && poet.isNotEmpty) 'poet': poet,
        if (arranger != null && arranger.isNotEmpty) 'arranger': arranger,
        'credits': credits,
        'mutopiaEditionId': editionId,
        'mutopiaLilypondUrl':
            hit?.lilypondUrl.toString() ?? detail?.lilypondUrl.toString(),
        'mutopiaDetailId': editionId,
        'sourceVariantLabel': streamVariable,
        // Use the existing explicit-version contract to keep parallel texts
        // out of automatic lyric donation to a different selected stream.
        'version': sourceTextVariantVersion('$editionId:$streamVariable'),
        'mutopiaLicense': _license,
        if (sourceCitation != null && sourceCitation.isNotEmpty)
          'sourceCitation': sourceCitation,
        if (hit != null) 'searchSourceCitation': hit.sourceCitation,
        if (instrument != null && instrument.isNotEmpty)
          'instrumentation': instrument,
        if (style != null && style.isNotEmpty) 'style': style,
        if (hit != null || detail != null)
          'updated': hit?.updated ?? detail!.updated,
      },
    );
  }

  static String _attribution(MutopiaLilypondDocument document, _Detail detail) {
    final names = <String>[
      if (document.composer != null) 'Composer: ${document.composer}',
      if (document.poet != null) 'Poet: ${document.poet}',
      if (document.arranger != null) 'Arranger: ${document.arranger}',
    ];
    return 'Mutopia Project — ${detail.title}; ${names.join('; ')}; '
        'publisher-declared Public Domain edition.';
  }

  static JsonMap _payload(Uint8List bytes, String contentType, String url) => {
    'contentType': contentType,
    'encoding': 'utf-8',
    'base64': base64Encode(bytes),
    'sha256': sha256.convert(bytes).toString(),
    'httpBodyBytesExact': true,
    'wireExact': false,
    'sourceUrl': url,
  };

  static String _decodeText(Uint8List bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: false);
      return text.startsWith('\uFEFF') ? text.substring(1) : text;
    } on FormatException {
      throw const ProviderException('invalid_response');
    }
  }

  static String _literal(String value) => value.replaceAllMapped(
    RegExp(r'[\\\[\]{}#]'),
    (match) => '\\${match[0]}',
  );
}

class _SearchHit {
  const _SearchHit({
    required this.id,
    required this.title,
    required this.composer,
    required this.sourceCitation,
    required this.license,
    required this.updated,
    required this.instrument,
    required this.style,
    required this.arranger,
    required this.detailUrl,
    required this.lilypondUrl,
  });

  final String id, title, composer, sourceCitation, license, updated;
  final String instrument, style, arranger;
  final Uri detailUrl, lilypondUrl;
}

class _Detail {
  const _Detail({
    required this.id,
    required this.title,
    required this.composer,
    required this.instrument,
    required this.style,
    required this.arranger,
    required this.opus,
    required this.compositionDate,
    required this.sourceCitation,
    required this.license,
    required this.updated,
    required this.musicId,
    required this.typesetUsing,
    required this.lilypondUrl,
  });

  final String id, title, composer, instrument, style, arranger, opus;
  final String compositionDate, sourceCitation, license, updated, musicId;
  final String typesetUsing;
  final Uri lilypondUrl;

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'composer': composer,
    'instrumentation': instrument,
    'style': style,
    if (arranger.isNotEmpty) 'arranger': arranger,
    if (opus.isNotEmpty) 'opus': opus,
    if (compositionDate.isNotEmpty) 'compositionDate': compositionDate,
    'sourceCitation': sourceCitation,
    'license': license,
    'updated': updated,
    'musicId': musicId,
    'typesetUsing': typesetUsing,
    'lilypondUrl': lilypondUrl.toString(),
  };
}
