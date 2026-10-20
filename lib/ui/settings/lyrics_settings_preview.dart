import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../player/player_lyric_line.dart';
import '../verse_ui_state.dart';

/// A compact, static miniature of the player used while changing lyric settings.
class LyricsSettingsPreview extends StatelessWidget {
  const LyricsSettingsPreview({super.key, required this.state, this.fontSize});

  final VerseUiState state;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final minorStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final exampleLine = LyricLineData(
      id: 'settings-preview-current',
      text: l10n.settingsPreviewCurrentLine,
      chords: const [
        LyricChord(graphemeOffset: 0, symbol: 'G'),
        LyricChord(graphemeOffset: 10, symbol: 'C'),
      ],
    );
    final nextLine = LyricLineData(
      id: 'settings-preview-next',
      text: l10n.settingsPreviewNextLine,
    );

    return Semantics(
      container: true,
      label: l10n.settingsLyricsPreview,
      child: Card(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsLyricsPreview,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.settingsPreviewSongTitle,
                style: titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.settingsPreviewArtist,
                style: minorStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              if (state.showSections) ...[
                Text(
                  l10n.sectionVerse,
                  key: const ValueKey('settings-preview-section-heading'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              PlayerLyricLine(
                line: exampleLine,
                state: state,
                current: true,
                fontSize: fontSize,
              ),
              const SizedBox(height: 6),
              PlayerLyricLine(
                line: nextLine,
                state: state,
                current: false,
                fontSize: fontSize,
              ),
              const SizedBox(height: 8),
              if (state.playerControlsExpanded)
                _ExpandedTransport(
                  key: const ValueKey('settings-preview-expanded-controls'),
                  state: state,
                  minorStyle: minorStyle,
                )
              else
                _CollapsedHandle(color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedTransport extends StatelessWidget {
  const _ExpandedTransport({
    super.key,
    required this.state,
    required this.minorStyle,
  });

  final VerseUiState state;
  final TextStyle? minorStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final paceLabel = state.timingMode == 'manual'
        ? l10n.playerManualScroll
        : state.timingMode == 'timed'
        ? l10n.playerTimedLyrics
        : l10n.playerEstimatedPace;

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('0:32', style: minorStyle),
              const Spacer(),
              Text('3:40', style: minorStyle),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final direction = Directionality.of(context);
                final firstX = direction == TextDirection.rtl
                    ? constraints.maxWidth * .76
                    : constraints.maxWidth * .24;
                final secondX = direction == TextDirection.rtl
                    ? constraints.maxWidth * .43
                    : constraints.maxWidth * .57;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      width: constraints.maxWidth * .15,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: firstX - 1,
                      top: 4,
                      bottom: 4,
                      child: Container(width: 2, color: colors.outline),
                    ),
                    Positioned(
                      left: secondX - 1,
                      top: 4,
                      bottom: 4,
                      child: Container(width: 2, color: colors.outline),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sectionVerse,
                  style: minorStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.sectionChorus,
                  style: minorStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  paceLabel,
                  style: minorStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 26,
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _CollapsedHandle extends StatelessWidget {
  const _CollapsedHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Center(
        child: Container(
          width: 34,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );
}
