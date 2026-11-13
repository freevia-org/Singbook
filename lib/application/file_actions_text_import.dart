part of 'file_actions.dart';

/// True only for the full local-file-header signature `PK\x03\x04`; a text file
/// whose title merely starts with "PK" is not an archive.
bool looksLikeZip(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

/// Backup suffixes carry archive intent even when the file has a damaged or
/// missing ZIP signature. Callers should reject them as invalid archives
/// instead of passing their bytes to the permissive lyric text decoder.
bool isLibraryPackageFileName(String name) {
  final basename = paths.basename(name).toLowerCase();
  return basename.endsWith('.zip') || basename.endsWith('.lyrics-setlist');
}

// Windows-1251 0x80..0xBF; 0xC0..0xFF map linearly to U+0410..U+044F.
const _cp1251Upper = <int>[
  0x0402, 0x0403, 0x201A, 0x0453, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x20AC, 0x2030, 0x0409, 0x2039, 0x040A, 0x040C, 0x040B, 0x040F,
  0x0452, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x0098, 0x2122, 0x0459, 0x203A, 0x045A, 0x045C, 0x045B, 0x045F,
  0x00A0, 0x040E, 0x045E, 0x0408, 0x00A4, 0x0490, 0x00A6, 0x00A7,
  0x0401, 0x00A9, 0x0404, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x0407,
  0x00B0, 0x00B1, 0x0406, 0x0456, 0x0491, 0x00B5, 0x00B6, 0x00B7,
  0x0451, 0x2116, 0x0454, 0x00BB, 0x0458, 0x0405, 0x0455, 0x0457,
];

String _decodeUtf16(List<int> bytes, {required bool bigEndian}) {
  if (bytes.length.isOdd) throw const FormatException('invalid_encoding');
  final units = <int>[
    for (var i = 0; i < bytes.length; i += 2)
      bigEndian
          ? (bytes[i] << 8) | bytes[i + 1]
          : bytes[i] | (bytes[i + 1] << 8),
  ];
  return String.fromCharCodes(units);
}

// Windows-1252 0x80..0x9F; the five undefined slots keep their C1 code point.
const _cp1252Upper = <int>[
  0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
  0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
];

class _DecodedText {
  const _DecodedText(this.text, this.encoding);
  final String text;

  /// Lower-case name of the detected encoding ("utf-8", "utf-16le", ...).
  final String encoding;
}

_DecodedText _decodeImported(List<int> bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
    return _DecodedText(
      _decodeUtf16(bytes.sublist(2), bigEndian: false),
      'utf-16le',
    );
  }
  if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
    return _DecodedText(
      _decodeUtf16(bytes.sublist(2), bigEndian: true),
      'utf-16be',
    );
  }
  try {
    return _DecodedText(utf8.decode(bytes), 'utf-8');
  } on FormatException {
    // Not UTF-8: fall through to single-byte encodings.
  }
  // Cyrillic letters are 0xC0..0xFF in Windows-1251, which in Latin-1 would be
  // accented vowels. Cyrillic words are runs of such bytes, whereas accented
  // Latin letters are almost always isolated between ASCII letters, so only
  // bytes in runs of two or more count towards Cyrillic.
  var cyrillic = 0, letters = 0, run = 0, inTag = false;
  for (var i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    // Markup (TTML/XML tag names and attributes) is ASCII whatever the text
    // language is, so it must not dilute the share of Cyrillic letters.
    if (byte == 0x3c) {
      inTag = true;
    } else if (byte == 0x3e) {
      inTag = false;
    }
    if (byte >= 0xc0) {
      letters++;
      run++;
      if (run == 2) {
        cyrillic += 2;
      } else if (run > 2) {
        cyrillic++;
      }
      continue;
    }
    run = 0;
    if (byte >= 0x80 ||
        (!inTag &&
            ((byte >= 0x41 && byte <= 0x5a) ||
                (byte >= 0x61 && byte <= 0x7a)))) {
      letters++;
    }
  }
  if (cyrillic > 0 && cyrillic * 2 >= letters) {
    return _DecodedText(
      String.fromCharCodes([
        for (final byte in bytes)
          if (byte < 0x80)
            byte
          else if (byte < 0xc0)
            _cp1251Upper[byte - 0x80]
          else
            0x0410 + (byte - 0xc0),
      ]),
      'windows-1251',
    );
  }
  return _DecodedText(
    String.fromCharCodes([
      for (final byte in bytes)
        if (byte >= 0x80 && byte < 0xa0) _cp1252Upper[byte - 0x80] else byte,
    ]),
    'windows-1252',
  );
}

/// Decodes imported text without failing on common legacy encodings: UTF-8
/// (with or without BOM), UTF-16 with BOM, then Windows-1251 for Cyrillic
/// (Bulgarian/Ukrainian) text, otherwise Windows-1252 (a superset of Latin-1
/// that also maps curly quotes, dashes and the euro sign).
String decodeImportedText(List<int> bytes) => _decodeImported(bytes).text;

