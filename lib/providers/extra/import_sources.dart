import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as html;
import '../../domain/models.dart';
import '../provider.dart';
import '../core/common.dart' show plainToChordPro;
import 'common.dart';

/// A real file/paste ingestion route, deliberately distinct from remote lookup.
/// Callers open definition.website and use the normal file picker or paste flow.
class FileImportProvider implements LyricsProvider {
  FileImportProvider(this.definition);
  @override
  final ProviderDefinition definition;
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    throw const ProviderException('file_import_required');
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    throw const ProviderException('file_import_required');
  }

  SourceResult importDocument(
    String text, {
    String? fileName,
    String? title,
    String? artist,
  }) {
    requireSongText(text);
    final name =
        chordProTitle(text, 'title') ??
        title ??
        fileName?.replaceFirst(RegExp(r'\.[^.]+$'), '') ??
        '';
    if (name.trim().isEmpty) throw const ProviderException('title_required');
    final found = SongCandidate(
      providerId: definition.id,
      id: sha256.convert(utf8.encode(text)).toString(),
      title: name,
      artist: chordProTitle(text, 'artist') ?? artist ?? '',
      url: definition.website,
      metadata: const {
        'identityScope': 'arrangement',
        'importMethod': 'userFile',
      },
    );
    return SourceResult(
      candidate: found,
      body: text,
      metadata: chordProMetadata(text),
      attribution: definition.name,
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(found, attribution: definition.name, original: text),
        'userSelectedImport': true,
        'fileName': ?fileName,
      },
    );
  }
}

class OzbcozProvider extends FileImportProvider {
  OzbcozProvider()
    : super(
        const ProviderDefinition(
          id: 'ozbcoz',
          name: 'Ozbcoz',
          capabilities: {'fileImport', 'lyrics', 'chords', 'metadata'},
          accessMode: 'fileImport',
          enabledByDefault: false,
          description: 'downloadChordProThenImport',
          website: 'https://ozbcoz.com/Songs/cp/',
        ),
      );
}

class WorshipTogetherProvider extends FileImportProvider {
  WorshipTogetherProvider()
    : super(
        const ProviderDefinition(
          id: 'worshiptogether',
          name: 'Worship Together',
          capabilities: {'fileImport', 'lyrics', 'chords', 'metadata'},
          accessMode: 'freeAccountImport',
          enabledByDefault: false,
          description: 'freeAccountDownloadThenImport',
          website: 'https://www.worshiptogether.com/songs/',
        ),
      );
}

class ChordieProvider implements LyricsProvider {
  ChordieProvider(this.transport);
  final ProviderTransport transport;
  @override
  final definition = const ProviderDefinition(
    id: 'chordie',
    name: 'Chordie',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata', 'fileImport'},
    accessMode: 'publicPage',
    website: 'https://www.chordie.com/',
    description: 'publicChordSheets',
  );
  static final base = Uri.parse('https://www.chordie.com/');
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final source = await transport.getText(
      base
          .resolve('result.php')
          .replace(queryParameters: {'q': queryText(query)}),
      cancel: cancel,
    );
    final doc = parseHtml(source);
    final found = <String, SongCandidate>{};
    for (final anchor in doc.querySelectorAll('a[href]')) {
      final spans = anchor.querySelectorAll('span');
      if (spans.length < 2) continue;
      final url = base.resolve(anchor.attributes['href']!);
      if (url.host != base.host || !url.path.startsWith('/chord.pere/')) {
        continue;
      }
      // Chordie double-encodes some characters ("&amp;#38;").
      String decoded(String html) =>
          textValue(html).replaceAllMapped(RegExp(r'&#(\d{1,6});'), (m) {
            final code = int.parse(m[1]!);
            return code > 0 && code <= 0x10FFFF
                ? String.fromCharCode(code)
                : m[0]!;
          });
      final title = decoded(spans[0].innerHtml),
          artist = decoded(spans[1].innerHtml);
      if (title.isEmpty || artist.isEmpty) continue;
      found[url.path] = SongCandidate(
        providerId: definition.id,
        id: url.path,
        title: title,
        artist: artist,
        url: url.toString(),
        metadata: const {'identityScope': 'arrangement'},
      );
    }
    if (found.isEmpty) throwIfBlocked(source);
    return found.values.take(12).toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    var found = candidate;
    if (candidate.providerId != definition.id) {
      final matches = (await search(candidate.title, cancel: cancel)).where(
        (c) =>
            normalized(c.title) == normalized(candidate.title) &&
            normalized(c.artist) == normalized(candidate.artist),
      );
      if (matches.isEmpty) throw const ProviderException('unavailable');
      found = matches.first;
    }
    final uri = checkedUrl(found.url ?? '', {
      base.host,
    }, prefix: '/chord.pere/');
    final source = await transport.getText(uri, cancel: cancel);
    final doc = parseHtml(source);
    // Fallback selectors tolerate small markup changes.
    final node =
        doc.querySelector('textarea#chordproContent') ??
        doc.querySelector('textarea[name="chordproContent"]') ??
        doc.querySelector('#chordproContent');
    final text = remoteChordPro(node?.text.trim() ?? '');
    if (text.trim().isEmpty) {
      throwIfBlocked(source);
      throw const ProviderException('extraction_failed');
    }
    requireSongText(text);
    final title = chordProTitle(text, 'title');
    if (title != null && normalized(title) != normalized(found.title)) {
      throw const ProviderException('identity_mismatch');
    }
    // Untrusted link: dropped unless it is a plain public https URL.
    final original = doc
        .querySelectorAll('a[href]')
        .where((a) => normalized(a.text) == 'original song')
        .map((a) => resolvedLink(uri, a.attributes['href']))
        .nonNulls
        .firstOrNull;
    return SourceResult(
      candidate: found,
      body: text,
      metadata: {
        ...chordProMetadata(text),
        ...found.metadata,
        'originalSourceUrl': ?original,
      },
      attribution: original == null
          ? 'Chordie'
          : 'Chordie; original source: $original',
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          attribution: 'Chordie',
          original: text,
          provenanceNote:
              'Read from a public web page; Chordie has not granted Singbook any redistribution license. Sharing or exporting is the user\'s responsibility.',
        ),
        'originalSourceUrl': ?original,
      },
    );
  }
}

