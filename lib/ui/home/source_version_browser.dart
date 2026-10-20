import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../localized_labels.dart';
import '../library_actions.dart';
import '../player/section_labels.dart';
import '../verse_ui_state.dart';
import '../widgets/chord_lyrics_line.dart';
import '../widgets/verse_components.dart';
import 'source_version_widgets.dart';
import 'comparison_details.dart';

/// A version is a whole page. New arrivals append; the identity of an existing
/// tab never changes when a recommendation gains another contributing source.
class SourceVersionBrowser extends StatefulWidget {
  const SourceVersionBrowser({
    super.key,
    required this.controller,
    this.onOpenFullScreen,
    this.onFilters,
    this.onOpened,
  });
  final VerseUiController controller;
  final VoidCallback? onOpenFullScreen, onFilters, onOpened;

  @override
  State<SourceVersionBrowser> createState() => _SourceVersionBrowserSession();
}

class _SourceVersionBrowserSession extends State<SourceVersionBrowser> {
  String? _referenceId;
  Map<String, double> _readingOffsets = {};

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final state = widget.controller.state;
      final referenceId = state.comparison?.reference.id;
      if (referenceId != _referenceId) {
        _referenceId = referenceId;
        _readingOffsets = {};
      }
      final filters = state.searchFilters;
      // A deliberate filter edit starts a new set of choices. Provider arrivals
      // keep this key, preserving tab order and an explicitly pinned source.
      // Reading offsets belong to the song session, so rebuilding these pages
      // does not discard a retained or temporarily filtered-out version's place.
      return _SourceVersionPages(
        key: ValueKey((
          state.comparison?.reference.id,
          filters.field,
          filters.chordsOnly,
          filters.timedOnly,
          filters.language,
          filters.durationBucket,
        )),
        controller: widget.controller,
        readingOffsets: _readingOffsets,
        onOpenFullScreen: widget.onOpenFullScreen,
        onFilters: widget.onFilters,
        onOpened: widget.onOpened,
      );
    },
  );
}

class _SourceVersionPages extends StatefulWidget {
  const _SourceVersionPages({
    super.key,
    required this.controller,
    required this.readingOffsets,
    this.onOpenFullScreen,
    this.onFilters,
    this.onOpened,
  });

  final VerseUiController controller;
  final Map<String, double> readingOffsets;
  final VoidCallback? onOpenFullScreen, onFilters, onOpened;

  @override
  State<_SourceVersionPages> createState() => _SourceVersionBrowserState();
}

