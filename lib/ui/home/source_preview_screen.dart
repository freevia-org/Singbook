import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../player/section_labels.dart';
import '../verse_ui_state.dart';
import '../widgets/chord_lyrics_line.dart';

/// The same choices are used by the comparison list and the full preview.
List<SourceVersionData> comparisonVersions(SearchComparisonData comparison) {
  final suggested = comparison.suggested;
  final explicitUnderlying =
      suggested?.sourceCount == 1 &&
      suggested?.underlyingSourceId == comparison.selectedVersionId;
  return [
    if (suggested != null && !explicitUnderlying) suggested,
    ...comparison.alternatives.where(
      (version) =>
          version.id != suggested?.id &&
          !(suggested?.sourceCount == 1 &&
              version.id == suggested?.underlyingSourceId &&
              version.id != comparison.selectedVersionId &&
              version.durationSeconds == suggested?.durationSeconds &&
              version.hasChords == suggested?.hasChords &&
              version.hasTiming == suggested?.hasTiming),
    ),
  ];
}

String versionName(AppLocalizations l10n, SourceVersionData version) =>
    version.sourceCount != null && version.sourceCount! > 1
    ? l10n.searchCombinedFromSources(version.sourceCount!)
    : version.providerName.isNotEmpty
    ? version.providerName
    : l10n.searchSuggested;

/// A single-source recommendation is displayed under that source's name.
/// Choosing it must pin that source rather than a future combined recipe.
String versionSelectionId(SourceVersionData version) =>
    version.sourceCount == 1 && version.underlyingSourceId != null
    ? version.underlyingSourceId!
    : version.id;

