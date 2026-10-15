import 'dart:convert';
import 'dart:math';
import 'package:characters/characters.dart';
import 'package:crypto/crypto.dart';
import 'models.dart';
import 'arrangement.dart';

class ChordProCodec {
  static const chunkSize = 4096;
  static const maxEncoded = 16 * 1024 * 1024;
  static const maxDecoded = 12 * 1024 * 1024;
  static const maxDocument = 24 * 1024 * 1024;
  // Total characters of raw timing text that rawRef resolution may produce.
  static const _maxExpanded = 32 * 1024 * 1024;
  static const _meta = {
    'album': 'album',
    'key': 'key',
    'capo': 'capo',
    'tempo': 'tempo',
    'time': 'timeSignature',
    'duration': 'durationSeconds',
    'year': 'year',
    'tuning': 'tuning',
    'composer': 'composer',
    'lyricist': 'lyricist',
    'copyright': 'copyright',
  };

  String encode(SongDocument song) {
    final headers = <String>[
      '{title: ${_safe(song.title)}}',
      '{artist: ${_safe(song.artist)}}',
    ];
    for (final entry in _meta.entries) {
      final value = song.metadata[entry.value];
      if (value != null) headers.add('{${entry.key}: ${_safe(value)}}');
    }
    if (song.preservedExtensions.any(
      (line) => RegExp(
        r'^\s*\{x_verse(?:_data)?\s*:',
        caseSensitive: false,
      ).hasMatch(line),
    )) {
      // An unsupported/invalid block is opaque and must not be replaced or duplicated.
      headers.addAll(song.preservedExtensions);
    } else {
      final rawAssets = jsonMap(song.extra['rawAssets']);
      final referencedAssets = <String>{};
      dynamic pack(dynamic value) {
        if (value is List) return value.map(pack).toList();
        if (value is Map) {
          final result = <String, dynamic>{};
          for (final entry in value.entries) {
            if (entry.key == 'raw' && entry.value is String) {
              final bytes = utf8.encode(entry.value as String);
              final hash = sha256.convert(bytes).toString();
              rawAssets[hash] = {
                ...jsonMap(rawAssets[hash]),
                'encoding': 'base64',
                'contentType': 'text/plain',
                'bytes': base64.encode(bytes),
              };
              result['rawRef'] = hash;
              referencedAssets.add(hash);
            } else {
              if (entry.key == 'rawRef' && entry.value is String) {
                referencedAssets.add(entry.value as String);
              }
              result[entry.key as String] = pack(entry.value);
            }
          }
          return result;
        }
        return value;
      }

      final allTracks = <String, TimingTrack>{
        for (final source in song.sources)
          for (final track in source.timingTracks) track.id: track,
        for (final track in song.timingTracks) track.id: track,
      };
      final sourceRecords = song.sources.map((source) {
        final json = source.toJson()..remove('timingTracks');
        if (source.timingTracks.isNotEmpty) {
          json['timingTrackIds'] = source.timingTracks
              .map((track) => track.id)
              .toList();
        }
        return json;
      }).toList();
      final data = <String, dynamic>{
        ...song.extra,
        'schema': 'verse-chordpro',
        'schemaVersion': 1,
        'id': song.id,
        'revision': song.revision,
        'lyricOrderHash': lyricOrderHash(song.body),
        'createdAt': song.createdAt.toUtc().toIso8601String(),
        'updatedAt': song.updatedAt.toUtc().toIso8601String(),
        if (song.favorite) 'favorite': true,
        if (song.metadata.isNotEmpty)
          'metadata': {...song.metadata}
            ..removeWhere((key, _) => _meta.values.contains(key)),
        if (song.selectedRecording != null)
          'selectedRecording': song.selectedRecording!.toJson(),
        // A dangling active id would make the whole timing payload invalid
        // on decode, so it is only written while its track exists.
        if (song.activeTimingTrackId != null &&
            allTracks.containsKey(song.activeTimingTrackId))
          'activeTimingTrackId': song.activeTimingTrackId,
        if (sourceRecords.isNotEmpty) 'sources': pack(sourceRecords),
        if (allTracks.isNotEmpty)
          'timingTracks': pack(
            allTracks.values.map((track) => track.toJson()).toList(),
          ),
      };
      // Assets no longer referenced by any current track/source are dropped.
      rawAssets.removeWhere((hash, _) => !referencedAssets.contains(hash));
      if (rawAssets.isNotEmpty) {
        data['rawAssets'] = rawAssets;
      } else {
        data.remove('rawAssets');
      }
      final bytes = utf8.encode(jsonEncode(data));
      if (bytes.length > maxDecoded) {
        throw const FormatException(
          'Song timing exceeds the 12 MiB file limit.',
        );
      }
      final encoded = base64Url.encode(bytes).replaceAll('=', '');
      final count = (encoded.length / chunkSize).ceil();
      if (count > 4096 || encoded.length > maxEncoded) {
        throw const FormatException('Song extension exceeds the file limit.');
      }
      headers.add('{x_verse: 1 json-base64url $count}');
      for (var i = 0; i < count; i++) {
        headers.add(
          '{x_verse_data: ${i + 1}/$count ${encoded.substring(i * chunkSize, min(encoded.length, (i + 1) * chunkSize))}}',
        );
      }
      headers.addAll(song.preservedExtensions);
    }
    final document = '${headers.join('\n')}\n\n${song.body}';
    // decode() refuses larger documents, so never write what cannot be read.
    if (document.length > maxDocument) {
      throw const FormatException('Song file exceeds the 24 MiB limit.');
    }
    return document;
  }

