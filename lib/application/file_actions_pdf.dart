part of 'file_actions.dart';

// ---------------------------------------------------------------------------
// PDF export
// ---------------------------------------------------------------------------

const _lyricSize = 10.0;
const _chordSize = 8.5;

/// Largest number of lyric lines one export may lay out. Beyond this the work
/// would stall a phone for minutes and exhaust memory.
const maxPdfLines = 60000;

const _regularAsset = 'assets/fonts/NotoSans-Regular.ttf';
const _boldAsset = 'assets/fonts/NotoSans-Bold.ttf';
const _monoAsset = 'assets/fonts/NotoSansMono-Regular.ttf';

/// Scripts the Latin/Cyrillic/Greek Noto Sans fonts cannot draw. Each is a
/// separate regular-weight file; the CJK pair is large, so it is only loaded
/// (and only embedded in the PDF) when the text needs it.
const _scriptFallbackAssets = [
  'assets/fonts/NotoSansArabic-Regular.ttf',
  'assets/fonts/NotoSansHebrew-Regular.ttf',
  'assets/fonts/NotoSansDevanagari-Regular.ttf',
  'assets/fonts/NotoSansThai-Regular.ttf',
];
const _cjkFallbackAssets = [
  'assets/fonts/NotoSansSC-Subset-Regular.ttf',
  'assets/fonts/NotoSansKR-Hangul-Regular.ttf',
];

// CJK symbols and ideographs, kana, Hangul, compatibility and full-width forms.
final _cjkPattern = RegExp(r'[⺀-힯豈-﫿＀-￯]');

final _fontAssetCache = <String, Future<Uint8List>>{};

Future<Uint8List> _fontAsset(String path) {
  return _fontAssetCache.putIfAbsent(path, () async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      _fontAssetCache.remove(path);
      rethrow;
    }
  });
}

/// Font files for one PDF job (plain bytes, so they can cross isolates).
class _PdfFontBytes {
  const _PdfFontBytes(this.regular, this.bold, this.mono, this.fallbacks);
  final Uint8List regular, bold, mono;
  final List<Uint8List> fallbacks;
}

class _PdfFonts {
  _PdfFonts(_PdfFontBytes bytes)
    : regular = pw.Font.ttf(ByteData.sublistView(bytes.regular)),
      bold = pw.Font.ttf(ByteData.sublistView(bytes.bold)),
      mono = pw.Font.ttf(ByteData.sublistView(bytes.mono)),
      _fallbackFonts = [
        for (final data in bytes.fallbacks)
          pw.Font.ttf(ByteData.sublistView(data)),
      ] {
    final regularFace = PdfFontFace.parse(bytes.regular);
    final monoFace = PdfFontFace.parse(bytes.mono);
    final faces = [for (final data in bytes.fallbacks) PdfFontFace.parse(data)];
    sansFaces = [regularFace, monoFace, ...faces];
    monoFaces = [monoFace, regularFace, ...faces];
  }

  final pw.Font regular, bold, mono;
  final List<pw.Font> _fallbackFonts;

  /// Coverage chains in drawing order (primary font first), used both to
  /// measure text and to find characters no bundled font can draw.
  late final List<PdfFontFace> sansFaces, monoFaces;

  /// Fonts the pdf package tries, in order, for a character the style's own
  /// font lacks. Mono comes first because only it has the sharp/flat signs
  /// and the true minus sign that key and capo fields use.
  List<pw.Font> get fallback => [mono, regular, ..._fallbackFonts];

  pw.TextStyle sans({
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) => pw.TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFallback: fallback,
  );

  pw.TextStyle monospace({
    required double fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) => pw.TextStyle(
    font: mono,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontFallback: fallback,
  );
}

/// Replaces characters that no bundled font can draw with U+FFFD and removes
/// invisible format characters, remembering what was replaced so the PDF can
/// say so. The pdf package would otherwise draw an empty box silently.
class _Sanitizer {
  final Set<int> missing = {};