class _SourceVersionBrowserState extends State<_SourceVersionPages> {
  final _order = <String>[];
  final _known = <String, SourceVersionData>{};
  final _documents = <String, GlobalKey<_VersionDocumentState>>{};
  final _tabs = <String, GlobalKey>{};
  late PageController _pages;
  Map<String, SourceVersionData> _current = {};
  String? _visibleId;
  int? _programmaticPage;
  final _anchors = <String, _PreviewAnchor>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reconcile();
    final index = _order.indexOf(_visibleId ?? '');
    _pages = PageController(initialPage: index < 0 ? 0 : index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool _hasBody(SourceVersionData version) =>
      version.bodyLines.isNotEmpty || version.bodyPreview.isNotEmpty;

  void _reconcile() {
    final comparison = widget.controller.state.comparison;
    if (comparison == null) return;
    _current = {
      for (final version in comparisonVersions(comparison))
        versionSelectionId(version): version,
    };
    final selected = comparison.selected;
    final selectedId = selected == null ? null : versionSelectionId(selected);
    // A one-source recommendation can enrich the raw version's metadata.
    // Until the person pins the raw source, paint exactly what Save will use.
    if (selected != null && selectedId != null) {
      _current[selectedId] = selected;
    }
    for (final entry in _current.entries) {
      _known[entry.key] = entry.value;
      if (!_order.contains(entry.key) &&
          (entry.key == selectedId ||
              entry.value.isUsableVersion ||
              entry.value.canSave ||
              (entry.value.isChecking && _hasBody(entry.value)))) {
        _order.add(entry.key);
      }
    }
    _visibleId ??= selectedId ?? (_order.isEmpty ? null : _order.first);
  }

  void _revealTab(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _tabs[id]?.currentContext;
      if (mounted && target != null) {
        Scrollable.ensureVisible(target, alignment: .5);
      }
    });
  }

  void _choose(int index, {bool animate = true}) {
    if (_saving || index < 0 || index >= _order.length) return;
    final id = _order[index];
    if (_visibleId == id) {
      final version = _current[id];
      if (version != null &&
          widget.controller.state.comparison?.selectedVersionId != id) {
        widget.controller.selectVersion(versionSelectionId(version));
      }
      return;
    }
    final anchor = _documents[_visibleId]?.currentState?.captureAnchor();
    // A previously read version keeps its own place, including after filters
    // temporarily remove it. Match passages only when opening a new version.
    if (anchor != null && !widget.readingOffsets.containsKey(id)) {
      _anchors[id] = anchor;
    }
    setState(() => _visibleId = id);
    final version = _current[id];
    if (version != null) {
      widget.controller.selectVersion(versionSelectionId(version));
    }
    if (animate) {
      _programmaticPage = index;
      // A tab can arrive in this frame before the viewport's scroll extent has
      // incorporated the new page. Move after layout, then verify the target.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pages.hasClients || _programmaticPage != index) {
          return;
        }
        unawaited(
          _pages
              .animateToPage(
                index,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              )
              .whenComplete(() {
                if (!mounted) return;
                if (_programmaticPage == index) {
                  if (_pages.hasClients && _pages.page!.round() != index) {
                    _pages.jumpToPage(index);
                  }
                  _programmaticPage = null;
                }
                _restoreAnchor(id);
              }),
        );
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreAnchor(id);
    });
    _revealTab(id);
  }

  void _restoreAnchor(String id) {
    if (id != _visibleId) return;
    final document = _documents[id]?.currentState;
    final anchor = _anchors[id];
    if (document != null && anchor != null) {
      document.restoreAnchor(anchor);
      _anchors.remove(id);
    }
  }

  void _pinVisible() {
    final version = _current[_visibleId];
    if (!_saving &&
        version != null &&
        widget.controller.state.comparison?.selectedVersionId != _visibleId) {
      widget.controller.selectVersion(versionSelectionId(version));
    }
  }

  Future<void> _open() async {
    if (_saving) return;
    final version = _current[_visibleId];
    if (version == null ||
        (!version.hasLyrics && version.savedSongId == null)) {
      return;
    }
    // Save stays available while previews slide. Align a pending selection
    // with the highlighted provider, retaining an already selected combination.
    final selected = widget.controller.state.comparison?.selected;
    if (selected == null || versionSelectionId(selected) != _visibleId) {
      _pinVisible();
      final pinned = widget.controller.state.comparison?.selected;
      if (pinned == null || versionSelectionId(pinned) != _visibleId) return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.saveSelectedVersion();
      if (mounted && widget.controller.state.route == VerseRoute.reader) {
        widget.onOpened?.call();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _reconcile();
    final state = widget.controller.state;
    final comparison = state.comparison;
    final l10n = AppLocalizations.of(context);
    if (comparison == null) return const SizedBox.shrink();
    final external = comparison.selected;
    final externalId = external == null ? null : versionSelectionId(external);
    if (externalId != null &&
        externalId != _visibleId &&
        _order.contains(externalId)) {
      _visibleId = externalId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) {
          _pages.jumpToPage(_order.indexOf(externalId));
          _revealTab(externalId);
        }
      });
    }
    final version = _current[_visibleId];
    final ready = _current.values
        .where((version) => version.hasLyrics || version.savedSongId != null)
        .map(versionSelectionId)
        .toSet()
        .length;
    final checked = comparison.providerChecks
        .where((c) => c.state != 'pending')
        .length;
    final filters = state.searchFilters;
    final filteredEmpty =
        !comparison.discovering &&
        comparison.discoveryError == null &&
        !comparison.noUsableLyrics &&
        (filters.chordsOnly ||
            filters.timedOnly ||
            filters.language.isNotEmpty ||
            filters.durationBucket.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          key: const ValueKey('version-tabs'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              for (final id in _order)
                Padding(
                  key: _tabs.putIfAbsent(id, GlobalKey.new),
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    key: ValueKey('version-row-$id'),
                    selected: id == _visibleId,
                    onSelected: _saving
                        ? null
                        : (_) => _choose(_order.indexOf(id)),
                    avatar: _current[id]?.isChecking == true
                        ? const Icon(Icons.hourglass_empty_rounded, size: 16)
                        : _current[id] == null ||
                              (!_current[id]!.isUsableVersion &&
                                  !_current[id]!.canSave &&
                                  _current[id]!.savedSongId == null)
                        ? const Icon(Icons.info_outline_rounded, size: 16)
                        : null,
                    label: Text(versionName(l10n, _current[id] ?? _known[id]!)),
                  ),
                ),
            ],
          ),
        ),
        if (comparison.discovering)
          const LinearProgressIndicator(
            key: ValueKey('discovery-progress'),
            minHeight: 2,
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.searchReadyVersions(ready),
                  key: const ValueKey('home-search-comparison-counts'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (comparison.discovering)
                Tooltip(
                  message: l10n.searchDiscoveryProgress(
                    checked,
                    comparison.providerChecks.length,
                  ),
                  child: Text(
                    '$checked/${comparison.providerChecks.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              IconButton(
                key: const ValueKey('version-info-button'),
                tooltip: l10n.searchVersionDetails,
                onPressed: version == null
                    ? null
                    : () => showComparisonVersionInfo(
                        context,
                        controller: widget.controller,
                        version: version,
                      ),
                icon: const Icon(Icons.info_outline_rounded),
              ),
              IconButton(
                key: const ValueKey('source-checks-button'),
                tooltip: l10n.searchProviderChecks,
                onPressed: () => showComparisonSourceChecks(
                  context,
                  controller: widget.controller,
                ),
                icon: const Icon(Icons.fact_check_outlined),
              ),
              if (version?.savedSongId case final songId?)
                PopupMenuButton<String>(
                  key: const ValueKey('online-song-menu'),
                  tooltip: l10n.songMenuLabel,
                  icon: const Icon(Icons.more_horiz_rounded),
                  itemBuilder: (_) =>
                      buildLibraryActionMenu(l10n, actions: songLibraryActions),
                  onSelected: (action) async {
                    await handleSongMenuAction(
                      context,
                      widget.controller,
                      songId,
                      action,
                    );
                    if (mounted && action == 'edit') widget.onOpened?.call();
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _order.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comparison.reference.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(comparison.reference.artist),
                      const SizedBox(height: 20),
                      if (filteredEmpty)
                        VerseEmptyState(
                          key: const ValueKey('version-filters-empty'),
                          icon: Icons.filter_alt_off_outlined,
                          title: l10n.emptyFiltered,
                          actionLabel: l10n.actionClear,
                          onAction: () {
                            widget.controller.setSearchFilter(
                              'chordsOnly',
                              false,
                            );
                            widget.controller.setSearchFilter(
                              'timedOnly',
                              false,
                            );
                            widget.controller.setSearchFilter('language', '');
                            widget.controller.setSearchFilter(
                              'durationBucket',
                              '',
                            );
                          },
                        )
                      else
                        Text(
                          key: ValueKey(
                            comparison.discoveryError != null
                                ? 'discovery-error'
                                : 'discovery-no-lyrics',
                          ),
                          comparison.discovering
                              ? l10n.searchVersionChecking
                              : comparison.discoveryError != null
                              ? l10n.searchDiscoveryError
                              : l10n.searchDiscoveryNoLyrics,
                        ),
                      if (!comparison.discovering && !filteredEmpty)
                        if (comparison.noUsableLyrics)
                          Text(l10n.searchDiscoveryNoLyricsDetails),
                      if (!comparison.discovering && !filteredEmpty)
                        TextButton(
                          onPressed: () => unawaited(
                            widget.controller.retrySelectedSongDiscovery(),
                          ),
                          child: Text(l10n.searchDiscoveryRetry),
                        ),
                    ],
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis != Axis.horizontal) {
                      return false;
                    }
                    if (notification is ScrollStartNotification) {
                      if (notification.dragDetails != null) {
                        _programmaticPage = null;
                      }
                    } else if (notification is ScrollEndNotification) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || !_pages.hasClients) return;
                        if (_programmaticPage == null) {
                          _choose(_pages.page!.round(), animate: false);
                        }
                      });
                    }
                    return false;
                  },
                  child: PageView.builder(
                    key: const ValueKey('version-preview-pages'),
                    controller: _pages,
                    physics: _saving
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (index) {
                      if (_programmaticPage != null) return;
                      if (_order[index] == _visibleId) return;
                      _choose(index, animate: false);
                    },
                    itemCount: _order.length,
                    findChildIndexCallback: (key) {
                      final index = key is ValueKey<String>
                          ? _order.indexOf(key.value)
                          : -1;
                      return index < 0 ? null : index;
                    },
                    itemBuilder: (context, index) {
                      final id = _order[index];
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _restoreAnchor(id);
                      });
                      return KeyedSubtree(
                        key: ValueKey(id),
                        child: Listener(
                          onPointerDown: (_) => _pinVisible(),
                          child: _VersionDocument(
                            key: _documents.putIfAbsent(
                              id,
                              GlobalKey<_VersionDocumentState>.new,
                            ),
                            version: _current[id] ?? _known[id]!,
                            readingOffsets: widget.readingOffsets,
                            reference: comparison.reference,
                            available: _current.containsKey(id),
                            showChords: state.showChords,
                            fontSize: state.lyricsFontSize,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (_order.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              key: const ValueKey('version-selection-footer'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton.icon(
                key: ValueKey(
                  widget.onOpened == null
                      ? 'save-open-lyrics'
                      : 'preview-save-open',
                ),
                onPressed: _open,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.menu_book_rounded),
                label: Text(l10n.actionSave),
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviewAnchor {
  const _PreviewAnchor(this.text, this.occurrence, this.fraction);
  final String? text;
  final int occurrence;
  final double fraction;
}

class _VersionDocument extends StatefulWidget {
  const _VersionDocument({
    super.key,
    required this.version,
    required this.readingOffsets,
    required this.reference,
    required this.available,
    required this.showChords,
    required this.fontSize,
  });
  final SourceVersionData version;
  final Map<String, double> readingOffsets;
  final SearchReferenceData reference;
  final bool available, showChords;
  final double fontSize;
  @override
  State<_VersionDocument> createState() => _VersionDocumentState();
}

class _VersionDocumentState extends State<_VersionDocument>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scroll;
  final _viewport = GlobalKey();
  final _lineKeys = <String, GlobalKey>{};
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final id = versionSelectionId(widget.version);
    _scroll =
        ScrollController(
          initialScrollOffset: widget.readingOffsets[id] ?? 0,
          keepScrollOffset: false,
        )..addListener(() {
          // Remember even an in-progress scroll before a filter rebuilds the page.
          widget.readingOffsets[id] = _scroll.offset;
        });
  }

  List<LyricLineData> get _lines => widget.version.bodyLines.isNotEmpty
      ? widget.version.bodyLines
      : widget.version.bodyPreview;
  String _anchorText(LyricLineData line) =>
      (line.text.trim().isNotEmpty ? line.text : line.section ?? '')
          .trim()
          .toLowerCase();

  _PreviewAnchor captureAnchor() {
    final viewport = _viewport.currentContext?.findRenderObject() as RenderBox?;
    final top = viewport?.localToGlobal(Offset.zero).dy;
    String? anchor;
    var occurrence = 0;
    if (top != null) {
      for (final line in _lines) {
        final box = _lineKeys[line.id]?.currentContext?.findRenderObject();
        if (box is RenderBox &&
            box.localToGlobal(Offset(0, box.size.height)).dy > top + 8 &&
            _anchorText(line).isNotEmpty) {
          anchor = _anchorText(line);
          occurrence = _lines
              .takeWhile((item) => item.id != line.id)
              .where((item) => _anchorText(item) == anchor)
              .length;
          break;
        }
      }
    }
    return _PreviewAnchor(
      anchor,
      occurrence,
      _scroll.hasClients && _scroll.position.maxScrollExtent > 0
          ? _scroll.offset / _scroll.position.maxScrollExtent
          : 0,
    );
  }

  void restoreAnchor(_PreviewAnchor anchor) {
    if (!_scroll.hasClients) return;
    if (anchor.fraction == 0) {
      _scroll.jumpTo(0);
      return;
    }
    final matches = _lines
        .where((line) => _anchorText(line) == anchor.text)
        .toList();
    final target = matches.isEmpty
        ? null
        : _lineKeys[matches[anchor.occurrence.clamp(0, matches.length - 1)].id]
              ?.currentContext;
    if (target != null) {
      _scroll.position.ensureVisible(
        target.findRenderObject()!,
        alignment: .08,
      );
    } else {
      _scroll.jumpTo(
        (anchor.fraction * _scroll.position.maxScrollExtent).clamp(
          0,
          _scroll.position.maxScrollExtent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final version = widget.version;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lines = _lines;
    final notes = lines.where((line) => line.isArrangementNote).toList();
    final lyrics = lines.where((line) => !line.isArrangementNote).toList();
    final hasBody = lyrics.any(
      (line) => line.text.trim().isNotEmpty || line.chords.isNotEmpty,
    );
    final metadata = [
      widget.reference.artist,
      if (widget.reference.album?.trim().isNotEmpty == true &&
          widget.reference.album!.toLowerCase() != 'unknown')
        widget.reference.album!,
      if (widget.reference.durationSeconds != null)
        formatDuration(widget.reference.durationSeconds!),
    ].where((part) => part.isNotEmpty).join(' · ');
    return SizedBox(
      key: _viewport,
      child: SingleChildScrollView(
        key: const ValueKey('full-preview-body'),
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.reference.title, style: theme.textTheme.titleLarge),
            if (metadata.isNotEmpty)
              Text(metadata, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Capability(
                  version.sameRecording
                      ? Icons.verified_outlined
                      : Icons.help_outline_rounded,
                  version.sameRecording
                      ? l10n.searchMatchExact
                      : version.matchSummary.isNotEmpty
                      ? localizedMatchReason(l10n, version.matchSummary)
                      : l10n.searchMatchUnverified,
                ),
                if (version.hasLyrics)
                  _Capability(
                    Icons.lyrics_outlined,
                    l10n.providerCapabilityLyrics,
                  ),
                if (version.hasChords)
                  _Capability(
                    Icons.music_note_rounded,
                    l10n.providerCapabilityChords,
                  ),
                if (version.durationSeconds != null)
                  _Capability(
                    Icons.timer_outlined,
                    '${l10n.searchVersionDuration}: ${formatDuration(version.durationSeconds!)}',
                  ),
                _Capability(
                  Icons.schedule_rounded,
                  version.hasTiming
                      ? l10n.playerTimedLyrics
                      : version.durationSeconds != null
                      ? l10n.playerEstimatedPace
                      : l10n.searchTimingUnavailable,
                ),
              ],
            ),
            if ((version.sourceCount ?? 0) > 1) ...[
              const SizedBox(height: 8),
              SourceContributions(version: version),
            ],
            if (version.isChecking)
              Text(
                l10n.searchVersionChecking,
                style: theme.textTheme.bodySmall,
              ),
            if (!widget.available ||
                (!version.isChecking &&
                    !version.canSave &&
                    !version.isUsableVersion &&
                    version.savedSongId == null))
              Text(
                l10n.searchVersionUnavailable,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            if (!hasBody) Text(l10n.searchPreviewUnavailable),
            for (var index = 0; index < lyrics.length; index++)
              _PreviewLine(
                key: _lineKeys.putIfAbsent(lyrics[index].id, GlobalKey.new),
                line: lyrics[index],
                instrumentalBlank:
                    lyrics[index].isBlank &&
                    lyrics[index].section == null &&
                    ((index > 0 &&
                            lyrics[index - 1].text.trim().isEmpty &&
                            lyrics[index - 1].chords.isNotEmpty) ||
                        (index + 1 < lyrics.length &&
                            lyrics[index + 1].text.trim().isEmpty &&
                            lyrics[index + 1].chords.isNotEmpty)),
                showChords: widget.showChords,
                fontSize: widget.fontSize,
              ),
            if (notes.isNotEmpty)
              ExpansionTile(
                key: ValueKey('preview-notes-${version.id}'),
                title: Text(l10n.searchArrangementNotes),
                children: [
                  for (final line in notes)
                    _PreviewLine(
                      line: line,
                      showChords: widget.showChords,
                      fontSize: widget.fontSize,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Capability extends StatelessWidget {
  const _Capability(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    ],
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    super.key,
    required this.line,
    required this.showChords,
    required this.fontSize,
    this.instrumentalBlank = false,
  });
  final LyricLineData line;
  final bool showChords, instrumentalBlank;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (line.section != null) {
      return Padding(
        key: ValueKey('preview-line-${line.id}'),
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(
          localizedSectionName(AppLocalizations.of(context), line.section!),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (line.isBlank && line.chords.isEmpty) {
      return SizedBox(
        key: ValueKey('preview-line-${line.id}'),
        height: instrumentalBlank ? 3 : 12,
      );
    }
    final instrumental = line.text.trim().isEmpty && line.chords.isNotEmpty;
    return Padding(
      key: ValueKey('preview-line-${line.id}'),
      padding: EdgeInsets.only(bottom: instrumental ? 2 : 12),
      child: ChordLyricsLine(
        text: line.text,
        chords: line.chords,
        showChords: showChords,
        compactChordOnly: instrumental,
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
