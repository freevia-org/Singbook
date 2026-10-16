import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../verse_ui_state.dart';

/// Paints chord labels above their exact grapheme anchors without placing the
/// labels in the lyric text's horizontal layout flow.
class ChordLyricsLine extends StatefulWidget {
  const ChordLyricsLine({
    super.key,
    required this.text,
    required this.chords,
    required this.showChords,
    required this.style,
    required this.chordStyle,
    this.textAlign,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.locale,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
  });

  final String text;
  final List<LyricChord> chords;
  final bool showChords;
  final TextStyle? style;
  final TextStyle? chordStyle;
  final TextAlign? textAlign;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Locale? locale;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;

  @override
  State<ChordLyricsLine> createState() => _ChordLyricsLineState();
}

class _ChordLyricsLineState extends State<ChordLyricsLine> {
  _ChordLineLayout? _layout;

  @override
  void dispose() {
    _layout?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    final lyricStyle = defaults.style.merge(widget.style);
    final chordStyle = defaults.style.merge(widget.chordStyle);
    final direction = Directionality.of(context);
    final textScaler = widget.textScaler ?? MediaQuery.textScalerOf(context);
    final locale = widget.locale ?? Localizations.maybeLocaleOf(context);
    final align = widget.textAlign ?? defaults.textAlign ?? TextAlign.start;
    final widthBasis = widget.textWidthBasis ?? defaults.textWidthBasis;
    final heightBehavior =
        widget.textHeightBehavior ?? defaults.textHeightBehavior;

    if (!widget.showChords || widget.chords.isEmpty) {
      _replaceLayout(null);
      return _plainText(
        lyricStyle,
        direction,
        textScaler,
        locale,
        align,
        widthBasis,
        heightBehavior,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final nextLayout = _ChordLineLayout.create(
          text: widget.text,
          chords: widget.chords,
          lyricStyle: lyricStyle,
          chordStyle: chordStyle,
          direction: direction,
          textScaler: textScaler,
          locale: locale,
          textAlign: align,
          textWidthBasis: widthBasis,
          textHeightBehavior: heightBehavior,
          maxLines: widget.maxLines,
          constraints: constraints,
        );
        _replaceLayout(nextLayout);
        return Semantics(
          label: _semanticsLabel(),
          textDirection: direction,
          child: ExcludeSemantics(
            child: CustomPaint(
              size: nextLayout.size,
              painter: _ChordLyricsPainter(nextLayout),
              child: SizedBox(
                width: nextLayout.size.width,
                height: nextLayout.size.height,
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: Text(
                      widget.text,
                      style: lyricStyle,
                      textAlign: align,
                      textDirection: direction,
                      textWidthBasis: widthBasis,
                      textHeightBehavior: heightBehavior,
                      locale: locale,
                      textScaler: textScaler,
                      maxLines: widget.maxLines,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _semanticsLabel() {
    final override = widget.semanticsLabel;
    if (override != null) return override;
    if (widget.text.trim().isEmpty) {
      return widget.chords.map((chord) => chord.symbol).join(', ');
    }
    if (!widget.showChords || widget.chords.isEmpty) return widget.text;

    final graphemes = widget.text.characters.toList();
    final ordered = widget.chords.indexed.toList()
      ..sort((a, b) {
        final byOffset = a.$2.graphemeOffset.compareTo(b.$2.graphemeOffset);
        return byOffset != 0 ? byOffset : a.$1.compareTo(b.$1);
      });
    final parts = <String>[];
    var cursor = 0;
    for (final (_, chord) in ordered) {
      final anchor = chord.graphemeOffset.clamp(cursor, graphemes.length);
      var offset = anchor;
      if (offset < graphemes.length && graphemes[offset].trim().isEmpty) {
        while (offset < graphemes.length && graphemes[offset].trim().isEmpty) {
          offset++;
        }
      } else {
        while (offset > 0 && graphemes[offset - 1].trim().isNotEmpty) {
          offset--;
        }
      }
      offset = offset.clamp(cursor, graphemes.length);
      final wordsBefore = graphemes
          .skip(cursor)
          .take(offset - cursor)
          .join()
          .trim();
      if (wordsBefore.isNotEmpty) parts.add(wordsBefore);
      if (chord.symbol.trim().isNotEmpty) parts.add(chord.symbol);
      cursor = offset;
    }
    final remainingWords = graphemes.skip(cursor).join().trim();
    if (remainingWords.isNotEmpty) parts.add(remainingWords);
    return parts.join(' ');
  }

  Widget _plainText(
    TextStyle style,
    TextDirection direction,
    TextScaler textScaler,
    Locale? locale,
    TextAlign align,
    TextWidthBasis widthBasis,
    TextHeightBehavior? heightBehavior,
  ) {
    if (widget.text.isEmpty) {
      // Keep a chord-only arrangement row's ordinary lyric-line spacing when
      // chord display is disabled.
      final metrics = TextPainter(
        text: TextSpan(text: ' ', style: style),
        textDirection: direction,
        textScaler: textScaler,
        locale: locale,
        textAlign: align,
        textWidthBasis: widthBasis,
        textHeightBehavior: heightBehavior,
        maxLines: widget.maxLines,
      )..layout();
      final height = metrics.height;
      metrics.dispose();
      return Semantics(
        label: widget.semanticsLabel ?? widget.text,
        textDirection: direction,
        child: SizedBox(height: height),
      );
    }
    return Text(
      widget.text,
      style: style,
      textAlign: align,
      textDirection: direction,
      textWidthBasis: widthBasis,
      textHeightBehavior: heightBehavior,
      locale: locale,
      textScaler: textScaler,
      maxLines: widget.maxLines,
      semanticsLabel: widget.semanticsLabel,
    );
  }

  void _replaceLayout(_ChordLineLayout? next) {
    final old = _layout;
    _layout = next;
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }
}

class _ChordLineLayout {
  _ChordLineLayout({
    required this.textPainter,
    required this.lines,
    required this.chordsByLine,
    required this.chordRowHeights,
    required this.size,
  });

  final TextPainter textPainter;
  final List<ui.LineMetrics> lines;
  final List<List<_ChordPaintData>> chordsByLine;
  final List<List<double>> chordRowHeights;
  final Size size;

  static _ChordLineLayout create({
    required String text,
    required List<LyricChord> chords,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required TextDirection direction,
    required TextScaler textScaler,
    required Locale? locale,
    required TextAlign textAlign,
    required TextWidthBasis textWidthBasis,
    required TextHeightBehavior? textHeightBehavior,
    required int? maxLines,
    required BoxConstraints constraints,
  }) {
    final lyrics = TextPainter(
      text: TextSpan(text: text, style: lyricStyle),
      textDirection: direction,
      textScaler: textScaler,
      locale: locale,
      textAlign: textAlign,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      maxLines: maxLines,
    );
    lyrics.layout(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
    );

    final lyricMetrics = lyrics.computeLineMetrics();
    TextPainter? emptyLineMetrics;
    var lines = lyricMetrics;
    if ((text.trim().isEmpty || lines.isEmpty) && chords.isNotEmpty) {
      // A chord-only row has one lyric-line spacer regardless of how many
      // whitespace wraps its invisible payload would otherwise produce.
      emptyLineMetrics = TextPainter(
        text: TextSpan(text: ' ', style: lyricStyle),
        textDirection: direction,
        textScaler: textScaler,
        locale: locale,
        textAlign: textAlign,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        maxLines: maxLines,
      )..layout(maxWidth: constraints.maxWidth);
      lines = emptyLineMetrics.computeLineMetrics();
    }

    final codeUnitOffsets = <int>[0];
    for (final grapheme in text.characters) {
      codeUnitOffsets.add(codeUnitOffsets.last + grapheme.length);
    }
    final grouped = List.generate(lines.length, (_) => <_ChordPaintData>[]);
    final ordered = chords.indexed.toList()
      ..sort((a, b) {
        final byOffset = a.$2.graphemeOffset.compareTo(b.$2.graphemeOffset);
        return byOffset != 0 ? byOffset : a.$1.compareTo(b.$1);
      });
    final width = text.trim().isEmpty && constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : constraints.constrainWidth(lyrics.width);
    final chordOnlyRow = text.trim().isEmpty;
    final chordOnlyPacking = chordOnlyRow
        ? _packChordOnly(
            ordered: ordered,
            lyrics: lyrics,
            codeUnitOffsets: codeUnitOffsets,
            direction: direction,
            textScaler: textScaler,
            locale: locale,
            chordStyle: chordStyle,
            width: width,
          )
        : null;
    if (chordOnlyPacking != null) {
      grouped[0].addAll(chordOnlyPacking.items);
    } else {
      for (final (_, chord) in ordered) {
        final graphemeOffset = chord.graphemeOffset.clamp(
          0,
          codeUnitOffsets.length - 1,
        );
        final anchor = _anchorGeometry(
          lyrics,
          codeUnitOffsets,
          graphemeOffset,
          direction,
        );
        final lineIndex = _lineForTop(lines, anchor.caret.dy);
        final label = TextPainter(
          text: TextSpan(text: chord.symbol, style: chordStyle),
          textDirection: direction,
          textScaler: textScaler,
          locale: locale,
          textAlign: TextAlign.start,
          textWidthBasis: TextWidthBasis.longestLine,
        )..layout();
        final labelWidth = label.width;
        var x = anchor.direction == TextDirection.rtl
            ? anchor.caret.dx - labelWidth
            : anchor.caret.dx;
        if (x + labelWidth > width && x >= 0) x = anchor.caret.dx - labelWidth;
        if (x < 0 && x + labelWidth <= width) x = anchor.caret.dx;
        x = x.clamp(0.0, math.max(0.0, width - labelWidth));
        grouped[lineIndex].add(
          _ChordPaintData(graphemeOffset: graphemeOffset, label: label, x: x),
        );
      }
    }

    var extraHeight = 0.0;
    final rowHeights = <List<double>>[];
    if (chordOnlyPacking != null) {
      rowHeights.add(chordOnlyPacking.slotHeights);
      extraHeight += chordOnlyPacking.slotHeights.fold<double>(
        0,
        (sum, value) => sum + value,
      );
    } else {
      for (var lineIndex = 0; lineIndex < grouped.length; lineIndex++) {
        final orderedChords = [...grouped[lineIndex]]
          ..sort((a, b) => a.x.compareTo(b.x));
        final slots = <List<_ChordPaintData>>[];
        final assigned = <_ChordPaintData>[];
        for (final chord in orderedChords) {
          var slotIndex = slots.indexWhere(
            (slot) =>
                slot.every((other) => !_overlapsHorizontally(chord, other)),
          );
          if (slotIndex < 0) {
            slotIndex = slots.length;
            slots.add(<_ChordPaintData>[]);
          }
          final placed = chord.copyWith(slot: slotIndex);
          slots[slotIndex].add(placed);
          assigned.add(placed);
        }
        assigned.sort((a, b) => a.graphemeOffset.compareTo(b.graphemeOffset));
        grouped[lineIndex] = assigned;
        final heights = List<double>.filled(slots.length, 0);
        for (final slot in slots) {
          for (final chord in slot) {
            heights[chord.slot] = math.max(
              heights[chord.slot],
              chord.label.height + _chordGap,
            );
          }
        }
        rowHeights.add(heights);
        extraHeight += heights.fold<double>(0, (sum, value) => sum + value);
      }
    }
    final lyricHeight = chordOnlyRow
        ? (emptyLineMetrics?.height ?? 0)
        : lyrics.height > 0
        ? lyrics.height
        : (emptyLineMetrics?.height ?? 0);
    final layout = _ChordLineLayout(
      textPainter: lyrics,
      lines: lines,
      chordsByLine: grouped,
      chordRowHeights: rowHeights,
      size: Size(width, lyricHeight + extraHeight),
    );
    emptyLineMetrics?.dispose();
    return layout;
  }

  static _ChordOnlyPacking _packChordOnly({
    required List<(int, LyricChord)> ordered,
    required TextPainter lyrics,
    required List<int> codeUnitOffsets,
    required TextDirection direction,
    required TextScaler textScaler,
    required Locale? locale,
    required TextStyle chordStyle,
    required double width,
  }) {
    final spacing = TextPainter(
      text: TextSpan(text: '  ', style: chordStyle),
      textDirection: direction,
      textScaler: textScaler,
      locale: locale,
      textAlign: TextAlign.start,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout();
    final minimumGap = math.max(_chordGap, spacing.width);
    spacing.dispose();

    final rows = <List<_ChordPaintData>>[<_ChordPaintData>[]];
    var rowIndex = 0;
    double? previousStart;
    double? previousEnd;

    for (final (_, chord) in ordered) {
      final graphemeOffset = chord.graphemeOffset.clamp(
        0,
        codeUnitOffsets.length - 1,
      );
      final anchor = lyrics.plainText.isEmpty
          ? _ChordAnchorGeometry(
              Offset(direction == TextDirection.rtl ? width : 0, 0),
              direction,
            )
          : _anchorGeometry(lyrics, codeUnitOffsets, graphemeOffset, direction);
      final label = _chordOnlyLabel(
        chord.symbol,
        chordStyle,
        direction,
        textScaler,
        locale,
        width,
      );
      final labelWidth = label.width.clamp(0.0, width).toDouble();
      final requestedStart = anchor.direction == TextDirection.rtl
          ? anchor.caret.dx - labelWidth
          : anchor.caret.dx;
      var start = previousStart == null
          ? requestedStart
          : direction == TextDirection.rtl
          ? math.min(requestedStart, previousStart - minimumGap - labelWidth)
          : math.max(requestedStart, previousEnd! + minimumGap);

      if (start < 0 || start + labelWidth > width) {
        rows.add(<_ChordPaintData>[]);
        rowIndex++;
        previousStart = null;
        previousEnd = null;
        start = direction == TextDirection.rtl ? width - labelWidth : 0;
      }
      start = start.clamp(0.0, math.max(0.0, width - labelWidth));
      rows[rowIndex].add(
        _ChordPaintData(
          graphemeOffset: graphemeOffset,
          label: label,
          x: start,
          slot: 0,
        ),
      );
      previousStart = start;
      previousEnd = start + labelWidth;
    }

    final visualRowHeights = [
      for (final row in rows)
        row.fold<double>(
          0,
          (height, item) => math.max(height, item.label.height + _chordGap),
        ),
    ];
    final slotHeights = visualRowHeights.reversed.toList();
    final items = <_ChordPaintData>[
      for (var index = 0; index < rows.length; index++)
        for (final item in rows[index])
          item.copyWith(slot: rows.length - 1 - index),
    ];
    return _ChordOnlyPacking(items: items, slotHeights: slotHeights);
  }

  static TextPainter _chordOnlyLabel(
    String symbol,
    TextStyle style,
    TextDirection direction,
    TextScaler textScaler,
    Locale? locale,
    double maxWidth,
  ) {
    TextPainter painterFor(TextScaler scaler) => TextPainter(
      text: TextSpan(text: symbol, style: style),
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
      textAlign: TextAlign.start,
      textWidthBasis: TextWidthBasis.longestLine,
    );

    final natural = painterFor(textScaler)..layout();
    if (natural.width <= maxWidth) return natural;
    final fontSize = style.fontSize ?? 14;
    final fittedScale =
        textScaler.scale(fontSize) / fontSize * maxWidth / natural.width;
    natural.dispose();
    // Keep each chord symbol intact. Only an individually oversized symbol
    // is fitted; the progression itself wraps between complete labels.
    return painterFor(TextScaler.linear(fittedScale))..layout();
  }

  static int _lineForTop(List<ui.LineMetrics> lines, double top) {
    if (lines.length < 2) return 0;
    var nearest = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < lines.length; index++) {
      final lineTop = lines[index].baseline - lines[index].ascent;
      final distance = (lineTop - top).abs();
      if (distance < nearestDistance) {
        nearest = index;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  static _ChordAnchorGeometry _anchorGeometry(
    TextPainter painter,
    List<int> codeUnitOffsets,
    int graphemeOffset,
    TextDirection fallback,
  ) {
    final offset = codeUnitOffsets[graphemeOffset];
    if (painter.plainText.isEmpty) {
      return _ChordAnchorGeometry(Offset.zero, fallback);
    }
    final graphemeCount = codeUnitOffsets.length - 1;
    final isEnd = graphemeOffset == graphemeCount;
    final start = isEnd ? codeUnitOffsets[graphemeOffset - 1] : offset;
    final end = isEnd ? offset : codeUnitOffsets[graphemeOffset + 1];
    if (end <= start) {
      final caret = painter.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );
      return _ChordAnchorGeometry(caret, fallback);
    }
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
      boxHeightStyle: ui.BoxHeightStyle.strut,
    );
    final caret = painter.getOffsetForCaret(
      TextPosition(
        offset: offset,
        affinity: isEnd ? TextAffinity.upstream : TextAffinity.downstream,
      ),
      Rect.zero,
    );
    if (boxes.isEmpty) return _ChordAnchorGeometry(caret, fallback);
    final box = boxes.first;
    final direction = box.direction;
    final dx = isEnd
        ? (direction == TextDirection.ltr ? box.right : box.left)
        : (direction == TextDirection.ltr ? box.left : box.right);
    return _ChordAnchorGeometry(Offset(dx, box.top), direction);
  }

  static bool _overlapsHorizontally(
    _ChordPaintData first,
    _ChordPaintData second,
  ) =>
      first.x < second.x + second.label.width + _chordGap &&
      second.x < first.x + first.label.width + _chordGap;

  void dispose() {
    textPainter.dispose();
    for (final line in chordsByLine) {
      for (final chord in line) {
        chord.label.dispose();
      }
    }
  }
}

class _ChordOnlyPacking {
  const _ChordOnlyPacking({required this.items, required this.slotHeights});

  final List<_ChordPaintData> items;
  final List<double> slotHeights;
}

class _ChordAnchorGeometry {
  const _ChordAnchorGeometry(this.caret, this.direction);

  final Offset caret;
  final TextDirection direction;
}

const double _chordGap = 2;

class _ChordPaintData {
  const _ChordPaintData({
    required this.graphemeOffset,
    required this.label,
    required this.x,
    this.slot = 0,
  });

  _ChordPaintData copyWith({required int slot}) => _ChordPaintData(
    graphemeOffset: graphemeOffset,
    label: label,
    x: x,
    slot: slot,
  );

  final int graphemeOffset;
  final TextPainter label;
  final double x;
  final int slot;
}

class _ChordLyricsPainter extends CustomPainter {
  const _ChordLyricsPainter(this.layout);

  final _ChordLineLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    var shiftBeforeLine = 0.0;
    for (var lineIndex = 0; lineIndex < layout.lines.length; lineIndex++) {
      final line = layout.lines[lineIndex];
      final chords = layout.chordsByLine[lineIndex];
      final rowHeights = layout.chordRowHeights[lineIndex];
      final laneHeight = rowHeights.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      final lineTop = line.baseline - line.ascent;
      final shiftForText = shiftBeforeLine + laneHeight;

      if (chords.isNotEmpty) {
        _paintChords(canvas, chords, lineTop + shiftBeforeLine, rowHeights);
      }

      if (layout.textPainter.plainText.isNotEmpty) {
        canvas.save();
        canvas.translate(0, shiftForText);
        canvas.clipRect(
          Rect.fromLTRB(
            0,
            line.baseline - line.ascent,
            size.width,
            line.baseline + line.descent,
          ),
        );
        layout.textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
      shiftBeforeLine = shiftForText;
    }
  }

  void _paintChords(
    Canvas canvas,
    List<_ChordPaintData> chords,
    double lineTop,
    List<double> rowHeights,
  ) {
    for (final item in chords) {
      final rowsAbove = rowHeights
          .skip(item.slot + 1)
          .fold<double>(0, (sum, value) => sum + value);
      final y =
          lineTop +
          rowsAbove +
          rowHeights[item.slot] -
          item.label.height -
          _chordGap;
      item.label.paint(canvas, Offset(item.x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _ChordLyricsPainter oldDelegate) =>
      oldDelegate.layout != layout;
}
