import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import '../../domain/models.dart';
import '../provider.dart';
import 'common.dart';

/// Publisher-documented ChordPro download, not a recording catalog or a claim
/// that its educational-use statement licenses redistribution of every song.
class RoswellMusicJamProvider implements LyricsProvider {
  RoswellMusicJamProvider(
    this.transport, {
    this.cacheLifetime = const Duration(hours: 24),
  });
  final ProviderTransport transport;
  final Duration cacheLifetime;
  static final songbooks = Uri.https('www.roswellmusicjam.com', '/songbooks');
  static const _hosts = {'www.roswellmusicjam.com'};
  static const _archiveLimit = 4 * 1024 * 1024;
  static const _entryLimit = 512 * 1024;
  static const _totalLimit = 16 * 1024 * 1024;
  static const _fileLimit = 1000;
  static final _filename = RegExp(r"^[a-z0-9][a-z0-9.'_-]{0,159}\.chordpro$");
  static final _release = RegExp(
    r'^rmj-all-chordpro-(\d{8})_(\d{6})-[A-Z]{2,5}\.zip$',
  );
  _RoswellCatalog? _cached;
  Future<void> _queue = Future.value();

  @override
  final definition = const ProviderDefinition(
    id: 'roswellmusicjam',
    name: 'Roswell Music Jam',
    capabilities: {'catalog', 'lyrics', 'chords', 'metadata'},
    accessMode: 'publicWeb',
    website: 'https://www.roswellmusicjam.com/songbooks',
    enabledByDefault: false,
  );

