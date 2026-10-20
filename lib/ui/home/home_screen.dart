import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../library_actions.dart';
import '../library/songs_screen.dart';
import '../library/collation.dart';
import '../verse_ui_state.dart';
import '../widgets/verse_components.dart';
import 'source_preview_screen.dart';
import 'source_version_browser.dart';

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
  bool? _cacheFavoritesOnly;
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

  List<RecentItemData> _historyItemsForMode(HomeListMode mode) {
    if (mode == HomeListMode.recent) {
      return widget.state.recent
          .where((item) => !item.isSetlist)
          .where((item) => !widget.state.favoritesOnly || item.favorite)
          .toList();
    }
    return const [];
  }

  List<RecentItemData> _filteredHistoryItems(HomeListMode mode) {
    final query = foldForSearch(widget.state.query);
    final items = _historyItemsForMode(mode);
    if (query.isEmpty) return items;
    return items
        .where(
          (item) => foldForSearch(
            '${item.title} ${item.artist} ${item.subtitle}',
          ).contains(query),
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
        _cacheFavoritesOnly == state.favoritesOnly &&
        _cacheQuery == state.query &&
        _cacheLocale == l10n.localeName &&
        _cacheDay == today) {
      return cached;
    }
    _cacheRecent = state.recent;
    _cacheSongs = state.songs;
    _cacheSetlists = state.setlists;
    _cacheMode = state.homeListMode;
    _cacheFavoritesOnly = state.favoritesOnly;
    _cacheQuery = state.query;
    _cacheLocale = l10n.localeName;
    _cacheDay = today;
    return _cachedGroups = _computeGroups(l10n);
  }

  List<_HistoryGroup> _computeGroups(AppLocalizations l10n) {
    final filtered = _filteredHistoryItems(widget.state.homeListMode);
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
    final edge = viewport.localToGlobal(Offset.zero).dy + 12;
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
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: SingleChildScrollView(
              key: const ValueKey('songs-search-header-scroll'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: _searchHeader(context, l10n, state),
              ),
            ),
          ),
          Expanded(
            child: state.homeListMode == HomeListMode.library
                ? SongsScreen(
                    controller: widget.controller,
                    showSearch: false,
                    query: state.query,
                  )
                : Stack(
                    key: _viewport,
                    children: [
                      CustomScrollView(
                        key: PageStorageKey(
                          'songs-${state.homeListMode.name}-scroll',
                        ),
                        controller: _scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          if (state.homeListMode != HomeListMode.online)
                            ..._historySlivers(context, l10n, state, groups),
                          if (state.homeListMode == HomeListMode.online)
                            ..._onlineSlivers(context, l10n, state),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                      if (state.homeListMode == HomeListMode.recent &&
                          groups.isNotEmpty)
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
                  ),
          ),
        ],
      ),
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
                    IconButton(
                      tooltip: l10n.searchSubmit,
                      onPressed: _submitSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!state.songsConflictFilter)
            VerseIconButton(
              key: const ValueKey('favorites-filter-button'),
              tooltip: l10n.searchFavoritesTab,
              selected: state.favoritesOnly,
              onPressed: () =>
                  widget.controller.setFavoritesOnly(!state.favoritesOnly),
              icon: state.favoritesOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
        ],
      ),
      const SizedBox(height: 14),
      _HomeModeSelector(
        selected: state.homeListMode,
        modes: const [
          HomeListMode.recent,
          HomeListMode.library,
          HomeListMode.online,
        ],
        onChanged: widget.controller.setHomeListMode,
        labels: [
          '${l10n.searchRecentTab}(${_filteredHistoryItems(HomeListMode.recent).length})',
          '${l10n.songsLibraryView}(${_libraryCount(state)})',
          '${l10n.searchOnlineTab}(${state.comparison == null ? state.autocomplete.length : 1})',
        ],
      ),
    ],
  );

  int _libraryCount(VerseUiState state) {
    final query = foldForSearch(state.query);
    return state.songs
        .where(
          (song) =>
              (!state.songsConflictFilter || song.isConflictCopy) &&
              (state.songsConflictFilter ||
                  !state.favoritesOnly ||
                  song.favorite) &&
              foldForSearch(
                '${song.title} ${song.artist} ${song.album ?? ''}',
              ).contains(query),
        )
        .length;
  }

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
    final favorites = state.favoritesOnly;
    final hasItems = groups.isNotEmpty;
    final out = <Widget>[];
    if (!hasItems) {
      out.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: VerseEmptyState(
            icon: favorites
                ? Icons.favorite_border_rounded
                : Icons.history_rounded,
            title: favorites ? l10n.homeFavoritesEmpty : l10n.homeRecentEmpty,
            actionLabel: state.recentHasMore ? l10n.homeAllHistory : null,
            onAction: state.recentHasMore && !state.loadingMoreRecent
                ? () => unawaited(widget.controller.loadMoreRecent())
                : null,
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
    if (state.recentHasMore) {
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
          itemBuilder: (_) => buildLibraryActionMenu(
            l10n,
            isSetlist: item.isSetlist,
            actions: item.isSetlist
                ? setlistLibraryActions
                : songLibraryActions,
          ),
          onSelected: (action) => _recentAction(context, item, action),
        ),
      ],
    );
  }

  Future<void> _recentAction(
    BuildContext context,
    RecentItemData item,
    String action,
  ) async {
    if (item.isSetlist) {
      await handleSetlistAction(context, widget.controller, item.id, action);
    } else {
      await handleSongMenuAction(context, widget.controller, item.id, action);
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

  void _openFullPreview() {
    final selected = widget.controller.state.comparison?.selected;
    if (selected != null) {
      widget.controller.selectVersion(versionSelectionId(selected));
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SourcePreviewScreen(controller: widget.controller),
      ),
    );
  }

  void _showVersionFilters() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .55,
          maxChildSize: .9,
          builder: (context, scroll) => AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final state = widget.controller.state;
              final comparison = state.comparison;
              final ready = comparison == null
                  ? 0
                  : comparisonVersions(comparison)
                        .where(
                          (version) =>
                              version.canSave || version.savedSongId != null,
                        )
                        .map(versionSelectionId)
                        .toSet()
                        .length;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 12,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.searchFilters,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('version-filters-done'),
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(l10n.actionDone),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      key: const ValueKey('version-filters-sheet'),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        Text(l10n.searchReadyVersions(ready)),
                        _searchFilters(context, l10n, state),
                        TextButton(
                          key: const ValueKey('version-filters-clear'),
                          onPressed: () {
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
                          child: Text(l10n.actionClear),
                        ),
                      ],
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

  Widget _comparison(
    BuildContext context,
    AppLocalizations l10n,
    SearchComparisonData comparison,
  ) => SourceVersionBrowser(
    key: ValueKey(comparison.reference.id),
    controller: widget.controller,
    onOpenFullScreen: _openFullPreview,
    onFilters: _showVersionFilters,
  );

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
    required this.modes,
    required this.onChanged,
    required this.labels,
  });

  final HomeListMode selected;
  final List<HomeListMode> modes;
  final ValueChanged<HomeListMode> onChanged;
  final List<String> labels;

  @override
  State<_HomeModeSelector> createState() => _HomeModeSelectorState();
}

class _HomeModeSelectorState extends State<_HomeModeSelector> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge;
    Widget segment(int index) {
      final mode = widget.modes[index];
      final selected = mode == widget.selected;
      return KeyedSubtree(
        key: ValueKey('home-mode-${mode.name}'),
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.pressed)
                  ? Colors.transparent
                  : null,
            ),
            onTap: () => widget.onChanged(mode),
            child: AnimatedContainer(
              key: ValueKey('home-mode-${mode.name}-segment'),
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.primaryContainer : Colors.transparent,
                border: index == 0
                    ? null
                    : BorderDirectional(
                        start: BorderSide(color: colors.outlineVariant),
                      ),
              ),
              child: Semantics(
                label: widget.labels[index],
                excludeSemantics: true,
                child: Text(
                  widget.labels[index],
                  textAlign: TextAlign.center,
                  softWrap: true,
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
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                for (var index = 0; index < widget.modes.length; index++)
                  Expanded(child: segment(index)),
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