  static bool _ignorable(int rune) =>
      (rune >= 0x200b && rune <= 0x200f) ||
      (rune >= 0x2028 && rune <= 0x202e) ||
      (rune >= 0x2060 && rune <= 0x2064) ||
      (rune >= 0xfe00 && rune <= 0xfe0f) ||
      rune == 0xfeff;

  String clean(String text, List<PdfFontFace> chain) {
    final out = StringBuffer();
    for (final rune in text.runes) {
      if (rune == 0x0a) {
        out.writeCharCode(rune);
      } else if (rune == 0x09) {
        out.write('    ');
      } else if (rune < 0x20 || rune == 0x7f || _ignorable(rune)) {
        continue;
      } else if (chain.any((face) => face.supports(rune))) {
        out.writeCharCode(rune);
      } else {
        missing.add(rune);
        out.writeCharCode(0xfffd);
      }
    }
    return out.toString();
  }

  /// One line for the page, or null when everything could be drawn.
  String? get notice {
    if (missing.isEmpty) return null;
    final sample = (missing.toList()..sort())
        .take(4)
        .map((rune) => 'U+${rune.toRadixString(16).toUpperCase()}')
        .join(', ');
    final more = missing.length > 4 ? ', ...' : '';
    return 'Note: ${missing.length} character(s) in this text are not '
        'available in the PDF fonts and are shown as \u{FFFD} ($sample$more).';
  }
}

double _measure(String text, List<PdfFontFace> chain, double size) {
  var width = 0.0;
  for (final rune in text.runes) {
    for (final face in chain) {
      if (face.supports(rune)) {
        width += face.advance(rune, size);
        break;
      }
    }
  }
  return width;
}

final _letter = RegExp(r'\p{L}', unicode: true);
final _rtlLetter = RegExp(r'[֐-ࣿיִ-﷿ﹰ-﻿]', unicode: true);

/// True when most letters of [text] belong to a right-to-left script.
bool isRightToLeftText(String text) {
  var letters = 0, rtl = 0;
  for (final match in _letter.allMatches(text)) {
    letters++;
    if (_rtlLetter.hasMatch(match.group(0)!)) rtl++;
  }
  return letters > 0 && rtl * 2 > letters;
}

class _ChordPlacement {
  const _ChordPlacement(this.x, this.label);
  final double x;
  final String label;
}

class _LineChunk {
  const _LineChunk(this.text, this.chords, {this.rtl = false});
  final String text;
  final List<_ChordPlacement> chords;
  final bool rtl;
}

/// Splits one chorded lyric line into rows that fit [maxWidth] and positions
/// each chord at the measured width of the lyric before it. Chords (8.5 pt)
/// and lyrics (10 pt) share one monospaced face but not one column pitch, so
/// padding with spaces drifts; absolute positions do not. Offsets in
/// [ArrangementLine.chords] count grapheme clusters, so rows are cut on
/// cluster boundaries and chords keep their anchor.
List<_LineChunk> _layoutChordedLine(
  ArrangementLine line,
  _Sanitizer sanitizer,
  List<PdfFontFace> chain,
  double maxWidth,
) {
  if (isRightToLeftText(line.text)) {
    // Syllable anchoring is not defined for bidirectional text: list the
    // chords above the line instead of placing them over wrong letters.
    final labels = [
      for (final anchor in line.chords) sanitizer.clean(anchor.chord, chain),
    ];
    final texts = _pdfTextChunks(sanitizer.clean(line.text, chain));
    return [
      for (var index = 0; index < texts.length; index++)
        _LineChunk(texts[index], [
          if (index == 0 && labels.isNotEmpty)
            _ChordPlacement(0, labels.join('   ')),
        ], rtl: true),
    ];
  }
  final graphemes = [
    for (final cluster in line.text.characters) sanitizer.clean(cluster, chain),
  ];
  final widths = [
    for (final cluster in graphemes) _measure(cluster, chain, _lyricSize),
  ];
  final limit = maxWidth * 0.995;
  final minGap = _measure(' ', chain, _chordSize);
  final chunks = <_LineChunk>[];
  var start = 0;
  do {
    var width = 0.0, end = start, lastBreak = -1;
    while (end < graphemes.length) {
      if (width + widths[end] > limit && end > start) break;
      width += widths[end];
      end++;
      final cluster = graphemes[end - 1];
      if (cluster.isNotEmpty && cluster.trim().isEmpty) lastBreak = end;
    }
    if (end < graphemes.length && lastBreak > start) end = lastBreak;
    final last = end >= graphemes.length;
    final placements = <_ChordPlacement>[];
    var previousEnd = -minGap;
    for (final anchor in line.chords) {
      final at = anchor.offset;
      if (at < start || (!last && at >= end)) continue;
      final offset = at > end ? end : at;
      var x = 0.0;
      for (var i = start; i < offset; i++) {
        x += widths[i];
      }
      final label = sanitizer.clean(anchor.chord, chain);
      final labelWidth = _measure(label, chain, _chordSize);
      // Keep neighbours apart, and keep the final chord on the page.
      if (x < previousEnd + minGap) x = previousEnd + minGap;
      if (x + labelWidth > limit) {
        final shifted = limit - labelWidth;
        x = shifted > previousEnd + minGap ? shifted : previousEnd + minGap;
      }
      placements.add(_ChordPlacement(x, label));
      previousEnd = x + labelWidth;
    }
    chunks.add(_LineChunk(graphemes.sublist(start, end).join(), placements));
    start = end;
  } while (start < graphemes.length);
  return chunks;
}

/// Row text and chord x positions (points) for [line] as the PDF lays them
/// out, for tests.
@visibleForTesting
List<({String text, List<({double x, String chord})> chords})>
layoutChordedRowsForTest(
  ArrangementLine line,
  List<PdfFontFace> chain,
  double maxWidth,
) => [
  for (final chunk in _layoutChordedLine(line, _Sanitizer(), chain, maxWidth))
    (
      text: chunk.text,
      chords: [for (final c in chunk.chords) (x: c.x, chord: c.label)],
    ),
];

/// Everything a PDF job needs, as plain data that can cross isolates.
class _PdfJob {
  _PdfJob(this.songs, this.format, this.setlist, this.fonts);
  final List<SongDocument> songs;
  final PdfPageFormat format;
  final SetlistDocument? setlist;
  final _PdfFontBytes fonts;
}

/// Only what printing reads, so large timing payloads are not copied between
/// isolates.
SongDocument _printable(SongDocument song) => SongDocument(
  id: song.id,
  title: song.title,
  artist: song.artist,
  body: song.body,
  metadata: song.metadata,
);

bool _hasCjk(SongDocument song) =>
    _cjkPattern.hasMatch(song.title) ||
    _cjkPattern.hasMatch(song.artist) ||
    _cjkPattern.hasMatch(song.body) ||
    song.metadata.values.any((value) => _cjkPattern.hasMatch('$value'));

/// Code points in [texts] that no bundled PDF font can draw (they print as a
/// visible U+FFFD with a note on the page). Lets a caller warn before export.
Future<List<int>> unprintableCharacters(Iterable<String> texts) async {
  final all = texts.toList();
  final needsCjk = all.any(_cjkPattern.hasMatch);
  final chain = [
    PdfFontFace.parse(await _fontAsset(_regularAsset)),
    PdfFontFace.parse(await _fontAsset(_monoAsset)),
    for (final path in [
      ..._scriptFallbackAssets,
      if (needsCjk) ..._cjkFallbackAssets,
    ])
      PdfFontFace.parse(await _fontAsset(path)),
  ];
  final sanitizer = _Sanitizer();
  for (final text in all) {
    sanitizer.clean(text, chain);
  }
  return sanitizer.missing.toList()..sort();
}

Future<Uint8List> createSongPdf(
  List<SongDocument> songs, {
  PdfPageFormat format = PdfPageFormat.a4,
  SetlistDocument? setlist,
}) async {
  final needsCjk =
      songs.any(_hasCjk) ||
      (setlist != null && _cjkPattern.hasMatch(setlist.name));
  final fonts = _PdfFontBytes(
    await _fontAsset(_regularAsset),
    await _fontAsset(_boldAsset),
    await _fontAsset(_monoAsset),
    [
      for (final path in [
        ..._scriptFallbackAssets,
        if (needsCjk) ..._cjkFallbackAssets,
      ])
        await _fontAsset(path),
    ],
  );
  final job = _PdfJob(
    [for (final song in songs) _printable(song)],
    format,
    setlist,
    fonts,
  );
  return _runInBackground(() => _buildSongPdf(job));
}

Future<Uint8List> _buildSongPdf(_PdfJob job) async {
  final songs = job.songs;
  final format = job.format;
  final setlist = job.setlist;
  final fonts = _PdfFonts(job.fonts);
  const navy = PdfColor.fromInt(0xff173454);
  const muted = PdfColor.fromInt(0xff5f6b78);
  const paleBlue = PdfColor.fromInt(0xfff1f5f9);
  String songKeywords(SongDocument song) => [
    song.title,
    if (song.artist.trim().isNotEmpty) song.artist.trim(),
    'lyrics',
    if (song.hasChords) 'chords',
    for (final key in const [
      'album',
      'year',
      'key',
      'capo',
      'tuning',
      'tempo',
      'composer',
      'lyricist',
    ])
      if (song.metadata[key]?.toString().trim().isNotEmpty == true)
        song.metadata[key].toString().trim(),
  ].join(', ');
  final songCredits = songs.length == 1
      ? {
          for (final key in const ['composer', 'lyricist'])
            if (songs.single.metadata[key] is String &&
                (songs.single.metadata[key] as String).trim().isNotEmpty)
              (songs.single.metadata[key] as String).trim(),
        }.join('; ')
      : '';
  final document = pw.Document(
    title: setlist?.name ?? songs.map((song) => song.title).join(', '),
    author: songCredits.isEmpty ? null : songCredits,
    subject: setlist == null
        ? songs.any((song) => song.hasChords)
              ? 'Song lyrics and chords'
              : 'Song lyrics'
        : songs.any((song) => song.hasChords)
        ? 'Setlist with song lyrics and chords'
        : 'Setlist with song lyrics',
    keywords: songs.length == 1
        ? songKeywords(songs.single)
        : 'setlist, lyrics, chords',
    theme: pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      fontFallback: fonts.fallback,
    ),
  );
  if (setlist != null) {
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 1000,
        build: (context) {
          final sanitizer = _Sanitizer();
          String clean(String text) => sanitizer.clean(text, fonts.sansFaces);
          final widgets = <pw.Widget>[
            pw.Text(
              clean(setlist.name),
              style: fonts.sans(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: navy,
              ),
            ),
            for (var i = 0; i < songs.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  clean(
                    '${i + 1}. ${songs[i].title}${songs[i].artist.trim().isEmpty ? '' : ' — ${songs[i].artist.trim()}'}',
                  ),
                  style: fonts.sans(fontSize: 22),
                  overflow: pw.TextOverflow.span,
                ),
              ),
          ];
          final notice = sanitizer.notice;
          if (notice != null) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 6),
                child: pw.Text(
                  notice,
                  style: fonts.sans(fontSize: 8, color: muted),
                ),
              ),
            );
          }
          return widgets;
        },
      ),
    );
  }
  var totalLines = 0;
  for (var songIndex = 0; songIndex < songs.length; songIndex++) {
    final song = songs[songIndex];
    final lines = parseArrangement(song.body);
    totalLines += lines.length;
    if (totalLines > maxPdfLines) {
      throw const FormatException('pdf_too_large');
    }
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 1000,
        build: (context) {
          final sanitizer = _Sanitizer();
          final title = sanitizer.clean(song.title, fonts.sansFaces);
          final body = _pdfSongBody(
            lines,
            context: context,
            format: format,
            metadata: [
              if (song.artist.trim().isNotEmpty)
                'Artist: ${song.artist.trim()}',
              ..._songMetadataLines(song),
            ],
            fonts: fonts,
            sanitizer: sanitizer,
            navy: navy,
            muted: muted,
            paleBlue: paleBlue,
          );
          final notice = sanitizer.notice;
          return [
            pw.Text(
              title,
              style: fonts.sans(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (notice != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  notice,
                  style: fonts.sans(fontSize: 8, color: muted),
                ),
              ),
            ...body,
          ];
        },
      ),
    );
  }
  return document.save();
}

