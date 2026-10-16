import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../localized_labels.dart';
import '../player/section_labels.dart';
import '../verse_ui_state.dart';
import '../widgets/chord_lyrics_line.dart';
import '../widgets/verse_components.dart';
import 'source_version_widgets.dart';

/// A version is a whole page. New arrivals append; the identity of an existing
/// tab never changes when a recommendation gains another contributing source.
class SourceVersionBrowser extends StatefulWidget {
  const SourceVersionBrowser({
    super.key,
    required this.controller,
    this.onOpenFullScreen,
    this.onFilters,
    this.onOpened,
    this.filters,
  });

  final VerseUiController controller;
  final VoidCallback? onOpenFullScreen, onFilters, onOpened;
  final Widget? filters;

  @override
  State<SourceVersionBrowser> createState() => _SourceVersionBrowserState();
}

class _SourceVersionBrowserState extends State<SourceVersionBrowser> {
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
  bool _paging = false;

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
    if (anchor != null) _anchors[id] = anchor;
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
        if (!mounted || !_pages.hasClients || _programmaticPage != index)
          return;
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
    final selected = widget.controller.state.comparison?.selected;
    final version = _current[_visibleId];
    if (version == null ||
        selected == null ||
        versionSelectionId(selected) != _visibleId ||
        (!version.canSave && version.savedSongId == null)) {
      return;
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

  void _jumpSection() {
    _pinVisible();
    final sourceId = _visibleId;
    final version = _current[sourceId];
    if (version == null) return;
    final sections = version.bodyLines.where((line) => line.section != null);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .5,
          maxChildSize: .9,
          builder: (context, scroll) => ListView(
            controller: scroll,
            children: [
              ListTile(title: Text(l10n.searchJumpSection)),
              for (final line in sections)
                ListTile(
                  title: Text(localizedSectionName(l10n, line.section!)),
                  onTap: () {
                    Navigator.pop(context);
                    if (_visibleId == sourceId) {
                      _documents[sourceId]?.currentState?.jumpTo(line.id);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSources() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .6,
          maxChildSize: .9,
          builder: (context, scroll) => AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final comparison = widget.controller.state.comparison;
              if (comparison == null) return const SizedBox.shrink();
              final unavailable = comparisonVersions(comparison)
                  .where(
                    (v) =>
                        !v.isChecking &&
                        !v.canSave &&
                        !v.isUsableVersion &&
                        v.savedSongId == null,
                  )
                  .toList();
              String status(String state) => switch (state) {
                'pending' => l10n.searchProviderPending,
                'found' => l10n.searchProviderFound,
                'rejected' => l10n.searchProviderRejected,
                'failed' => l10n.searchProviderFailed,
                _ => l10n.searchProviderUnavailable,
              };
              return ListView(
                controller: scroll,
                children: [
                  ListTile(title: Text(l10n.searchProviderChecks)),
                  if (comparison.providerChecks.any(
                    (check) =>
                        check.state == 'failed' || check.state == 'unavailable',
                  ))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.searchSourcesUnavailableCount(
                          comparison.providerChecks
                              .where(
                                (check) =>
                                    check.state == 'failed' ||
                                    check.state == 'unavailable',
                              )
                              .length,
                        ),
                      ),
                    ),
                  if (comparison.discoveryError != null ||
                      comparison.noUsableLyrics)
                    ListTile(
                      leading: const Icon(Icons.refresh_rounded),
                      title: Text(l10n.searchDiscoveryRetry),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        unawaited(
                          widget.controller.retrySelectedSongDiscovery(),
                        );
                      },
                    ),
                  if (widget.onFilters != null)
                    ListTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: Text(l10n.searchFilters),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onFilters!();
                      },
                    ),
                  if (widget.onOpenFullScreen != null)
                    ListTile(
                      leading: const Icon(Icons.fullscreen_rounded),
                      title: Text(l10n.searchFullPreview),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onOpenFullScreen!();
                      },
                    ),
                  if (unavailable.isNotEmpty)
                    ExpansionTile(
                      key: const ValueKey('unavailable-versions'),
                      title: Text(
                        l10n.searchUnavailableVersions(unavailable.length),
                      ),
                      children: [
                        for (final version in unavailable)
                          ListTile(
                            title: Text(versionName(l10n, version)),
                            subtitle: Text(l10n.searchVersionUnavailable),
                            onTap: _saving
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);
                                    final id = versionSelectionId(version);
                                    setState(() {
                                      _current[id] = version;
                                      _known[id] = version;
                                      if (!_order.contains(id)) _order.add(id);
                                    });
                                    _choose(_order.indexOf(id));
                                  },
                          ),
                      ],
                    ),
                  for (final check in comparison.providerChecks)
                    ListTile(
                      key: ValueKey('discovery-provider-${check.id}'),
                      dense: true,
                      title: Text(check.name),
                      subtitle: Text(status(check.state)),
                      trailing: Icon(
                        check.state == 'pending'
                            ? Icons.hourglass_empty_rounded
                            : check.state == 'found'
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
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
      final available =
          version != null &&
          externalId == _visibleId &&
          (version.canSave || version.savedSongId != null);
      final ready = _current.values
          .where((v) => v.canSave || v.savedSongId != null)
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
                      label: Text(
                        versionName(l10n, _current[id] ?? _known[id]!),
                      ),
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
                if (version?.bodyLines.any((line) => line.section != null) ==
                    true)
                  IconButton(
                    key: const ValueKey('preview-sections'),
                    tooltip: l10n.searchJumpSection,
                    onPressed: _jumpSection,
                    icon: const Icon(Icons.segment_rounded),
                  ),
                IconButton(
                  key: const ValueKey('version-source-menu'),
                  tooltip: l10n.searchProviderChecks,
                  onPressed: _showSources,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          if (widget.filters != null)
            Flexible(child: SingleChildScrollView(child: widget.filters!)),
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
                        if (!_paging) {
                          setState(() => _paging = true);
                        }
                      } else if (notification is ScrollEndNotification) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || !_pages.hasClients) return;
                          if (_programmaticPage == null) {
                            _choose(_pages.page!.round(), animate: false);
                          }
                          if (_paging) setState(() => _paging = false);
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
                  onPressed: available && !_saving && !_paging ? _open : null,
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
                  label: Text(
                    version?.savedSongId != null
                        ? l10n.searchOpenLyrics
                        : l10n.searchSaveOpenLyrics,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
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
    required this.reference,
    required this.available,
    required this.showChords,
    required this.fontSize,
  });
  final SourceVersionData version;
  final SearchReferenceData reference;
  final bool available, showChords;
  final double fontSize;
  @override
  State<_VersionDocument> createState() => _VersionDocumentState();
}

class _VersionDocumentState extends State<_VersionDocument>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final _viewport = GlobalKey();
  final _lineKeys = <String, GlobalKey>{};
  @override
  bool get wantKeepAlive => true;
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
      Scrollable.ensureVisible(target, alignment: .08);
    } else {
      _scroll.jumpTo(
        (anchor.fraction * _scroll.position.maxScrollExtent).clamp(
          0,
          _scroll.position.maxScrollExtent,
        ),
      );
    }
  }

  void jumpTo(String id) {
    final target = _lineKeys[id]?.currentContext;
    if (target != null) Scrollable.ensureVisible(target, alignment: .02);
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
            ExpansionTile(
              key: ValueKey('version-details-${version.id}'),
              tilePadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              minTileHeight: 36,
              dense: true,
              title: Text(
                version.sameRecording
                    ? l10n.searchMatchExact
                    : version.matchSummary.isNotEmpty
                    ? localizedMatchReason(l10n, version.matchSummary)
                    : l10n.searchMatchUnverified,
                style: theme.textTheme.bodySmall,
              ),
              childrenPadding: const EdgeInsets.only(bottom: 10),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.searchVersionDetails,
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  [
                    version.title,
                    version.artist,
                    if (version.album?.isNotEmpty == true &&
                        version.album!.toLowerCase() != 'unknown')
                      version.album!,
                  ].where((value) => value.isNotEmpty).join(' · '),
                ),
                Text(
                  l10n.searchSelectedRecording,
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  [
                    widget.reference.title,
                    widget.reference.artist,
                    if (widget.reference.album?.isNotEmpty == true)
                      widget.reference.album!,
                    if (widget.reference.durationSeconds != null)
                      formatDuration(widget.reference.durationSeconds!),
                  ].where((value) => value.isNotEmpty).join(' · '),
                ),
                if (version.durationSeconds != null)
                  Text(
                    '${l10n.searchVersionDuration}: ${formatDuration(version.durationSeconds!)}',
                  ),
                if (version.rating != null)
                  Text(l10n.searchRating(version.rating!.toString())),
              ],
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
