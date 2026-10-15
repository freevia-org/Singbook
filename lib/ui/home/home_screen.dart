import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../library_actions.dart';
import '../verse_ui_state.dart';
import '../localized_labels.dart';
import '../widgets/verse_components.dart';
import 'source_preview_screen.dart';

class VerseHomeScreen extends StatefulWidget {
  const VerseHomeScreen({
    super.key,
    required this.controller,
    required this.state,
  });
  final VerseUiController controller;
  final VerseUiState state;
  @override
  State<VerseHomeScreen> createState() => _VerseHomeScreenState();
}

class _VerseHomeScreenState extends State<VerseHomeScreen> {
  final _scroll = ScrollController();
  final _queryScroll = ScrollController();
  final _timelineScroll = ScrollController();
  final _queryFocus = FocusNode();
  final _viewport = GlobalKey();
  late final TextEditingController _query;
  final Map<String, GlobalKey> _dayKeys = {};
  Timer? _hideTimeline;
  bool _timelineVisible = false, _paging = false;
  int _activeDay = 0;
  bool _activeDayPending = false;

  // History groups are rebuilt only when their inputs change, not on every
  // scroll event or rebuild.
  List<_HistoryGroup>? _cachedGroups;
  Object? _cacheRecent, _cacheSongs, _cacheSetlists;
  HomeListMode? _cacheMode;
  String? _cacheQuery, _cacheLocale;
  DateTime? _cacheDay;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.state.query);
    _scroll.addListener(_onScroll);
    _queryFocus.addListener(_onSearchFocusChanged);
  }

  @override
  void didUpdateWidget(covariant VerseHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasRecent =
        oldWidget.state.activeTab == VerseTab.home &&
        oldWidget.state.homeListMode == HomeListMode.recent;
    final isRecent =
        widget.state.activeTab == VerseTab.home &&
        widget.state.homeListMode == HomeListMode.recent;
    if (wasRecent && !isRecent) {
      _hideTimeline?.cancel();
      _timelineVisible = false;
    }
    if (_query.text != widget.state.query) {
      _query.value = TextEditingValue(
        text: widget.state.query,
        selection: TextSelection.collapsed(offset: widget.state.query.length),
      );
    }
    if (!widget.state.loadingMoreRecent) _paging = false;
  }

  @override
  void dispose() {
    _hideTimeline?.cancel();
    _scroll.removeListener(_onScroll);
    _queryFocus.removeListener(_onSearchFocusChanged);
    _scroll.dispose();
    _queryScroll.dispose();
    _timelineScroll.dispose();
    _queryFocus.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final state = widget.state;
    final recent =
        state.activeTab == VerseTab.home &&
        state.homeListMode == HomeListMode.recent;
    if (recent && _scroll.offset > 0 && state.recent.isNotEmpty) {
      _hideTimeline?.cancel();
      if (!_timelineVisible) setState(() => _timelineVisible = true);
      _scheduleActiveDayUpdate();
      _hideTimeline = Timer(const Duration(milliseconds: 850), () {
        if (mounted) setState(() => _timelineVisible = false);
      });
    } else if (_timelineVisible || _activeDay != 0) {
      _hideTimeline?.cancel();
      setState(() {
        _timelineVisible = false;
        _activeDay = 0;
      });
    }
    if (recent &&
        state.recentHasMore &&
        !state.loadingMoreRecent &&
        !_paging &&
        _scroll.position.extentAfter < 260) {
      _paging = true;
      unawaited(
        widget.controller.loadMoreRecent().whenComplete(() {
          _paging = false;
        }),
      );
    }
  }

  void _submitSearch() {
    _queryFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _resetQueryScroll();
    unawaited(widget.controller.submitSearch());
  }

  void _openReference(SearchReferenceData reference) {
    _queryFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _resetQueryScroll();
    unawaited(widget.controller.selectReference(reference));
  }

  void _onSearchFocusChanged() {
    if (!_queryFocus.hasFocus) _resetQueryScroll();
  }

  void _resetQueryScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _queryFocus.hasFocus || !_queryScroll.hasClients) return;
      _queryScroll.jumpTo(_queryScroll.position.minScrollExtent);
    });
  }

  List<RecentItemData> _historyItemsForMode(
    HomeListMode mode,
    AppLocalizations l10n,
  ) {
    if (mode == HomeListMode.recent) return widget.state.recent;
    if (mode != HomeListMode.favorites) return const [];
    return <RecentItemData>[
      ...widget.state.songs
          .where((item) => item.favorite)
          .map(
            (song) => RecentItemData(
              id: song.id,
              title: song.title,
              artist: song.artist,
              subtitle: [
                if (song.album?.isNotEmpty == true) song.album!,
                if (song.durationSeconds != null)
                  formatDuration(song.durationSeconds!),
              ].join(' · '),
              artworkUrl: song.artworkUrl,
              occurredAt: song.modifiedAt ?? DateTime.now(),
              isSetlist: false,
              favorite: true,
              playCount: song.playCount,
            ),
          ),
      ...widget.state.setlists
          .where((item) => item.favorite)
          .map(
            (set) => RecentItemData(
              id: set.id,
              title: set.title,
              subtitle: l10n.setlistSongsCount(set.songTitles.length),
              occurredAt: set.modifiedAt ?? DateTime.now(),
              isSetlist: true,
              favorite: true,
            ),
          ),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  List<RecentItemData> _filteredHistoryItems(
    HomeListMode mode,
    AppLocalizations l10n,
  ) {
    final query = widget.state.query.trim().toLowerCase();
    final items = _historyItemsForMode(mode, l10n);
    if (query.isEmpty) return items;
    return items
        .where(
          (item) => '${item.title} ${item.artist} ${item.subtitle}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
  }

  List<_HistoryGroup> _groups(AppLocalizations l10n) {
    final state = widget.state;
    final today = DateUtils.dateOnly(DateTime.now());
    final cached = _cachedGroups;
    if (cached != null &&
        identical(_cacheRecent, state.recent) &&
        identical(_cacheSongs, state.songs) &&
        identical(_cacheSetlists, state.setlists) &&
        _cacheMode == state.homeListMode &&
        _cacheQuery == state.query &&
        _cacheLocale == l10n.localeName &&
        _cacheDay == today) {
      return cached;
    }
    _cacheRecent = state.recent;
    _cacheSongs = state.songs;
    _cacheSetlists = state.setlists;
    _cacheMode = state.homeListMode;
    _cacheQuery = state.query;
    _cacheLocale = l10n.localeName;
    _cacheDay = today;
    return _cachedGroups = _computeGroups(l10n);
  }

  List<_HistoryGroup> _computeGroups(AppLocalizations l10n) {
    final filtered = _filteredHistoryItems(widget.state.homeListMode, l10n);
    final groups = <String, _HistoryGroup>{};
    for (final item in filtered) {
      final day = DateUtils.dateOnly(item.occurredAt.toLocal());
      final key = DateFormat('yyyy-MM-dd', 'en').format(day);
      (groups[key] ??= _HistoryGroup(key, day, l10n)).items.add(item);
    }
    _dayKeys.removeWhere((key, _) => !groups.containsKey(key));
    for (final key in groups.keys) {
      _dayKeys.putIfAbsent(key, GlobalKey.new);
    }
    return groups.values.toList();
  }

  /// Scroll listeners run before the viewport lays out for the new offset, so
  /// day positions are measured after the frame, once per frame.
  void _scheduleActiveDayUpdate() {
    if (_activeDayPending) return;
    _activeDayPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeDayPending = false;
      _updateActiveDay();
    });
  }

  void _updateActiveDay() {
    if (!mounted || !_scroll.hasClients) return;
    final viewport = _viewport.currentContext?.findRenderObject();
    final groups = _cachedGroups;
    if (viewport is! RenderBox || !viewport.hasSize || groups == null) return;
    final edge = viewport.localToGlobal(Offset.zero).dy + 84;
    var active = 0;
    for (var i = 0; i < groups.length; i++) {
      // The key sits on a box inside the day's sliver; the sliver's own
      // render object is not a RenderBox and has no global position.
      final object = _dayKeys[groups[i].key]?.currentContext
          ?.findRenderObject();
      if (object is! RenderBox || !object.attached || !object.hasSize) {
        continue;
      }
      if (object.localToGlobal(Offset.zero).dy <= edge) {
        active = i;
      } else {
        break;
      }
    }
    if (active != _activeDay) {
      setState(() => _activeDay = active);
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActiveChip());
    }
  }

  /// Keeps the highlighted day inside the timeline strip, which scrolls on its
  /// own when there are more days than fit.
  void _revealActiveChip() {
    if (!mounted || !_timelineScroll.hasClients) return;
    final position = _timelineScroll.position;
    final top = _activeDay * _timelineChipExtent;
    final bottom = top + _timelineChipExtent + 12;
    if (top < position.pixels) {
      _timelineScroll.jumpTo(top.clamp(0.0, position.maxScrollExtent));
    } else if (bottom > position.pixels + position.viewportDimension) {
      _timelineScroll.jumpTo(
        (bottom - position.viewportDimension).clamp(
          0.0,
          position.maxScrollExtent,
        ),
      );
    }
  }

  void _jumpTo(int index, List<_HistoryGroup> groups) {
    if (index < 0 || index >= groups.length) return;
    final ctx = _dayKeys[groups[index].key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: .04,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    if (state.homeListMode == HomeListMode.online && state.comparison != null) {
      return _comparison(context, l10n, state.comparison!);
    }
    final groups = _groups(l10n);
    return Stack(
      key: _viewport,
      children: [
        CustomScrollView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _searchHeader(context, l10n, state),
              ),
            ),
            if (state.homeListMode != HomeListMode.online)
              ..._historySlivers(context, l10n, state, groups),
            if (state.homeListMode == HomeListMode.online)
              ..._onlineSlivers(context, l10n, state),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        if (state.homeListMode == HomeListMode.recent && groups.isNotEmpty)
          PositionedDirectional(
            end: 4,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_timelineVisible,
              child: ExcludeSemantics(
                excluding: !_timelineVisible,
                child: AnimatedOpacity(
                  opacity: _timelineVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: _timeline(context, l10n, groups),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchHeader(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _query,
              focusNode: _queryFocus,
              scrollController: _queryScroll,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              onChanged: widget.controller.setQuery,
              onSubmitted: (_) => _submitSearch(),
              decoration: InputDecoration(
                hintText: state.homeListMode == HomeListMode.online
                    ? l10n.searchCatalogHint
                    : l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.text.isNotEmpty)
                      IconButton(
                        tooltip: l10n.accessibilityClearSearch,
                        onPressed: () {
                          _query.clear();
                          widget.controller.setQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                      TextButton(
                        onPressed: _submitSearch,
                        child: Text(l10n.searchSubmit),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.searchFilters,
            onPressed: widget.controller.toggleSearchFilters,
            icon: Icon(
              Icons.tune_rounded,
              color: state.searchFiltersExpanded
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
        ],
      ),
      if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: _submitSearch,
            icon: const Icon(Icons.search_rounded),
            label: Text(l10n.searchSubmit),
          ),
        ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 180),
        crossFadeState: state.searchFiltersExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: const SizedBox(width: double.infinity),
        secondChild: _searchFilters(context, l10n, state),
      ),
      const SizedBox(height: 14),
      _HomeModeSelector(
        selected: state.homeListMode,
        onChanged: widget.controller.setHomeListMode,
        labels: [
          '${l10n.searchRecentTab} (${_filteredHistoryItems(HomeListMode.recent, l10n).length})',
          '${l10n.searchFavoritesTab} (${_filteredHistoryItems(HomeListMode.favorites, l10n).length})',
          '${l10n.searchOnlineTab} (${state.comparison == null ? state.autocomplete.length : 1})',
        ],
      ),
    ],
  );

  Widget _searchFilters(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
  ) {
    final catalogSearch =
        state.homeListMode == HomeListMode.online && state.comparison == null;
    final comparison =
        state.homeListMode == HomeListMode.online && state.comparison != null;
    final fields = [
      DropdownMenuItem(value: 'all', child: Text(l10n.searchFilterAll)),
      DropdownMenuItem(value: 'title', child: Text(l10n.searchFilterTitle)),
      DropdownMenuItem(value: 'artist', child: Text(l10n.searchFilterArtist)),
      if (!catalogSearch)
        DropdownMenuItem(value: 'lyrics', child: Text(l10n.searchFilterLyrics)),
    ];
    final selectedField =
        fields.any((item) => item.value == state.searchFilters.field)
        ? state.searchFilters.field
        : 'all';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!comparison)
            DropdownButtonFormField<String>(
              initialValue: selectedField,
              decoration: InputDecoration(labelText: l10n.searchMetadata),
              items: fields,
              onChanged: (value) {
                if (value != null) {
                  widget.controller.setSearchFilter('field', value);
                }
              },
            ),
          if (catalogSearch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.searchCatalogFilterHint,
                key: const ValueKey('online-filter-limit-hint'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (!catalogSearch) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: Text(l10n.searchFilterChords),
                  selected: state.searchFilters.chordsOnly,
                  onSelected: (value) =>
                      widget.controller.setSearchFilter('chordsOnly', value),
                ),
                FilterChip(
                  label: Text(l10n.searchFilterTimed),
                  selected: state.searchFilters.timedOnly,
                  onSelected: (value) =>
                      widget.controller.setSearchFilter('timedOnly', value),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: state.searchFilters.language,
              decoration: InputDecoration(labelText: l10n.searchFilterLanguage),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.searchFilterAll)),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'bg', child: Text('Български')),
                const DropdownMenuItem(value: 'uk', child: Text('Українська')),
              ],
              onChanged: (value) =>
                  widget.controller.setSearchFilter('language', value ?? ''),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _historySlivers(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
    List<_HistoryGroup> groups,
  ) {
    final favorites = state.homeListMode == HomeListMode.favorites;
    final hasItems = groups.isNotEmpty;
    final out = <Widget>[];
    if (!favorites && state.recent.isNotEmpty) {
      out.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () =>
                    confirmClearHistory(context, widget.controller),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: Text(l10n.homeHistoryClear),
              ),
            ),
          ),
        ),
      );
    }
    if (!hasItems) {
      out.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: VerseEmptyState(
            icon: favorites
                ? Icons.favorite_border_rounded
                : Icons.history_rounded,
            title: favorites ? l10n.homeFavoritesEmpty : l10n.homeRecentEmpty,
          ),
        ),
      );
      return out;
    }
    for (final group in groups) {
      out.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Padding(
              key: _dayKeys[group.key],
              padding: const EdgeInsets.fromLTRB(3, 14, 3, 3),
              child: Text(
                group.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
      out.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: group.items.length,
            itemBuilder: (context, index) =>
                _recentRow(context, l10n, group.items[index]),
            separatorBuilder: (_, _) => const Divider(indent: 60),
          ),
        ),
      );
    }
    if (state.recentHasMore && !favorites) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: state.loadingMoreRecent
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () =>
                          unawaited(widget.controller.loadMoreRecent()),
                      child: Text(l10n.homeAllHistory),
                    ),
            ),
          ),
        ),
      );
    }
    return out;
  }

  Widget _recentRow(
    BuildContext context,
    AppLocalizations l10n,
    RecentItemData item,
  ) {
    return Row(
      key: ValueKey(
        item.isSetlist
            ? 'recent-setlist-row-${item.id}'
            : 'recent-row-${item.id}',
      ),
      children: [
        Expanded(
          child: InkWell(
            onTap: () => item.isSetlist
                ? widget.controller.openSetlist(item.id)
                : widget.controller.openSong(item.id),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  if (item.isSetlist)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else
                    VerseArtwork(url: item.artworkUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.isSetlist
                              ? l10n.setlistSongsCount(item.playCount)
                              : [
                                      item.artist,
                                      item.subtitle,
                                      if (item.playCount > 0)
                                        l10n.songsUsageCount(item.playCount),
                                    ]
                                    .where((value) => value.isNotEmpty)
                                    .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        VerseIconButton(
          icon: item.favorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: item.favorite
              ? (item.isSetlist
                    ? l10n.setlistFavoriteRemove
                    : l10n.songFavoriteRemove)
              : (item.isSetlist
                    ? l10n.setlistFavoriteAdd
                    : l10n.songFavoriteAdd),
          selected: item.favorite,
          onPressed: () => item.isSetlist
              ? widget.controller.toggleSetlistFavorite(item.id)
              : widget.controller.toggleSongFavorite(item.id),
        ),
        PopupMenuButton<String>(
          tooltip: item.isSetlist
              ? l10n.accessibilitySetlistMenu(item.title)
              : l10n.accessibilitySongMenu(item.title),
          icon: const Icon(Icons.more_horiz_rounded),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share',
              child: Text(
                item.isSetlist ? l10n.setlistShare : l10n.settingsShareSong,
              ),
            ),
            PopupMenuItem(
              value: 'share_pdf',
              child: Text(l10n.settingsSharePdf),
            ),
            PopupMenuItem(
              value: 'print',
              child: Text(
                item.isSetlist ? l10n.setlistPrint : l10n.settingsPrintSong,
              ),
            ),
            if (!item.isSetlist)
              PopupMenuItem(value: 'copy', child: Text(l10n.settingsCopySong)),
            if (item.isSetlist)
              PopupMenuItem(value: 'copy', child: Text(l10n.settingsCopySong)),
          ],
          onSelected: (action) => _recentAction(item, action),
        ),
      ],
    );
  }

  void _recentAction(RecentItemData item, String action) {
    if (item.isSetlist) {
      if (action == 'share') widget.controller.shareSetlist(item.id);
      if (action == 'share_pdf') {
        widget.controller.shareSetlistPdf(item.id);
      }
      if (action == 'print') widget.controller.printSetlist(item.id);
      if (action == 'copy') widget.controller.copySetlist(item.id);
    } else {
      if (action == 'share') widget.controller.shareSong(item.id);
      if (action == 'share_pdf') widget.controller.shareSongPdf(item.id);
      if (action == 'print') widget.controller.printSong(item.id);
      if (action == 'copy') widget.controller.copySongChordPro(item.id);
    }
  }

  List<Widget> _onlineSlivers(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
  ) {
    final out = <Widget>[];
    if (state.query.trim().length < 2 && state.comparison == null) {
      out.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: VerseEmptyState(
            icon: Icons.search_rounded,
            title: l10n.searchCatalogEmptyQuery,
          ),
        ),
      );
      return out;
    }
    if (state.searchState == LoadState.loading) {
      out.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.searchLoading),
              ],
            ),
          ),
        ),
      );
      return out;
    }
    if (state.searchError != null || state.searchState == LoadState.failed) {
      out.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: VerseEmptyState(
            icon: Icons.wifi_off_rounded,
            title: l10n.searchError,
            message: l10n.searchErrorDetails,
            actionLabel: l10n.actionRetry,
            onAction: _submitSearch,
          ),
        ),
      );
      return out;
    }
    if (state.comparison != null) {
      out.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _comparison(context, l10n, state.comparison!),
          ),
        ),
      );
      return out;
    }
    if (state.autocomplete.isEmpty) {
      out.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: VerseEmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.searchResultCount(0),
            message: l10n.searchNoResults,
          ),
        ),
      );
      return out;
    }
    out.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: state.autocomplete.length,
          itemBuilder: (context, index) {
            final item = state.autocomplete[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              leading: VerseArtwork(url: item.artworkUrl, size: 44),
              title: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.album?.isNotEmpty == true ||
                      item.durationSeconds != null)
                    Text(
                      [
                        if (item.album?.isNotEmpty == true) item.album!,
                        if (item.durationSeconds != null)
                          formatDuration(item.durationSeconds!),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: Tooltip(
                message: l10n.searchViewVersions,
                child: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                ),
              ),
              onTap: () => _openReference(item),
            );
          },
          separatorBuilder: (_, _) => const Divider(indent: 60),
        ),
      ),
    );
    return out;
  }

  String _sourceName(AppLocalizations l10n, SourceVersionData version) =>
      versionName(l10n, version);

  void _openFullPreview() {
    final selected = widget.controller.state.comparison?.selected;
    if (selected != null) {
      widget.controller.selectVersion(
        selected.sourceCount == 1 && selected.underlyingSourceId != null
            ? selected.underlyingSourceId!
            : selected.id,
      );
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SourcePreviewScreen(controller: widget.controller),
      ),
    );
  }

  Widget _comparison(
    BuildContext context,
    AppLocalizations l10n,
    SearchComparisonData comparison,
  ) {
    final chosen = comparison.selected;
    // Keep unavailable and checking versions in place, so finishing a check
    // cannot move a different row under the user's finger.
    final allVersions = comparisonVersions(comparison);
    final versions = allVersions;
    final selectedRowId = chosen?.id;
    final usable = versions
        .where(
          (item) =>
              item.isUsableVersion ||
              (item.id == comparison.suggested?.id && item.hasLyrics),
        )
        .toList();
    final colors = Theme.of(context).colorScheme;
    final count = allVersions
        .where((item) => item.providerId != 'combined' && item.isUsableVersion)
        .length;
    final checked = comparison.providerChecks
        .where((item) => item.state != 'pending')
        .length;
    final reference = comparison.reference;
    final list = ListView(
      key: const PageStorageKey('version-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        Padding(
          key: const ValueKey('home-search-comparison-counts'),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            l10n.searchSourceVersionsCount(count),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        if (usable.isEmpty &&
            !comparison.discovering &&
            !comparison.noUsableLyrics &&
            comparison.discoveryError == null)
          VerseEmptyState(
            key: const ValueKey('version-filters-empty'),
            icon: Icons.filter_alt_off_outlined,
            title: l10n.emptyFiltered,
            actionLabel: l10n.actionClear,
            onAction: () {
              widget.controller.setSearchFilter('chordsOnly', false);
              widget.controller.setSearchFilter('timedOnly', false);
              widget.controller.setSearchFilter('language', '');
              widget.controller.setSearchFilter('durationBucket', '');
            },
          ),
        for (final version in versions)
          _sourceVersionCard(
            context,
            l10n,
            version,
            suggested: version.id == comparison.suggested?.id,
            selected: version.id == selectedRowId,
            onSelect: () => widget.controller.selectVersion(version.id),
          ),
        _discoveryStatus(context, l10n, comparison),
      ],
    );
    final footer = chosen == null
        ? const SizedBox.shrink()
        : _versionFooter(context, l10n, chosen);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
          child: Row(
            children: [
              VerseArtwork(url: reference.artworkUrl, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reference.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        reference.artist,
                        if (reference.album?.isNotEmpty == true)
                          reference.album!,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.searchFilters,
                onPressed: widget.controller.toggleSearchFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
        ),
        if (widget.state.searchFiltersExpanded)
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _searchFilters(context, l10n, widget.state),
              ),
            ),
          ),
        if (comparison.discovering) ...[
          const LinearProgressIndicator(
            key: ValueKey('discovery-progress'),
            minHeight: 2,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              l10n.searchDiscoveryProgress(
                checked,
                comparison.providerChecks.length,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 700 || constraints.maxHeight < 340) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: list),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(child: footer),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: list),
                  footer,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _versionFooter(
    BuildContext context,
    AppLocalizations l10n,
    SourceVersionData version,
  ) {
    final colors = Theme.of(context).colorScheme;
    final compact =
        MediaQuery.sizeOf(context).height < 600 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final preview = version.bodyPreview
        .where((line) => line.text.trim().isNotEmpty)
        .take(compact ? 1 : 3);
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('version-selection-footer'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.searchSelectedPreview} · ${_sourceName(l10n, version)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.primary),
                  ),
                ),
                TextButton(
                  key: const ValueKey('open-full-preview'),
                  onPressed: _openFullPreview,
                  child: Text(l10n.searchFullPreview),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final line in preview)
              Text.rich(
                TextSpan(
                  children: [
                    if (line.chords.isNotEmpty)
                      TextSpan(
                        text:
                            '${line.chords.map((chord) => chord.symbol).join('  ')}  ',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    TextSpan(text: line.text),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (preview.isEmpty) Text(l10n.searchPreviewUnavailable),
            if (version.isChecking) Text(l10n.searchVersionChecking),
            if (!version.isChecking &&
                !version.isUsableVersion &&
                version.id != 'combined')
              Text(l10n.searchVersionUnavailable),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('save-open-lyrics'),
              onPressed: version.canSave || version.savedSongId != null
                  ? widget.controller.saveSelectedVersion
                  : null,
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(
                version.savedSongId != null
                    ? l10n.searchOpenLyrics
                    : l10n.searchSaveOpenLyrics,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discoveryStatus(
    BuildContext context,
    AppLocalizations l10n,
    SearchComparisonData comparison,
  ) {
    final unavailable = comparison.providerChecks
        .where(
          (check) => check.state == 'failed' || check.state == 'unavailable',
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comparison.discoveryError != null ||
            (!comparison.discovering && comparison.noUsableLyrics))
          VerseEmptyState(
            key: ValueKey(
              comparison.discoveryError != null
                  ? 'discovery-error'
                  : 'discovery-no-lyrics',
            ),
            icon: Icons.lyrics_outlined,
            title: comparison.discoveryError != null
                ? l10n.searchDiscoveryError
                : l10n.searchDiscoveryNoLyrics,
            message: comparison.discoveryError != null
                ? l10n.searchErrorDetails
                : l10n.searchDiscoveryNoLyricsDetails,
            actionLabel: l10n.searchDiscoveryRetry,
            onAction: () =>
                unawaited(widget.controller.retrySelectedSongDiscovery()),
          ),
        if (comparison.providerChecks.isNotEmpty)
          ExpansionTile(
            key: const PageStorageKey('discovery-provider-checks'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              l10n.searchProviderChecks,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
              if (unavailable > 0)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(l10n.searchSourcesUnavailableCount(unavailable)),
                ),
              for (final check in comparison.providerChecks)
                ListTile(
                  key: ValueKey('discovery-provider-${check.id}'),
                  dense: true,
                  title: Text(check.name),
                  subtitle: Text(_providerCheckLabel(l10n, check.state)),
                ),
            ],
          ),
      ],
    );
  }

  String _providerCheckLabel(AppLocalizations l10n, String state) =>
      switch (state) {
        'pending' => l10n.searchProviderPending,
        'found' => l10n.searchProviderFound,
        'rejected' => l10n.searchProviderRejected,
        'failed' => l10n.searchProviderFailed,
        'unavailable' => l10n.searchProviderUnavailable,
        _ => l10n.searchProviderUnavailable,
      };

  Widget _sourceVersionCard(
    BuildContext context,
    AppLocalizations l10n,
    SourceVersionData version, {
    required bool suggested,
    bool selected = false,
    VoidCallback? onSelect,
  }) {
    final colors = Theme.of(context).colorScheme;
    final detail = [
      if (version.album?.trim().isNotEmpty == true &&
          version.album!.toLowerCase() != 'unknown')
        version.album!,
      if (version.durationSeconds != null)
        formatDuration(version.durationSeconds!),
    ].join(' · ');
    return Semantics(
      selected: selected,
      button: onSelect != null,
      child: Card(
        key: ValueKey('version-row-${version.id}'),
        margin: const EdgeInsets.only(bottom: 6),
        color: selected ? colors.primaryContainer.withValues(alpha: .3) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : .5,
          ),
        ),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: onSelect == null ? colors.outline : colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sourceName(l10n, version),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children: [
                          if (version.hasChords)
                            _FactPill(
                              icon: Icons.music_note_rounded,
                              label: l10n.providerCapabilityChords,
                            ),
                          _FactPill(
                            icon: version.hasTiming
                                ? Icons.schedule_rounded
                                : Icons.lyrics_outlined,
                            label: version.hasTiming
                                ? l10n.playerTimedLyrics
                                : l10n.providerCapabilityLyrics,
                          ),
                          if (suggested)
                            Text(
                              l10n.searchSuggested,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.primary),
                            ),
                        ],
                      ),
                      if ((version.sourceCount ?? 0) > 1) ...[
                        const SizedBox(height: 4),
                        SourceContributions(version: version),
                      ] else if (!version.sameRecording &&
                          version.matchSummary.isNotEmpty)
                        Text(
                          localizedMatchReason(l10n, version.matchSummary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      if (version.isChecking)
                        Text(
                          l10n.searchVersionChecking,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (!version.isChecking &&
                          !version.isUsableVersion &&
                          version.id != 'combined')
                        Text(
                          l10n.searchVersionUnavailable,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeline(
    BuildContext context,
    AppLocalizations l10n,
    List<_HistoryGroup> groups,
  ) => Container(
    key: const ValueKey('recent-history-timeline'),
    width: 63,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .91),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .5),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ListView.builder(
      controller: _timelineScroll,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemExtent: _timelineChipExtent,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final date = formatLocalizedDate(
          DateFormat.MMMd,
          group.date,
          Localizations.localeOf(context).toString(),
        );
        return Semantics(
          label: l10n.accessibilityTimeline(date),
          button: true,
          selected: index == _activeDay,
          child: InkWell(
            onTap: () => _jumpTo(index, groups),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              key: ValueKey('timeline-day-$index'),
              height: _timelineChipExtent,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: index == _activeDay
                  ? BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: .8),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: index == _activeDay
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: index == _activeDay
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Height of a day chip in the history timeline (a 48dp touch target).
const _timelineChipExtent = 48.0;

class _HomeModeSelector extends StatefulWidget {
  const _HomeModeSelector({
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  final HomeListMode selected;
  final ValueChanged<HomeListMode> onChanged;
  final List<String> labels;

  @override
  State<_HomeModeSelector> createState() => _HomeModeSelectorState();
}

class _HomeModeSelectorState extends State<_HomeModeSelector> {
  final _scroll = ScrollController();
  final _segmentKeys = HomeListMode.values
      .map((_) => GlobalKey())
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(covariant _HomeModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _revealSelected() {
    if (!mounted || !_scroll.hasClients) return;
    final context = _segmentKeys[widget.selected.index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 160),
      alignment: .5,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final modes = HomeListMode.values;
    final rowWidth = modes.indexed.fold<double>(0, (width, entry) {
      final index = entry.$1;
      final painter = TextPainter(
        text: TextSpan(text: widget.labels[index], style: textStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final labelWidth = painter.width;
      painter.dispose();
      return width + labelWidth + 32 + (index == 0 ? 0 : 1);
    });

    Widget segment(int index, {required bool wrapped}) {
      final selected = modes[index] == widget.selected;
      return KeyedSubtree(
        key: ValueKey('home-mode-${modes[index].name}'),
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            key: _segmentKeys[index],
            borderRadius: BorderRadius.circular(24),
            onTap: () => widget.onChanged(modes[index]),
            child: AnimatedContainer(
              key: ValueKey('home-mode-${modes[index].name}-$wrapped'),
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 48),
              padding: EdgeInsets.symmetric(horizontal: wrapped ? 12 : 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.primaryContainer : Colors.transparent,
                borderRadius: wrapped ? BorderRadius.circular(24) : null,
                border: wrapped
                    ? Border.all(color: colors.outlineVariant)
                    : index == 0
                    ? null
                    : BorderDirectional(
                        start: BorderSide(color: colors.outlineVariant),
                      ),
              ),
              child: Text(
                widget.labels[index],
                maxLines: 1,
                softWrap: false,
                style: textStyle?.copyWith(
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (rowWidth > constraints.maxWidth) {
          return Wrap(
            key: const ValueKey('home-mode-scroll'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < modes.length; index++)
                segment(index, wrapped: true),
            ],
          );
        }
        return SingleChildScrollView(
          key: const ValueKey('home-mode-scroll'),
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < modes.length; index++)
                  segment(index, wrapped: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryGroup {
  _HistoryGroup(this.key, this.date, AppLocalizations l10n)
    : label = DateUtils.isSameDay(date, DateTime.now())
          ? l10n.dateToday
          : DateUtils.isSameDay(
              date,
              DateTime.now().subtract(const Duration(days: 1)),
            )
          ? l10n.dateYesterday
          : formatLocalizedDate(DateFormat.yMMMMd, date, l10n.localeName);
  final String key;
  final DateTime date;
  final String label;
  final List<RecentItemData> items = [];
}

class _FactPill extends StatelessWidget {
  const _FactPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13),
      const SizedBox(width: 3),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