List<pw.Widget> _pdfSongBody(
  List<ArrangementLine> lines, {
  required pw.Context context,
  required PdfPageFormat format,
  required List<String> metadata,
  required _PdfFonts fonts,
  required _Sanitizer sanitizer,
  required PdfColor navy,
  required PdfColor muted,
  required PdfColor paleBlue,
}) {
  final margin = pw.PageTheme(
    pageFormat: format,
  ).margin!.resolve(pw.TextDirection.ltr);
  final contentWidth = format.width - margin.horizontal;
  final columnWidth = contentWidth - 10;
  final lyricWidth = metadata.isEmpty ? contentWidth : columnWidth * .7;
  final metadataWidth = columnWidth * .3;
  final chordStyle = fonts.monospace(
    fontSize: _chordSize,
    fontWeight: pw.FontWeight.bold,
    color: navy,
  );

  pw.Widget lyricRow(_LineChunk chunk) {
    pw.Widget? chordRow;
    if (chunk.chords.isNotEmpty) {
      if (chunk.rtl) {
        chordRow = pw.SizedBox(
          width: lyricWidth,
          child: pw.Text(
            chunk.chords.first.label,
            style: chordStyle,
            textAlign: pw.TextAlign.right,
            softWrap: false,
          ),
        );
      } else {
        var previousEnd = 0.0;
        final cells = <pw.Widget>[];
        for (final chord in chunk.chords) {
          cells
            ..add(pw.SizedBox(width: chord.x - previousEnd))
            ..add(pw.Text(chord.label, style: chordStyle, softWrap: false));
          previousEnd =
              chord.x + _measure(chord.label, fonts.monoFaces, _chordSize);
        }
        chordRow = pw.Row(mainAxisSize: pw.MainAxisSize.min, children: cells);
      }
    }
    final lyric = pw.Text(
      chunk.text.isEmpty ? ' ' : chunk.text,
      style: fonts.monospace(fontSize: _lyricSize),
      textDirection: chunk.rtl ? pw.TextDirection.rtl : null,
      textAlign: chunk.rtl ? pw.TextAlign.right : null,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 0.8),
      child: pw.Inseparable(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ?chordRow,
            chunk.rtl ? pw.SizedBox(width: lyricWidth, child: lyric) : lyric,
          ],
        ),
      ),
    );
  }

  final lyricRows = <pw.Widget>[];
  final pendingHeadings = <pw.Widget>[];
  final pendingSpacing = <pw.Widget>[];
  void appendBodyRows(List<pw.Widget> rows) {
    if (pendingHeadings.isEmpty || rows.isEmpty) {
      lyricRows.addAll(rows);
      return;
    }
    // An inseparable block taller than a page cannot be laid out at all.
    // Only the headings nearest the row stay attached to it; a longer run
    // (notes kept as many comment lines) flows across pages on its own.
    if (pendingHeadings.length > _pdfAttachedHeadings) {
      final detached = pendingHeadings.length - _pdfAttachedHeadings;
      lyricRows.addAll(pendingHeadings.take(detached));
      pendingHeadings.removeRange(0, detached);
    }
    if (pendingSpacing.length > _pdfAttachedSpacing) {
      final detached = pendingSpacing.length - _pdfAttachedSpacing;
      lyricRows.addAll(pendingSpacing.take(detached));
      pendingSpacing.removeRange(0, detached);
    }
    lyricRows.add(
      pw.Inseparable(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [...pendingHeadings, ...pendingSpacing, rows.first],
        ),
      ),
    );
    lyricRows.addAll(rows.skip(1));
    pendingHeadings.clear();
    pendingSpacing.clear();
  }

  for (final line in lines) {
    final heading = line.directive ? _pdfSectionHeading(line.text) : null;
    if (heading != null) {
      // A very long note is cut like any other long row, so no single
      // heading can outgrow the page either.
      for (final text in _pdfTextChunks(
        sanitizer.clean(heading, fonts.sansFaces),
      )) {
        pendingHeadings.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 5, bottom: 2),
            child: pw.Text(
              text,
              style: fonts.sans(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: muted,
              ),
            ),
          ),
        );
      }
      continue;
    } else if (!line.directive &&
        line.text.trim().isEmpty &&
        line.chords.isEmpty) {
      final spacing = pw.SizedBox(height: 5);
      if (pendingHeadings.isEmpty) {
        lyricRows.add(spacing);
      } else {
        pendingSpacing.add(spacing);
      }
    } else if (!line.directive) {
      final chunks = line.chords.isEmpty
          ? [
              for (final text in _pdfTextChunks(
                sanitizer.clean(line.text, fonts.monoFaces),
              ))
                _LineChunk(text, const [], rtl: isRightToLeftText(text)),
            ]
          : _layoutChordedLine(line, sanitizer, fonts.monoFaces, lyricWidth);
      appendBodyRows(chunks.map(lyricRow).toList());
    }
  }
  // Preserve meaningful terminal headings and notes even when no body row
  // follows them; the PDF should match the arrangement the user authored.
  lyricRows
    ..addAll(pendingHeadings)
    ..addAll(pendingSpacing);

  final metadataWidgets = <pw.Widget>[];
  for (final value in metadata) {
    final chunks = _pdfTextChunks(sanitizer.clean(value, fonts.sansFaces));
    for (var index = 0; index < chunks.length; index++) {
      metadataWidgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 0.8),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: paleBlue,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            index == 0 ? chunks[index] : '(continued) ${chunks[index]}',
            style: fonts.sans(fontSize: 8, color: navy),
          ),
        ),
      );
    }
  }

  if (metadataWidgets.isEmpty) return lyricRows;

  // Measure actual font wrapping at the printed width. Keep each block well
  // below a fresh page so MultiPage can paginate it as one unit. The sidebar
  // flows independently; lyrics fill its height instead of leaving a fixed
  // opening gap or imposing their own row heights on metadata fields.
  final maxBlockHeight = (format.height - margin.vertical) * .65;
  double measuredHeight(pw.Widget widget, double width) {
    widget.layout(context, pw.BoxConstraints(minWidth: width, maxWidth: width));
    return widget.box!.height;
  }

  final lyricHeights = [
    for (final row in lyricRows) measuredHeight(row, lyricWidth),
  ];
  final metadataHeights = [
    for (final widget in metadataWidgets) measuredHeight(widget, metadataWidth),
  ];
  var lyricIndex = 0;
  var metadataIndex = 0;
  final blocks = <pw.Widget>[];
  while (metadataIndex < metadataWidgets.length) {
    final metadataStart = metadataIndex;
    var metadataHeight = 0.0;
    do {
      metadataHeight += metadataHeights[metadataIndex++];
    } while (metadataIndex < metadataWidgets.length &&
        metadataHeight + metadataHeights[metadataIndex] <= maxBlockHeight);

    final lyricStart = lyricIndex;
    var lyricHeight = 0.0;
    while (lyricIndex < lyricRows.length &&
        lyricHeight + lyricHeights[lyricIndex] <= maxBlockHeight &&
        (lyricIndex == lyricStart ||
            lyricHeight + lyricHeights[lyricIndex] <= metadataHeight)) {
      lyricHeight += lyricHeights[lyricIndex++];
    }
    blocks.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 7,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: lyricRows.sublist(lyricStart, lyricIndex),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: metadataWidgets.sublist(metadataStart, metadataIndex),
            ),
          ),
        ],
      ),
    );
  }
  blocks.addAll(lyricRows.skip(lyricIndex));
  return blocks;
}