class SourceContributions extends StatelessWidget {
  const SourceContributions({super.key, required this.version});
  final SourceVersionData version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if ((version.sourceCount ?? 0) < 2 || version.contributions.isEmpty) {
      return const SizedBox.shrink();
    }
    String role(String value) => switch (value) {
      'lyrics' => l10n.providerCapabilityLyrics,
      'chords' => l10n.providerCapabilityChords,
      'timing' => l10n.playerTimedLyrics,
      _ => l10n.searchMetadata,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchContributions,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        for (final contribution in version.contributions)
          Text(
            '${contribution.providerName} · ${contribution.roles.map(role).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// Inspect a version before saving. Provider updates remain visible, while
/// choosing a different version is always an explicit action.
class SourcePreviewScreen extends StatefulWidget {
  const SourcePreviewScreen({super.key, required this.controller});
  final VerseUiController controller;

  @override
  State<SourcePreviewScreen> createState() => _SourcePreviewScreenState();
}

class _SourcePreviewScreenState extends State<SourcePreviewScreen> {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  final Map<String, GlobalKey> _lineKeys = {};
  bool _saving = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Keep a shared lyric/section in view when comparing arrangements. Different
  // wording falls back to the same proportional place in the document.
  void _switchTo(SourceVersionData version, SourceVersionData? previous) {
    String? anchor;
    var occurrence = 0;
    final viewport = _viewport.currentContext?.findRenderObject() as RenderBox?;
    final top = viewport?.localToGlobal(Offset.zero).dy;
    if (previous != null && top != null) {
      for (final line in previous.bodyLines) {
        final box = _lineKeys[line.id]?.currentContext?.findRenderObject();
        if (box is RenderBox &&
            box.localToGlobal(Offset(0, box.size.height)).dy > top + 8) {
          final text = line.text.trim().isNotEmpty ? line.text : line.section;
          if (text?.trim().isNotEmpty == true) {
            anchor = text!.trim().toLowerCase();
            occurrence = previous.bodyLines
                .takeWhile((item) => item.id != line.id)
                .where(
                  (item) =>
                      (item.text.trim().isNotEmpty
                              ? item.text
                              : item.section ?? '')
                          .trim()
                          .toLowerCase() ==
                      anchor,
                )
                .length;
            break;
          }
        }
      }
    }
    final fraction = _scroll.hasClients && _scroll.position.maxScrollExtent > 0
        ? _scroll.offset / _scroll.position.maxScrollExtent
        : 0.0;
    widget.controller.selectVersion(versionSelectionId(version));
    final resolved = widget.controller.state.comparison?.selected ?? version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final matches = resolved.bodyLines
          .where(
            (line) =>
                (line.text.trim().isNotEmpty ? line.text : line.section ?? '')
                    .trim()
                    .toLowerCase() ==
                anchor,
          )
          .toList();
      final target = matches.isEmpty
          ? null
          : _lineKeys[matches[occurrence.clamp(0, matches.length - 1)].id]
                ?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, alignment: .08);
      } else {
        _scroll.jumpTo(
          (fraction * _scroll.position.maxScrollExtent).clamp(
            0,
            _scroll.position.maxScrollExtent,
          ),
        );
      }
    });
  }

  Future<void> _open() async {
    setState(() => _saving = true);
    try {
      await widget.controller.saveSelectedVersion();
      if (mounted && widget.controller.state.route == VerseRoute.reader) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final comparison = state.comparison;
      final l10n = AppLocalizations.of(context);
      final versions = comparison == null
          ? <SourceVersionData>[]
          : comparisonVersions(comparison);
      final selected = comparison?.selected;
      final index = versions.indexWhere((item) => item.id == selected?.id);
      final available =
          selected != null &&
          (selected.canSave || selected.savedSongId != null);
      final lines = selected?.bodyLines ?? const <LyricLineData>[];
      // Present the song first. Leading tuning/fingering instructions remain
      // available as arrangement notes instead of crowding out the lyrics.
      final start = selected?.bodyPreview.isNotEmpty == true
          ? lines.indexWhere(
              (line) => line.id == selected!.bodyPreview.first.id,
            )
          : lines.length;
      final notes = lines
          .take(start < 0 ? 0 : start)
          .where((line) => line.isArrangementNote)
          .toList();
      final noteIds = notes.map((line) => line.id).toSet();
      final lyrics = lines.where((line) => !noteIds.contains(line.id));
      final hasLyrics = lyrics.any(
        (line) =>
            line.text.trim().isNotEmpty &&
            !line.isArrangementNote &&
            line.section == null,
      );
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.navClose,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(l10n.searchFullPreview),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const ValueKey('preview-previous'),
                      tooltip: l10n.actionPrevious,
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                      ),
                      onPressed: !_saving && index > 0
                          ? () => _switchTo(versions[index - 1], selected)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        selected == null
                            ? l10n.searchPreviewUnavailable
                            : versionName(l10n, selected),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${index < 0 ? 0 : index + 1}/${versions.length}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    IconButton(
                      key: const ValueKey('preview-next'),
                      tooltip: l10n.actionNext,
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                      ),
                      onPressed:
                          !_saving && index >= 0 && index + 1 < versions.length
                          ? () => _switchTo(versions[index + 1], selected)
                          : null,
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  key: _viewport,
                  child: ListView(
                    key: const ValueKey('full-preview-body'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      if (selected != null) ...[
                        Text(
                          selected.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          [
                            selected.artist,
                            if (selected.durationSeconds != null)
                              formatDuration(selected.durationSeconds!),
                          ].where((value) => value.isNotEmpty).join(' · '),
                        ),
                        if ((selected.sourceCount ?? 0) > 1) ...[
                          const SizedBox(height: 12),
                          SourceContributions(version: selected),
                        ],
                        const SizedBox(height: 20),
                      ],
                      if (!hasLyrics) Text(l10n.searchPreviewUnavailable),
                      for (final line in lyrics)
                        _PreviewLine(
                          key: _lineKeys.putIfAbsent(line.id, GlobalKey.new),
                          line: line,
                          showChords: state.showChords,
                          fontSize: state.lyricsFontSize,
                        ),
                      if (notes.isNotEmpty)
                        ExpansionTile(
                          key: ValueKey('preview-notes-${selected?.id}'),
                          title: Text(l10n.searchArrangementNotes),
                          children: [
                            for (final line in notes)
                              _PreviewLine(
                                line: line,
                                showChords: state.showChords,
                                fontSize: state.lyricsFontSize,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (selected?.isChecking == true)
                          Text(l10n.searchVersionChecking),
                        if (selected != null &&
                            !selected.isChecking &&
                            !available)
                          Text(l10n.searchVersionUnavailable),
                        FilledButton.icon(
                          key: const ValueKey('preview-save-open'),
                          onPressed: available && !_saving ? _open : null,
                          icon: const Icon(Icons.menu_book_rounded),
                          label: Text(
                            selected?.savedSongId != null
                                ? l10n.searchOpenLyrics
                                : l10n.searchSaveOpenLyrics,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    super.key,
    required this.line,
    required this.showChords,
    required this.fontSize,
  });
  final LyricLineData line;
  final bool showChords;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (line.section != null) {
      return Padding(
        key: ValueKey('preview-line-${line.id}'),
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          localizedSectionName(AppLocalizations.of(context), line.section!),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (line.isBlank) {
      return SizedBox(key: ValueKey('preview-line-${line.id}'), height: 15);
    }
    return Padding(
      key: ValueKey('preview-line-${line.id}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: ChordLyricsLine(
        text: line.text,
        chords: line.chords,
        showChords: showChords,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: fontSize,
          height: 1.35,
        ),
        chordStyle: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