class WikisourceProvider implements LyricsProvider {
  WikisourceProvider(this.transport);
  final ProviderTransport transport;
  @override
  final definition = const ProviderDefinition(
    id: 'wikisource',
    name: 'Wikisource',
    capabilities: {'catalog', 'lyrics', 'metadata', 'fileImport'},
    accessMode: 'publicDomainText',
    enabledByDefault: false,
    website: 'https://en.wikisource.org/',
    description: 'historicalTextPerWorkLicense',
  );
  Future<JsonMap> _api(
    Map<String, String> params,
    CancellationToken? cancel,
  ) async {
    final result = jsonMap(
      await transport.requestJson(
        Uri.https('en.wikisource.org', '/w/api.php', {
          'format': 'json',
          'formatversion': '2',
          'maxlag': '5',
          ...params,
        }),
        cancel: cancel,
      ),
    );
    throwIfApiError(result);
    return result;
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final result = await _api({
      'action': 'query',
      'list': 'search',
      'srsearch': queryText(query),
      'srnamespace': '0',
      'srlimit': '10',
    }, cancel);
    return maps(jsonMap(result['query'])['search'])
        .map(
          (r) => SongCandidate(
            providerId: definition.id,
            id: r['pageid'].toString(),
            title: stringValue(r['title']),
            artist: '',
            url: 'https://en.wikisource.org/?curid=${r['pageid']}',
            metadata: {
              'identityScope': 'historicalText',
              'snippet': textValue(r['snippet']),
            },
          ),
        )
        .toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    // A poem is not evidence for an arbitrary contemporary recording. This
    // source requires a user-selected catalog page, not fuzzy automatic import.
    if (candidate.providerId != definition.id ||
        !RegExp(r'^\d+$').hasMatch(candidate.id)) {
      throw const ProviderException('user_selection_required');
    }
    final result = await _api({
      'action': 'parse',
      'pageid': candidate.id,
      'prop': 'text|revid|templates|categories',
    }, cancel);
    final parsed = jsonMap(result['parse']);
    final pageId = parsed['pageid'];
    if (pageId is! int ||
        pageId <= 0 ||
        pageId.toString() != candidate.id ||
        stringValue(parsed['title']).isEmpty ||
        _wikisourceTitleIdentity(stringValue(parsed['title'])) !=
            _wikisourceTitleIdentity(candidate.title)) {
      throw const ProviderException('identity_mismatch');
    }
    final revision = parsed['revid'];
    if (revision is! int || revision <= 0) {
      throw const ProviderException('invalid_response');
    }
    final templates = maps(
      parsed['templates'],
    ).map((r) => stringValue(r['title'])).toList();
    if (templates.any((t) => t.toLowerCase().contains('disambig'))) {
      throw const ProviderException('select_specific_work');
    }
    final rights = templates
        .where(
          (t) => RegExp(
            r'^Template:(?:PD-|Cc-by|CC0)',
            caseSensitive: false,
          ).hasMatch(t),
        )
        .toList();
    if (rights.isEmpty) throw const ProviderException('rights_review_required');
    final doc = parseHtml(stringValue(parsed['text']));
    final poems = doc.querySelectorAll('.poem');
    if (poems.isEmpty) throw const ProviderException('unavailable');
    if (poems.any(htmlTooDeep)) {
      throw const ProviderException('extraction_failed');
    }
    final blocks = <String>[];
    for (final poem in poems) {
      for (final br in poem.querySelectorAll('br')) {
        br.replaceWith(html.parseFragment('\n'));
      }
      final text = poem.text.trim();
      if (text.isNotEmpty) blocks.add(text);
    }
    // Wiki text is editable by anyone: drop Singbook directives, then escape
    // ChordPro syntax so poem brackets never become chords or directives.
    final body = plainToChordPro(remoteChordPro(blocks.join('\n\n')));
    requireSongText(body);
    final authors = doc
        .querySelectorAll('a[href^="/wiki/Author:"]')
        .map((a) => a.text.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final found = SongCandidate(
      providerId: definition.id,
      id: candidate.id,
      title: stringValue(parsed['title']).isEmpty
          ? candidate.title
          : stringValue(parsed['title']),
      artist: authors.join(', '),
      url: candidate.url,
      metadata: {
        'identityScope': 'historicalText',
        'resolvedPageId': pageId.toString(),
        'resolvedTitle': stringValue(parsed['title']),
        'revision': revision,
        'copyrightTags': rights,
      },
    );
    return SourceResult(
      candidate: found,
      body: body,
      metadata: found.metadata,
      attribution: '${found.artist}; Wikisource contributors',
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          license: rights.join('; '),
          licenseUrl:
              'https://en.wikisource.org/wiki/Wikisource:Copyright_policy',
          attribution: '${found.artist}; Wikisource contributors',
          revision: revision.toString(),
          permissions: {'status': 'per_work_and_jurisdiction', 'tags': rights},
        ),
        'userSelectedImport': true,
      },
    );
  }
}

String _wikisourceTitleIdentity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