/// Break exceptional single rows into bounded continuations so each piece can
/// stay together and still fit on a page. The limit is a conservative text-size
/// bound, not a page-height estimate; ordinary text remains unchanged. Chunk
/// boundaries prefer whitespace and never split a grapheme cluster when a long
/// unbroken token needs splitting. Chorded lines are cut by measured width
/// instead (see [_layoutChordedLine]).
const _pdfTextChunkLength = 320;

/// Headings and blank rows kept on one page with the row that follows them.
const _pdfAttachedHeadings = 4;
const _pdfAttachedSpacing = 8;

List<String> _pdfTextChunks(String value) {
  if (value.length <= _pdfTextChunkLength) return [value];

  final chunks = <String>[];
  var start = 0;
  while (value.length - start > _pdfTextChunkLength) {
    final limit = start + _pdfTextChunkLength;
    final whitespace = RegExp(r'\s').allMatches(value.substring(start, limit));
    final lastWhitespace = whitespace.isEmpty ? null : whitespace.last;
    var end = lastWhitespace == null ? start : start + lastWhitespace.end;
    if (end <= start) {
      end = start;
      for (final grapheme in value.substring(start).characters) {
        if (end + grapheme.length - start > _pdfTextChunkLength) break;
        end += grapheme.length;
      }
    }
    if (end <= start) {
      end = start + value.substring(start).characters.first.length;
    }
    chunks.add(value.substring(start, end));
    start = end;
  }
  chunks.add(value.substring(start));
  return chunks;
}