  SongDocument decode(String input) {
    if (input.length > maxDocument) {
      throw const FormatException('Song file exceeds the 24 MiB import limit.');
    }
    final lines = (input.startsWith('\uFEFF') ? input.substring(1) : input)
        .replaceAll('\r\n', '\n')
        .split('\n');
    var title = '', artist = '';
    final metadata = <String, dynamic>{};
    final body = <String>[], extension = <String>[], other = <String>[];
    final directive = RegExp(r'^\s*\{([\w_]+)\s*:\s*(.*?)\}\s*$');
    // Metadata directives are only promoted from the header block (up to the
    // first blank line or the first non-directive line). Directives that appear
    // later, such as a mid-song {key:} modulation, stay in the body verbatim,
    // as do repeated header directives, so nothing is overwritten or dropped.
    var inHeader = true, sawHeaderLine = false;
    final seenMeta = <String>{};
    final anyDirective = RegExp(r'^\s*\{.*\}\s*$');
    for (final line in lines) {
      if (RegExp(
        r'^\s*\{x_verse(?:_data)?\s*:',
        caseSensitive: false,
      ).hasMatch(line)) {
        extension.add(line);
        continue;
      }
      if (inHeader) {
        if (line.trim().isEmpty) {
          if (sawHeaderLine) inHeader = false;
        } else if (anyDirective.hasMatch(line) ||
            line.trimLeft().startsWith('#')) {
          sawHeaderLine = true;
        } else {
          inHeader = false;
        }
      }
      final m = inHeader ? directive.firstMatch(line) : null;
      final key = m?.group(1)?.toLowerCase();
      final value = m?.group(2) ?? '';
      if (key?.startsWith('x_') == true) {
        other.add(line);
        continue;
      }
      final canonical = key == 't' ? 'title' : key;
      if (canonical != null &&
          (canonical == 'title' ||
              canonical == 'artist' ||
              _meta.containsKey(canonical)) &&
          seenMeta.add(canonical)) {
        if (canonical == 'title') {
          title = value;
        } else if (canonical == 'artist') {
          artist = value;
        } else {
          metadata[_meta[canonical]!] = canonical == 'duration'
              ? _duration(value) ?? value
              : {'capo', 'tempo', 'year'}.contains(canonical)
              ? num.tryParse(value) ?? value
              : value;
        }
        continue;
      }
      body.add(line);
    }
    // One delimiter blank line belongs to the file header, not the arrangement.
    if (body.isNotEmpty && body.first.isEmpty) body.removeAt(0);
    final bodyText = body.join('\n');
    JsonMap payload = {};
    String? error;
    try {
      if (extension.isNotEmpty) payload = _decodeExtension(extension);
    } on Object catch (e) {
      error = e is FormatException
          ? e.message.toString()
          : 'Singbook timing data could not be read.';
    }
    var tracks = <TimingTrack>[];
    var sources = <SourceResult>[];
    SongCandidate? selected;
    final stale =
        payload['lyricOrderHash'] != null &&
        payload['lyricOrderHash'] != lyricOrderHash(bodyText);
    // A track whose cues fail validation is kept but marked invalid (cues
    // dropped, raw input retained); an edited body makes usable tracks stale.
    // Source copies receive the same treatment as the song's own list.
    var invalidIds = <String>{};
    TimingTrack adjust(TimingTrack t) {
      if (invalidIds.contains(t.id)) {
        return t.copyWith(
          status: TimingStatus.invalid,
          cues: const [],
          extra: {
            ...t.extra,
            'parseError': 'Timing cues are outside the supported bounds.',
          },
        );
      }
      return stale && t.status == TimingStatus.usable
          ? t.copyWith(status: TimingStatus.stale)
          : t;
    }

    try {
      tracks = (payload['timingTracks'] as List? ?? [])
          .map((t) => TimingTrack.fromJson(jsonMap(t)))
          .toList();
      final tracksById = {for (final track in tracks) track.id: track};
      if (tracksById.length != tracks.length) {
        throw const FormatException('Duplicate timing track IDs.');
      }
      sources = (payload['sources'] as List? ?? []).map((s) {
        final json = jsonMap(s);
        if (json['timingTrackIds'] is List) {
          json['timingTracks'] = (json.remove('timingTrackIds') as List).map((
            id,
          ) {
            final track = tracksById[id];
            if (track == null) {
              throw const FormatException('Source timing track is missing.');
            }
            return track.toJson();
          }).toList();
        }
        return SourceResult.fromJson(json);
      }).toList();
      if (payload['selectedRecording'] != null) {
        selected = SongCandidate.fromJson(
          jsonMap(payload['selectedRecording']),
        );
      }
      invalidIds = _validateTracks(
        {
          ...tracksById,
          for (final source in sources)
            for (final track in source.timingTracks) track.id: track,
        }.values.toList(),
      );
      final active = payload['activeTimingTrackId'];
      if (active != null && !tracks.any((t) => t.id == active)) {
        throw const FormatException('The active timing track is missing.');
      }
      tracks = tracks.map(adjust).toList();
      sources = sources
          .map(
            (s) => s.timingTracks.isEmpty
                ? s
                : s.copyWith(timingTracks: s.timingTracks.map(adjust).toList()),
          )
          .toList();
    } on Object catch (_) {
      // Structural damage: the timing/source data cannot be trusted, but the
      // document-level fields (id, favorite, revision, dates, metadata, extra)
      // stay in `payload` and the opaque x_verse lines are preserved verbatim.
      error = 'Singbook timing has invalid fields or references.';
      tracks = [];
      sources = [];
      selected = null;
    }
    final extra = {...payload}
      ..removeWhere(
        (k, _) => {
          'schema',
          'schemaVersion',
          'id',
          'revision',
          'lyricOrderHash',
          'createdAt',
          'updatedAt',
          'favorite',
          'metadata',
          'selectedRecording',
          'activeTimingTrackId',
          'sources',
          'timingTracks',
        }.contains(k),
      );
    final activeId = payload['activeTimingTrackId'] as String?;
    final activeUsable =
        activeId != null &&
        tracks.any(
          (track) =>
              track.id == activeId && track.status == TimingStatus.usable,
        );
    return SongDocument(
      id: payload['id'] as String? ?? newId(),
      title: title,
      artist: artist,
      body: bodyText,
      metadata: {...jsonMap(payload['metadata']), ...metadata},
      sources: sources,
      timingTracks: tracks,
      favorite: payload['favorite'] as bool? ?? false,
      selectedRecording: selected,
      activeTimingTrackId: stale || !activeUsable ? null : activeId,
      revision: payload['revision'] as int? ?? 1,
      createdAt: DateTime.tryParse(payload['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(payload['updatedAt'] as String? ?? ''),
      extra: extra,
      preservedExtensions: [if (error != null) ...extension, ...other],
      extensionError: error,
    );
  }

  JsonMap _decodeExtension(List<String> lines) {
    final heads = lines
        .where(
          (l) => RegExp(r'^\s*\{x_verse\s*:', caseSensitive: false).hasMatch(l),
        )
        .toList();
    if (heads.length != 1) {
      throw const FormatException('Expected one Singbook extension header.');
    }
    if (lines.first != heads.single) {
      throw const FormatException(
        'Singbook extension header must precede its data.',
      );
    }
    final header = RegExp(
      r'^\s*\{x_verse:\s*1 json-base64url (\d+)\}\s*$',
      caseSensitive: false,
    ).firstMatch(heads.single);
    if (header == null) {
      throw const FormatException(
        'This Singbook extension version or encoding is not supported.',
      );
    }
    final count = int.parse(header.group(1)!);
    if (count < 1 || count > 4096 || lines.length != count + 1) {
      throw const FormatException(
        'Singbook timing chunks are missing or excessive.',
      );
    }
    final chunks = <String>[];
    for (final line in lines.where((l) => l != heads.single)) {
      final m = RegExp(
        r'^\s*\{x_verse_data:\s*(\d+)/(\d+) ([A-Za-z0-9_-]{1,4096})\}\s*$',
        caseSensitive: false,
      ).firstMatch(line);
      if (m == null ||
          int.parse(m.group(1)!) != chunks.length + 1 ||
          int.parse(m.group(2)!) != count) {
        throw const FormatException(
          'Singbook timing chunk indices are invalid.',
        );
      }
      chunks.add(m.group(3)!);
    }
    final encoded = chunks.join();
    if (encoded.length > maxEncoded) {
      throw const FormatException('Singbook extension exceeds 16 MiB.');
    }
    final bytes = base64Url.decode(base64Url.normalize(encoded));
    if (bytes.length > maxDecoded) {
      throw const FormatException('Singbook data exceeds 12 MiB.');
    }
    final raw = jsonDecode(utf8.decode(bytes));
    if (raw is! Map || raw['schemaVersion'] != 1) {
      throw const FormatException('Invalid Singbook schema.');
    }
    final data = jsonMap(raw);
    if (data['schema'] != null && data['schema'] != 'verse-chordpro') {
      throw const FormatException('Unknown song extension schema.');
    }
    if (data['id'] is! String ||
        data['revision'] is! int ||
        (data['revision'] as int) < 1 ||
        data['favorite'] != null && data['favorite'] is! bool ||
        data['createdAt'] != null && data['createdAt'] is! String ||
        data['updatedAt'] != null && data['updatedAt'] is! String ||
        data['activeTimingTrackId'] != null &&
            data['activeTimingTrackId'] is! String ||
        data['metadata'] != null && data['metadata'] is! Map) {
      throw const FormatException('Invalid Singbook document fields.');
    }
    final assets = jsonMap(data['rawAssets']);
    // Each asset is decoded and hashed once however often it is referenced,
    // and the total text produced is capped, so a crafted file with many
    // references cannot expand a small payload into gigabytes.
    final decodedAssets = <String, String>{};
    var expanded = 0;
    dynamic unpack(dynamic value, int depth) {
      if (depth > 64) {
        throw const FormatException('Singbook data is nested too deeply.');
      }
      if (value is List) return value.map((v) => unpack(v, depth + 1)).toList();
      if (value is Map) {
        final result = value.map(
          (k, v) => MapEntry(k as String, unpack(v, depth + 1)),
        );
        if (result.containsKey('rawRef')) {
          final ref = result['rawRef'];
          final asset = jsonMap(assets[ref]);
          if (asset['encoding'] != 'base64' || asset['bytes'] is! String) {
            throw const FormatException('Missing source timing payload.');
          }
          var text = decodedAssets[ref];
          if (text == null) {
            final original = base64.decode(asset['bytes'] as String);
            if (sha256.convert(original).toString() != ref) {
              throw const FormatException(
                'Source timing payload hash mismatch.',
              );
            }
            text = decodedAssets[ref as String] = utf8.decode(original);
          }
          expanded += text.length;
          if (expanded > _maxExpanded) {
            throw const FormatException('Singbook data expands too far.');
          }
          result['raw'] = text;
          result.remove('rawRef');
        }
        return result;
      }
      return value;
    }

    return jsonMap(unpack(data, 0));
  }

  /// Throws on structural problems (too many cues overall). Returns the ids of
  /// tracks whose cues are individually invalid so the caller can mark just
  /// those tracks invalid instead of discarding the whole song's metadata.
  Set<String> _validateTracks(List<TimingTrack> tracks) {
    if (tracks.fold<int>(0, (n, t) => n + t.cues.length) > 100000) {
      throw const FormatException('Too many timing cues.');
    }
    final invalid = <String>{};
    for (final track in tracks) {
      try {
        _validateTrack(track);
      } on FormatException {
        invalid.add(track.id);
      }
    }
    return invalid;
  }

  void _validateTrack(TimingTrack track) {
    {
      final ids = <String>{};
      final lines = track.sourceLyrics.split('\n');
      final lengths = <int, int>{};
      var previousStart = -1;
      for (final cue in track.cues) {
        if (!ids.add(cue.id) ||
            cue.startUs < 0 ||
            cue.startUs > 604800000000 ||
            cue.endUs != null &&
                (cue.endUs! < cue.startUs || cue.endUs! > 604800000000) ||
            cue.graphemeStart != null &&
                (cue.graphemeStart! < 0 ||
                    cue.graphemeEnd == null ||
                    cue.graphemeEnd! < cue.graphemeStart!)) {
          throw const FormatException('Invalid timing cue bounds.');
        }
        if (cue.startUs < previousStart) {
          throw const FormatException(
            'Timing cues must be ordered by start time.',
          );
        }
        previousStart = cue.startUs;
        final occurrence = RegExp(r'^line-(\d+)$').firstMatch(cue.occurrenceId);
        if (occurrence != null) {
          final index = int.parse(occurrence[1]!);
          if (index >= lines.length ||
              cue.graphemeEnd != null &&
                  cue.graphemeEnd! >
                      (lengths[index] ??= lines[index].characters.length)) {
            throw const FormatException(
              'Timing span exceeds its source lyric occurrence.',
            );
          }
        }
      }
    }
  }

  String _safe(Object value) =>
      value.toString().replaceAll(RegExp(r'[\r\n{}]'), ' ');
  double? _duration(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      return (double.tryParse(parts[0]) ?? 0) * 60 +
          (double.tryParse(parts[1]) ?? 0);
    }
    return double.tryParse(value);
  }
}
