import 'dart:typed_data';

/// Minimal read-only view of a TrueType font: which code points it can draw and
/// how wide they are. It exists so PDF layout can be measured and unsupported
/// characters detected without a PDF document (the pdf package only reveals
/// glyph coverage once a font has been embedded in a document, and embedding
/// every fallback font would bloat each file).
class PdfFontFace {
  PdfFontFace._(this.unitsPerEm, this._glyphs, this._advances);

  factory PdfFontFace.parse(Uint8List data) {
    final view = ByteData.sublistView(data);
    final tables = <String, int>{};
    final count = view.getUint16(4);
    for (var i = 0; i < count; i++) {
      final record = 12 + i * 16;
      tables[String.fromCharCodes(data.sublist(record, record + 4))] = view
          .getUint32(record + 8);
    }
    final head = tables['head'];
    final hhea = tables['hhea'];
    final hmtx = tables['hmtx'];
    final cmap = tables['cmap'];
    if (head == null || hhea == null || hmtx == null || cmap == null) {
      throw const FormatException('Unsupported font file.');
    }
    final unitsPerEm = view.getUint16(head + 18);
    final metrics = view.getUint16(hhea + 34);
    final advances = Uint16List(metrics);
    for (var i = 0; i < metrics; i++) {
      advances[i] = view.getUint16(hmtx + i * 4);
    }
    final glyphs = <int, int>{};
    final subtables = view.getUint16(cmap + 2);
    for (var i = 0; i < subtables; i++) {
      final record = cmap + 4 + i * 8;
      final platform = view.getUint16(record);
      if (platform != 0 && platform != 3) continue;
      final offset = cmap + view.getUint32(record + 4);
      final format = view.getUint16(offset);
      if (format == 4) {
        _readFormat4(view, offset, glyphs);
      } else if (format == 12) {
        _readFormat12(view, offset, glyphs);
      }
    }
    return PdfFontFace._(unitsPerEm, glyphs, advances);
  }

  static void _readFormat4(ByteData view, int base, Map<int, int> glyphs) {
    final segments = view.getUint16(base + 6) ~/ 2;
    final ends = base + 14;
    final starts = ends + segments * 2 + 2;
    final deltas = starts + segments * 2;
    final ranges = deltas + segments * 2;
    for (var s = 0; s < segments; s++) {
      final end = view.getUint16(ends + s * 2);
      final start = view.getUint16(starts + s * 2);
      final delta = view.getInt16(deltas + s * 2);
      final rangeOffset = view.getUint16(ranges + s * 2);
      for (var code = start; code <= end && code != 0xffff; code++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (code + delta) & 0xffff;
        } else {
          final at = ranges + s * 2 + rangeOffset + (code - start) * 2;
          if (at + 2 > view.lengthInBytes) continue;
          glyph = view.getUint16(at);
          if (glyph != 0) glyph = (glyph + delta) & 0xffff;
        }
        if (glyph != 0) glyphs[code] = glyph;
      }
    }
  }

  static void _readFormat12(ByteData view, int base, Map<int, int> glyphs) {
    final groups = view.getUint32(base + 12);
    for (var g = 0; g < groups; g++) {
      final at = base + 16 + g * 12;
      final start = view.getUint32(at);
      final end = view.getUint32(at + 4);
      final first = view.getUint32(at + 8);
      if (end - start > 0x10000) continue;
      for (var code = start; code <= end; code++) {
        final glyph = first + code - start;
        if (glyph != 0) glyphs[code] = glyph;
      }
    }
  }

  final int unitsPerEm;
  final Map<int, int> _glyphs;
  final Uint16List _advances;

  bool supports(int rune) => _glyphs.containsKey(rune);

  /// Advance width of [rune] at [size] points; 0 when unsupported.
  double advance(int rune, double size) {
    final glyph = _glyphs[rune];
    if (glyph == null || _advances.isEmpty) return 0;
    final units = glyph < _advances.length
        ? _advances[glyph]
        : _advances[_advances.length - 1];
    return units * size / unitsPerEm;
  }
}
