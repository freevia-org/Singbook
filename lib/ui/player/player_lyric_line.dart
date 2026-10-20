import 'package:flutter/material.dart';

import '../verse_ui_state.dart';
import '../widgets/chord_lyrics_line.dart';

/// Shared paint and typography for the reader and its live settings preview.
/// Highlighting never changes line metrics or the chord anchor positions.
class PlayerLyricLine extends StatelessWidget {
  const PlayerLyricLine({
    super.key,
    required this.line,
    required this.state,
    required this.current,
    this.fontSize,
  });

  final LyricLineData line;
  final VerseUiState state;
  final bool current;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        current &&
        (state.lyricHighlightStyle == 'background' ||
            state.lyricHighlightStyle == 'backgroundUnderline');
    final underline =
        current &&
        (state.lyricHighlightStyle == 'underline' ||
            state.lyricHighlightStyle == 'backgroundUnderline');
    final contrast = current && state.lyricHighlightStyle == 'contrast';
    return Semantics(
      selected: current,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background
              ? theme.colorScheme.primaryContainer.withValues(alpha: .48)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ChordLyricsLine(
          text: line.text,
          chords: line.chords,
          showChords: state.showChords,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: fontSize ?? state.lyricsFontSize,
            height: 1.35,
            color: contrast ? theme.colorScheme.tertiary : null,
            decoration: underline ? TextDecoration.underline : null,
            decorationColor: underline ? theme.colorScheme.tertiary : null,
            decorationThickness: underline ? 2.5 : null,
          ),
          chordStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