String _chordRow(ArrangementLine line) {
  final row = StringBuffer();
  for (final anchor in line.chords) {
    final padding = anchor.offset - row.length;
    if (padding > 0) {
      row.write(' ' * padding);
    } else if (row.isNotEmpty) {
      row.write(' ');
    }
    row.write(anchor.chord);
  }
  return row.toString();
}

/// Directive names that carry free text which the reader shows as a note.
const _commentDirectives = {
  'comment',
  'c',
  'comment italic',
  'ci',
  'comment box',
  'cb',
};

const _sectionLabels = {
  'verse': 'Verse',
  'chorus': 'Chorus',
  'bridge': 'Bridge',
  'pre chorus': 'Pre-Chorus',
  'post chorus': 'Post-Chorus',
  'intro': 'Intro',
  'outro': 'Outro',
  'interlude': 'Interlude',
  'instrumental': 'Instrumental',
  'solo': 'Solo',
  'refrain': 'Refrain',
  'hook': 'Hook',
  'breakdown': 'Breakdown',
  'coda': 'Coda',
  'tag': 'Tag',
  'ending': 'Ending',
  // ChordPro short forms.
  'sov': 'Verse',
  'soc': 'Chorus',
  'sob': 'Bridge',
};

/// Heading or note text for a directive line, or null when it prints nothing.
/// Section directives and every `{comment: ...}` (the reader shows them all)
/// produce text; metadata directives and `{end_of_...}` do not.
String? _pdfSectionHeading(String directive) {
  final match = RegExp(
    r'^\{\s*(?:start_of_)?([a-z_]+)\s*(?::\s*([^}]*))?\}$',
    caseSensitive: false,
  ).firstMatch(directive.trim());
  if (match == null) return null;
  final name = match.group(1)!.replaceAll('_', ' ').toLowerCase();
  final detail = match.group(2)?.trim();
  if (_commentDirectives.contains(name)) {
    return detail == null || detail.isEmpty ? null : detail;
  }
  final label = _sectionLabels[name];
  if (label == null) return null;
  if (detail == null || detail.isEmpty) return label;
  if (detail.toLowerCase().startsWith(label.toLowerCase())) return detail;
  return '$label · $detail';
}