/// Matches a document whose root element is `<set>`, after an optional BOM,
/// XML declaration and comments. Lyrics that merely mention `<set>` elsewhere
/// are not setlists. This is a linear scan on purpose: a regular expression
/// with a repeated comment group backtracks exponentially on a crafted file.
bool looksLikeSetlistXml(String text) {
  var i = 0;
  final n = text.length;
  bool space(int unit) =>
      unit == 0x20 || unit == 0x09 || unit == 0x0a || unit == 0x0d;
  void skipSpace() {
    while (i < n && space(text.codeUnitAt(i))) {
      i++;
    }
  }

  if (i < n && text.codeUnitAt(i) == 0xfeff) i++;
  skipSpace();
  if (text.startsWith('<?xml', i)) {
    final end = text.indexOf('?>', i + 5);
    if (end < 0) return false;
    i = end + 2;
    skipSpace();
  }
  while (text.startsWith('<!--', i)) {
    final end = text.indexOf('-->', i + 4);
    if (end < 0) return false;
    i = end + 3;
    skipSpace();
  }
  if (!text.startsWith('<set', i)) return false;
  i += 4;
  if (i >= n) return false;
  final next = text.codeUnitAt(i);
  return space(next) || next == 0x3e /* > */ || next == 0x2f /* / */;
}

// Line-leading whitespace for the multi-line import patterns. `\s` also
// matches line terminators, so `^\s*` rescans a run of blank lines from every
// line start in it (quadratic). A line that matches after blank lines also
// matches from its own start, so horizontal whitespace finds the same lines.
const _lineLead = r'^[^\S\r\n\u2028\u2029]*';

bool _isLineTerminator(int unit) =>
    unit == 0x0a || unit == 0x0d || unit == 0x2028 || unit == 0x2029;

// Exactly the code units `\s` matches in a non-Unicode Dart RegExp.
bool _isRegExpSpace(int unit) =>
    (unit >= 0x09 && unit <= 0x0d) ||
    unit == 0x20 ||
    unit == 0xa0 ||
    unit == 0x1680 ||
    (unit >= 0x2000 && unit <= 0x200a) ||
    unit == 0x2028 ||
    unit == 0x2029 ||
    unit == 0x202f ||
    unit == 0x205f ||
    unit == 0x3000 ||
    unit == 0xfeff;

/// Splits a multi-song ChordPro text at `{new_song}` lines. Returns what
/// `text.split(RegExp(r'^\s*\{new_song\}\s*$', multiLine: true))` returns
/// (the directive line and the blank lines around it are removed), in linear
/// time: that pattern is quadratic in the length of a run of blank lines.
@visibleForTesting
List<String> splitNewSongSections(String text) {
  const directive = '{new_song}';
  final parts = <String>[];
  var partStart = 0, matchFloor = 0, from = 0;
  while (true) {
    final brace = text.indexOf(directive, from);
    if (brace < 0) break;
    from = brace + directive.length;
    // The match begins at the first line start within the whitespace that
    // precedes the directive, but never inside the previous match.
    var lead = brace;
    while (lead > matchFloor && _isRegExpSpace(text.codeUnitAt(lead - 1))) {
      lead--;
    }
    var start = -1;
    for (var at = lead; at <= brace; at++) {
      if (at == 0 || _isLineTerminator(text.codeUnitAt(at - 1))) {
        start = at;
        break;
      }
    }
    if (start < 0) continue;
    // It ends before the last line terminator of the whitespace that follows,
    // or at the end of the text.
    var tail = from;
    while (tail < text.length && _isRegExpSpace(text.codeUnitAt(tail))) {
      tail++;
    }
    var end = tail == text.length ? tail : -1;
    for (var at = tail - 1; end < 0 && at >= from; at--) {
      if (_isLineTerminator(text.codeUnitAt(at))) end = at;
    }
    if (end < 0) continue;
    parts.add(text.substring(partStart, start));
    partStart = matchFloor = end;
    from = end > from ? end : from;
  }
  parts.add(text.substring(partStart));
  return parts;
}

/// Imports timing without implying that the user's file identifies a recording.
List<SongDocument> decodeSongText(String input, {String? fileName}) {
  final inputBytes = utf8.encode(input);
  if (inputBytes.length > maxImportBytes) {
    throw const FormatException('file_too_large');
  }
  final text = input.replaceFirst('\uFEFF', '');
  if (text.trim().isEmpty) throw const FormatException('empty_file');
  final title = fileName == null
      ? text.split('\n').first.trim()
      : paths.basenameWithoutExtension(fileName);
  if (RegExp(
        _lineLead + r'\[\d+:\d{2}(?:\.\d+)?\]',
        multiLine: true,
      ).hasMatch(text) ||
      RegExp(r'<(?:\w+:)?tt(?:\s|>)').hasMatch(text)) {
    final id = newId();
    final rawTrack = parseTimingBytes(
      inputBytes,
      sourceDocumentId: 'import:$id',
      format: text.trimLeft().startsWith('<') ? 'ttml' : 'lrc',
    );
    final track = bindImportedTiming(rawTrack, rawTrack.sourceLyrics);
    if (track.status == TimingStatus.invalid) {
      throw const FormatException('invalid_timing');
    }
    return [
      _timedImportSong(
        id,
        track,
        tags: text,
        fallbackTitle: title,
        fileName: fileName,
      ),
    ];
  }
  if (text.trimLeft().startsWith('<')) {
    throw const FormatException('unsupported_file');
  }
  final parts = splitNewSongSections(text);
  if (parts.length > 1000) throw const FormatException('too_many_songs');
  return parts.where((part) => part.trim().isNotEmpty).map((part) {
    final song = ChordProCodec().decode(part);
    return song.title.isEmpty
        ? song.copyWith(title: title, revision: song.revision)
        : song;
  }).toList();
}