  Future<_RoswellCatalog> _catalog(CancellationToken? cancel) {
    final result = _queue.then((_) async {
      cancel?.throwIfCancelled();
      final previous = _cached;
      if (previous != null &&
          DateTime.now().difference(previous.loadedAt) < cacheLifetime) {
        return previous;
      }
      final page = await transport.getText(
        songbooks,
        cancel: cancel,
        maxBytes: 2 * 1024 * 1024,
        allowedHosts: _hosts,
      );
      throwIfBlocked(page);
      final archiveUrl = _latestArchive(page);
      final bytes = await transport.getBytes(
        archiveUrl,
        cancel: cancel,
        maxBytes: _archiveLimit,
        allowedHosts: _hosts,
      );
      cancel?.throwIfCancelled();
      final charts = _readArchive(bytes, cancel);
      cancel?.throwIfCancelled();
      // Commit a complete validated catalog only. Failures do not poison the
      // previous cache, and expired data never masquerades as a healthy refresh.
      return _cached = _RoswellCatalog(
        charts,
        archiveUrl,
        sha256.convert(bytes).toString(),
        DateTime.now(),
      );
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    if (cancel == null) return result;
    return Future.any([
      result,
      cancel.cancelled.then<_RoswellCatalog>((_) {
        throw const ProviderException('cancelled');
      }),
    ]);
  }

  static Uri _latestArchive(String page) {
    final links = <String, Uri>{};
    for (final anchor in parseHtml(page).querySelectorAll('a[href]')) {
      final raw = anchor.attributes['href'];
      if (raw == null || raw.length > 2048) continue;
      final parsed = Uri.tryParse(raw);
      if (parsed == null) continue;
      final url = songbooks.resolveUri(parsed);
      if (url.scheme != 'https' ||
          !_hosts.contains(url.host) ||
          url.userInfo.isNotEmpty ||
          (url.hasPort && url.port != 443) ||
          url.fragment.isNotEmpty ||
          !RegExp(
            r'^/_files/archives/[A-Za-z0-9_-]+\.zip$',
          ).hasMatch(url.path) ||
          url.queryParametersAll.length != 1 ||
          url.queryParametersAll['dn']?.length != 1) {
        continue;
      }
      final release = _release.firstMatch(url.queryParameters['dn'] ?? '');
      if (release == null) continue;
      final date = release[1]!, time = release[2]!;
      final stamp = '$date$time';
      final values = [
        int.parse(date.substring(0, 4)),
        int.parse(date.substring(4, 6)),
        int.parse(date.substring(6, 8)),
        int.parse(time.substring(0, 2)),
        int.parse(time.substring(2, 4)),
        int.parse(time.substring(4, 6)),
      ];
      final parsedDate = DateTime.utc(
        values[0],
        values[1],
        values[2],
        values[3],
        values[4],
        values[5],
      );
      if (parsedDate.year != values[0] ||
          parsedDate.month != values[1] ||
          parsedDate.day != values[2] ||
          parsedDate.hour != values[3] ||
          parsedDate.minute != values[4] ||
          parsedDate.second != values[5]) {
        continue;
      }
      // Multiple different files advertised as the same release are ambiguous.
      final existing = links[stamp];
      if (existing != null && existing != url) {
        throw const ProviderException('invalid_response');
      }
      links[stamp] = url;
    }
    if (links.isEmpty) throw const ProviderException('extraction_failed');
    final latest = links.keys.toList()..sort();
    return links[latest.last]!;
  }

  static Map<String, _RoswellChart> _readArchive(
    Uint8List bytes,
    CancellationToken? cancel,
  ) {
    try {
      if (bytes.length > _archiveLimit) {
        throw const FormatException('Archive too large');
      }
      _checkDirectory(bytes);
      // Reading the directory directly avoids ZipDecoder's eager symlink
      // expansion and duplicate-name collapsing before our validation.
      final directory = ZipDirectory()..read(InputMemoryStream(bytes));
      if (directory.fileHeaders.isEmpty ||
          directory.fileHeaders.length > _fileLimit ||
          directory.fileHeaders.length !=
              directory.totalCentralDirectoryEntries) {
        throw const FormatException('Invalid archive directory');
      }
      var total = 0;
      final names = <String>{};
      for (final header in directory.fileHeaders) {
        cancel?.throwIfCancelled();
        final file = header.file;
        final mode = (header.externalFileAttributes >> 16) & 0xf000;
        if (!_filename.hasMatch(header.filename) ||
            !names.add(header.filename) ||
            header.generalPurposeBitFlag & 1 != 0 ||
            !{0, 8}.contains(header.compressionMethod) ||
            mode != 0 && mode != 0x8000 ||
            header.diskNumberStart != 0 ||
            header.uncompressedSize <= 0 ||
            header.uncompressedSize > _entryLimit ||
            header.compressedSize > _entryLimit ||
            file == null ||
            file.filename != header.filename ||
            file.flags & 1 != 0 ||
            file.flags != header.generalPurposeBitFlag ||
            file.compressionMethod !=
                (header.compressionMethod == 0
                    ? CompressionType.none
                    : CompressionType.deflate)) {
          throw const FormatException('Unsupported archive entry');
        }
        total += header.uncompressedSize;
        if (total > _totalLimit) {
          throw const FormatException('Archive expands beyond limit');
        }
      }
      final charts = <String, _RoswellChart>{};
      for (final header in directory.fileHeaders) {
        cancel?.throwIfCancelled();
        final decoded = header.file!.getStream().toUint8List();
        if (decoded.length != header.uncompressedSize ||
            getCrc32(decoded) != header.crc32) {
          throw const FormatException('Invalid archive content');
        }
        final text = utf8.decode(decoded);
        // Dart's UTF-8 decoder consumes an initial BOM. Retain it in the raw
        // payload so exporting source evidence reproduces the publisher bytes.
        final hasBom =
            decoded.length >= 3 &&
            decoded[0] == 0xef &&
            decoded[1] == 0xbb &&
            decoded[2] == 0xbf;
        final raw = hasBom ? '\uFEFF$text' : text;
        final body = remoteChordPro(
          raw.startsWith('\uFEFF') ? raw.substring(1) : raw,
        ).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
        requireSongText(body);
        final title = boundedText(chordProTitle(body, 'title'));
        if (title.isEmpty) throw const FormatException('Missing chart title');
        // Artist may be absent in the publisher's chart. Never invent one or
        // attach that arrangement automatically to a foreign recording.
        final artist = boundedText(chordProTitle(body, 'artist'));
        final metadata = sanitizeExtraMetadata({
          ...chordProMetadata(body),
          'identityScope': 'arrangement',
          'sourceCollections': _directives(body, 'book'),
          'credits': [
            for (final role in ['composer', 'lyricist'])
              for (final name in _directives(body, role))
                {'role': role, 'name': name},
          ],
        });
        charts[header.filename] = _RoswellChart(
          title,
          artist,
          body,
          raw,
          metadata,
        );
      }
      return charts;
    } on ProviderException {
      rethrow;
    } catch (_) {
      throw const ProviderException('invalid_response');
    }
  }

  // Bound the central directory before the archive library materializes it.
  // This publisher ships ordinary single-disk ZIPs; ZIP64 is unnecessary here.
  static void _checkDirectory(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var eocd = -1;
    for (var i = bytes.length - 22; i >= 0 && i >= bytes.length - 65557; i--) {
      if (data.getUint32(i, Endian.little) == 0x06054b50 &&
          i + 22 + data.getUint16(i + 20, Endian.little) == bytes.length) {
        eocd = i;
        break;
      }
    }
    if (eocd < 0 ||
        data.getUint16(eocd + 4, Endian.little) != 0 ||
        data.getUint16(eocd + 6, Endian.little) != 0) {
      throw const FormatException('Invalid ZIP');
    }
    final count = data.getUint16(eocd + 10, Endian.little);
    final length = data.getUint32(eocd + 12, Endian.little);
    final offset = data.getUint32(eocd + 16, Endian.little);
    if (count == 0 ||
        count > _fileLimit ||
        data.getUint16(eocd + 8, Endian.little) != count ||
        offset + length != eocd) {
      throw const FormatException('Invalid ZIP directory');
    }
    var position = offset;
    var seen = 0;
    while (position < eocd) {
      if (++seen > _fileLimit ||
          position + 46 > eocd ||
          data.getUint32(position, Endian.little) != 0x02014b50) {
        throw const FormatException('Invalid ZIP header');
      }
      position +=
          46 +
          data.getUint16(position + 28, Endian.little) +
          data.getUint16(position + 30, Endian.little) +
          data.getUint16(position + 32, Endian.little);
    }
    if (position != eocd || seen != count) {
      throw const FormatException('Invalid ZIP entry count');
    }
  }

  static List<String> _directives(String body, String key) =>
      RegExp(
            '^\\{$key:\\s*([^{}\\r\\n]+)\\}\\s*\$',
            caseSensitive: false,
            multiLine: true,
          )
          .allMatches(body)
          .map((m) => boundedText(m[1]))
          .where((s) => s.isNotEmpty)
          .toSet()
          .take(30)
          .toList();

  SongCandidate _candidate(
    String filename,
    _RoswellChart chart,
    _RoswellCatalog catalog,
  ) => SongCandidate(
    providerId: definition.id,
    id: filename,
    title: chart.title,
    artist: chart.artist,
    url: songbooks.toString(),
    metadata: {
      ...chart.metadata,
      'sourceArchiveUrl': catalog.url.toString(),
      'sourceArchiveSha256': catalog.sha256,
      'sourceArchiveFile': filename,
    },
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async {
    final text = queryText(query);
    final catalog = await _catalog(cancel);
    final matches =
        catalog.charts.entries
            .where(
              (entry) => queryMatches(
                text,
                '${entry.value.title} ${entry.value.artist}',
              ),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return matches
        .take(30)
        .map((e) => _candidate(e.key, e.value, catalog))
        .toList();
  }

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    final catalog = await _catalog(cancel);
    final own = candidate.providerId == definition.id;
    // Archive hashes describe retrieval provenance, not immutable selection
    // revisions. A chart may evolve under the same publisher filename. Recheck
    // its title/artist and return the current chart with its current evidence;
    // previously saved source payloads remain the library's history.
    final matches = catalog.charts.entries
        .where(
          (entry) =>
              (!own || entry.key == candidate.id) &&
              normalized(entry.value.title) == normalized(candidate.title) &&
              normalized(entry.value.artist) == normalized(candidate.artist) &&
              (own || entry.value.artist.isNotEmpty),
        )
        .toList();
    if (matches.length != 1) {
      throw ProviderException(
        own && catalog.charts.containsKey(candidate.id)
            ? 'identity_mismatch'
            : 'unavailable',
      );
    }
    final entry = matches.single;
    final found = _candidate(entry.key, entry.value, catalog);
    return SourceResult(
      candidate: found,
      body: entry.value.body,
      metadata: found.metadata,
      attribution: 'Roswell Music Jam — $songbooks',
      retrievedAt: DateTime.now().toUtc(),
      extra: {
        ...sourceEvidence(
          found,
          original: entry.value.raw,
          revision: catalog.sha256,
          evidenceUrl: songbooks.toString(),
          attribution: 'Roswell Music Jam',
          provenanceNote:
              'Publisher provides a free educational ChordPro ZIP and '
              'instructions for use in ChordPro apps. No blanket redistribution '
              'license for the included songs is stated.',
        ),
        'sourceArchiveUrl': catalog.url.toString(),
        'sourceArchiveFile': entry.key,
      },
    );
  }
}

class _RoswellCatalog {
  _RoswellCatalog(this.charts, this.url, this.sha256, this.loadedAt);
  final Map<String, _RoswellChart> charts;
  final Uri url;
  final String sha256;
  final DateTime loadedAt;
}

class _RoswellChart {
  _RoswellChart(this.title, this.artist, this.body, this.raw, this.metadata);
  final String title, artist, body, raw;
  final JsonMap metadata;
}