class PickedDocument {
  const PickedDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;

  /// Strict UTF-8; throws [FormatException] for anything else.
  String get text => utf8.decode(bytes);

  /// Tolerant decoding used by imports (see [decodeImportedText]).
  String get lenientText => decodeImportedText(bytes);
}

List<SongDocument> decodePickedSongs(PickedDocument file) {
  final extension = paths.extension(file.name).toLowerCase();
  if (extension != '.lrc' && extension != '.ttml') {
    return decodeSongText(file.lenientText, fileName: file.name);
  }
  if (file.bytes.length > maxImportBytes) {
    throw const FormatException('file_too_large');
  }
  final id = newId();
  // parseTimingBytes only understands UTF-8 and UTF-16. A Windows-1251 or
  // Windows-1252 file is transcoded for parsing, while the original bytes and
  // their detected encoding stay on the track so provenance is not lost.
  final decoded = _decodeImported(file.bytes);
  final legacy = decoded.encoding.startsWith('windows-');
  var raw = parseTimingBytes(
    legacy ? utf8.encode(decoded.text) : file.bytes,
    sourceDocumentId: 'import:$id',
    format: extension.substring(1),
  );
  if (raw.status == TimingStatus.unsupported) {
    throw const FormatException('invalid_timing');
  }
  if (legacy) {
    raw = raw.copyWith(
      extra: {
        ...raw.extra,
        'rawBytesBase64': base64.encode(file.bytes),
        'rawByteHash': sha256.convert(file.bytes).toString(),
        'rawEncoding': decoded.encoding,
      },
    );
  }
  final track = bindImportedTiming(raw, raw.sourceLyrics);
  if (track.status == TimingStatus.invalid) {
    throw const FormatException('invalid_timing');
  }
  if (track.sourceLyrics.trim().isEmpty) {
    throw const FormatException('empty_file');
  }
  return [
    _timedImportSong(
      id,
      track,
      tags: track.raw ?? '',
      fallbackTitle: paths.basenameWithoutExtension(file.name),
      fileName: file.name,
    ),
  ];
}

/// The song for one imported timing file; LRC tags in [tags] name it.
SongDocument _timedImportSong(
  String id,
  TimingTrack track, {
  required String tags,
  required String fallbackTitle,
  required String? fileName,
}) {
  final metadata = _lrcMetadata(tags);
  final title = metadata.remove('_title')?.toString() ?? fallbackTitle;
  final artist = metadata.remove('_artist')?.toString() ?? '';
  return SongDocument(
    id: id,
    title: title,
    artist: artist,
    body: track.sourceLyrics,
    metadata: metadata,
    timingTracks: [track],
    activeTimingTrackId: track.status == TimingStatus.usable ? track.id : null,
    extra: {'importedFile': fileName},
  );
}

Map<String, Object?> _lrcMetadata(String text) {
  String? tag(String name) {
    for (final match in RegExp(
      _lineLead + r'\[' + name + r':([^\]]*)\]\s*$',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(text)) {
      final value = match.group(1)!.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  final metadata = <String, Object?>{};
  final title = tag('ti');
  final artist = tag('ar');
  final album = tag('al');
  final lyricist = tag('au');
  final length = tag('length');
  if (title != null) metadata['_title'] = title;
  if (artist != null) metadata['_artist'] = artist;
  if (album != null) metadata['album'] = album;
  if (lyricist != null) metadata['lyricist'] = lyricist;
  if (length != null) {
    final duration = _parseLrcLength(length);
    if (duration != null) metadata['durationSeconds'] = duration;
  }
  return metadata;
}

double? _parseLrcLength(String value) {
  final match = RegExp(
    r'^(?:(\d+):)?(\d{1,2}):(\d{2})(?:\.(\d+))?$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  final hours = int.tryParse(match.group(1) ?? '0');
  final minutes = int.tryParse(match.group(2)!);
  final seconds = int.tryParse(match.group(3)!);
  final fraction = match.group(4);
  if (hours == null ||
      minutes == null ||
      seconds == null ||
      minutes > 59 && match.group(1) != null ||
      seconds > 59) {
    return null;
  }
  final fractionalSeconds = fraction == null
      ? 0.0
      : double.tryParse('0.$fraction') ?? 0.0;
  final total = hours * 3600 + minutes * 60 + seconds + fractionalSeconds;
  return total > 0 && total <= 86400 ? total : null;
}
