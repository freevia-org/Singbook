import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../library_actions.dart';
import '../verse_ui_state.dart';
import '../widgets/subpage_header.dart';
import '../widgets/verse_components.dart';
import 'collation.dart';

class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key, required this.controller});
  final VerseUiController controller;
  @override
  State<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends State<SetlistsScreen> {
  final _search = TextEditingController();
  final _expanded = <String>{};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.controller.state;
    final needle = foldForSearch(_query);
    final lists = state.setlists
        .where((value) => !state.favoritesOnly || value.favorite)
        .where((value) => foldForSearch(value.title).contains(needle))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            tooltip: l10n.accessibilityClearSearch,
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        IconButton(
                          tooltip: l10n.searchSubmit,
                          onPressed: () => FocusScope.of(context).unfocus(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        ),
        Expanded(
          child: lists.isEmpty
              ? Column(
                  children: [
                    Expanded(
                      child: VerseEmptyState(
                        icon: Icons.queue_music_rounded,
                        title: state.setlists.isEmpty
                            ? l10n.setlistsEmpty
                            : l10n.setlistsEmptySearch,
                      ),
                    ),
                    LibraryCreateShortcut(
                      key: const ValueKey('setlists-create-shortcut'),
                      label: l10n.setlistCreate,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      onPressed: () => widget.controller.createSetlist(
                        name: l10n.setlistCreate,
                      ),
                    ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 640;
                    // A lone card should use the available desktop canvas
                    // and stay visually centered instead of occupying only
                    // the first half of an otherwise empty two-column grid.
                    final centeredSingleCard = wide && lists.length == 1;
                    final columns = wide && !centeredSingleCard ? 2 : 1;
                    final cardWidth = centeredSingleCard
                        ? (constraints.maxWidth - 32).clamp(0.0, 960.0)
                        : wide
                        ? (constraints.maxWidth - 40) / 2
                        : constraints.maxWidth - 32;
                    return ListView.builder(
                      key: wide ? const ValueKey('tablet-setlists-grid') : null,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: (lists.length + columns) ~/ columns,
                      itemBuilder: (context, rowIndex) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: centeredSingleCard
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(columns, (column) {
                            final index = rowIndex * columns + column;
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: column == 0 && wide && !centeredSingleCard
                                    ? 8
                                    : 0,
                              ),
                              child: SizedBox(
                                width: cardWidth.toDouble(),
                                child: index < lists.length
                                    ? _setlistCard(context, l10n, lists[index])
                                    : index == lists.length
                                    ? LibraryCreateShortcut(
                                        key: const ValueKey(
                                          'setlists-create-shortcut',
                                        ),
                                        label: l10n.setlistCreate,
                                        onPressed: () =>
                                            widget.controller.createSetlist(
                                              name: l10n.setlistCreate,
                                            ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _setlistCard(
    BuildContext context,
    AppLocalizations l10n,
    SetlistCardData value,
  ) {
    final controller = widget.controller;
    final expanded = _expanded.contains(value.id);
    final titles = [
      for (final title in value.songTitles)
        title.isEmpty ? l10n.setlistSongMissing : title,
    ];
    final preview = expanded ? titles : titles.take(2).toList();
    final formattedDuration = formatDuration(value.durationSeconds);
    final duration = value.durationPartial
        ? l10n.setlistDurationPartial(
            value.durationEstimated ? '~$formattedDuration' : formattedDuration,
          )
        : value.durationEstimated
        ? l10n.playerEstimatedDuration(formattedDuration)
        : l10n.setlistDuration(formattedDuration);
    final summary =
        '${l10n.setlistSongsCount(value.songTitles.length)}  ·  $duration';
    void toggleExpanded() => setState(
      () => expanded ? _expanded.remove(value.id) : _expanded.add(value.id),
    );
    return Card(
      key: ValueKey('setlist-card-${value.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => controller.openSetlist(value.id),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          value.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: value.favorite
                      ? l10n.setlistFavoriteRemove
                      : l10n.setlistFavoriteAdd,
                  onPressed: () => controller.toggleSetlistFavorite(value.id),
                  icon: Icon(
                    value.favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: value.favorite
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.accessibilitySetlistMenu(value.title),
                  icon: const Icon(Icons.more_horiz_rounded),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .72,
                  ),
                  itemBuilder: (_) => buildLibraryActionMenu(
                    l10n,
                    isSetlist: true,
                    actions: setlistLibraryActions,
                  ),
                  onSelected: (action) => handleSetlistAction(
                    context,
                    controller,
                    value.id,
                    action,
                  ),
                ),
              ],
            ),
            Semantics(
              button: true,
              expanded: expanded,
              label: expanded
                  ? l10n.accessibilityCollapseSetlist(value.title)
                  : l10n.accessibilityExpandSetlist(value.title),
              value: [summary, ...preview].join('\n'),
              excludeSemantics: true,
              onTap: toggleExpanded,
              child: InkWell(
                onTap: toggleExpanded,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 8, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (preview.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  expanded
                                      ? preview.indexed
                                            .map(
                                              (entry) =>
                                                  '${entry.$1 + 1}. ${entry.$2}',
                                            )
                                            .join('\n')
                                      : preview.join(' · '),
                                  maxLines: expanded ? null : 1,
                                  overflow: expanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 13, height: 1.15),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetlistDetailScreen extends StatefulWidget {
  const SetlistDetailScreen({super.key, required this.controller});
  final VerseUiController controller;
  @override
  State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  late final TextEditingController _name;
  final GlobalKey _deleteBasketGeometryKey = GlobalKey();
  String? _loadedSetlistId;
  String? _draggingEntryId;
  int? _draggingEntryIndex;
  Offset? _dragPosition;
  bool _deleteBasketDropPending = false;
  bool _wasEditing = false;
  VerseUiController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final value = controller.state.activeSetlist;
    _loadedSetlistId = value?.id;
    _wasEditing = controller.state.editingSetlist;
    _name = TextEditingController(text: value?.title ?? '');
  }

  @override
  void didUpdateWidget(covariant SetlistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = controller.state;
    final value = state.activeSetlist;
    final editing = state.editingSetlist;
    if (value != null) {
      // Reload the title when another setlist opens, when editing starts and
      // while not editing (a sync may have changed it), but never under text
      // being typed, so Save cannot overwrite newer stored data.
      final reload =
          value.id != _loadedSetlistId || (editing && !_wasEditing) || !editing;
      if (reload) {
        _loadedSetlistId = value.id;
        if (_name.text != value.title) _name.text = value.title;
      }
    }
    _wasEditing = editing;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Text typed into the inline title, or null when not editing.
  String? _typedName(bool editing) => editing ? _name.text : null;
  String? _typedNotes(bool editing) =>
      editing ? controller.state.activeSetlist?.notes : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final value = state.activeSetlist;
    if (value == null) return const SizedBox.shrink();
    final editing = state.editingSetlist;
    return Column(
      children: [
        SubpageHeader(
          title: value.title,
          onTitleTap: editing ? null : () => controller.editSetlist(value.id),
          titleWidget: editing
              ? TextField(
                  key: const ValueKey('setlist-name-inline-field'),
                  controller: _name,
                  autofocus: true,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.setlistNameHint,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => controller.saveSetlistDetails(
                    name: _name.text,
                    notes: value.notes,
                    entryOrder: [for (final entry in value.entries) entry.id],
                    finishEditing: true,
                  ),
                )
              : null,
          onBack: controller.back,
          actions: [
            if (editing)
              IconButton(
                tooltip: l10n.actionSave,
                onPressed: () => controller.saveSetlistDetails(
                  name: _name.text,
                  notes: value.notes,
                  entryOrder: [for (final entry in value.entries) entry.id],
                  finishEditing: true,
                ),
                icon: const Icon(Icons.check_rounded),
              )
            else
              IconButton(
                tooltip: l10n.actionEdit,
                onPressed: () => controller.editSetlist(value.id),
                icon: const Icon(Icons.edit_outlined),
              ),
            IconButton(
              tooltip: value.favorite
                  ? l10n.setlistFavoriteRemove
                  : l10n.setlistFavoriteAdd,
              onPressed: () => controller.toggleSetlistFavorite(value.id),
              icon: Icon(
                value.favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.setlistMenuLabel,
              icon: const Icon(Icons.more_horiz_rounded),
              itemBuilder: (_) => buildLibraryActionMenu(
                l10n,
                isSetlist: true,
                actions: editing
                    ? setlistLibraryActions.difference(const {'edit'})
                    : setlistLibraryActions,
              ),
              onSelected: (action) =>
                  handleSetlistAction(context, controller, value.id, action),
            ),
          ],
        ),
        Expanded(
          child: value.entries.isEmpty
              ? VerseEmptyState(
                  icon: Icons.queue_music_rounded,
                  title: l10n.setlistSongsEmpty,
                )
              : Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) => _dragPosition = event.position,
                  onPointerMove: (event) => _dragPosition = event.position,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    buildDefaultDragHandles: false,
                    // Keep a stable child count while dragging. Expanding a new
                    // final child mid-drag can duplicate Flutter's internal
                    // reorder keys on the accessibility test route.
                    itemCount: value.entries.length + 1,
                    onReorderStart: (index) {
                      if (index >= value.entries.length) return;
                      setState(() {
                        _draggingEntryId = value.entries[index].id;
                        _draggingEntryIndex = index;
                        _dragPosition = null;
                        _deleteBasketDropPending = false;
                      });
                    },
                    onReorderEnd: (_) {
                      final dragIndex = _draggingEntryIndex;
                      final deleteDrop = _isPointerOverDeleteBasket();
                      if (deleteDrop &&
                          dragIndex != null &&
                          dragIndex < value.entries.length) {
                        final entry = value.entries[dragIndex];
                        _deleteBasketDropPending = true;
                        if (mounted) setState(_clearDragVisualState);
                        unawaited(
                          _removeEntryFromSetlist(
                            context,
                            value,
                            entry,
                            editing,
                          ),
                        );
                      } else if (mounted) {
                        // This receives a raw insertion slot. Flutter omits
                        // onReorderItem for normalized no-op drops (old+1), so
                        // every non-delete end must clear the drag visuals.
                        setState(_clearDragState);
                      }
                    },
                    onReorderItem: (oldIndex, newIndex) async {
                      if (_deleteBasketDropPending) {
                        _deleteBasketDropPending = false;
                        return;
                      }
                      setState(_clearDragState);
                      if (newIndex >= value.entries.length) return;
                      final entries = [...value.entries];
                      final item = entries.removeAt(oldIndex);
                      entries.insert(newIndex, item);
                      await controller.saveSetlistDetails(
                        name: editing ? _name.text : value.title,
                        notes: value.notes,
                        entryOrder: [for (final entry in entries) entry.id],
                      );
                    },
                    itemBuilder: (context, index) {
                      if (index == value.entries.length) {
                        return _draggingEntryId == null
                            ? const SizedBox.shrink(
                                key: ValueKey('setlist-delete-basket'),
                              )
                            : _deleteBasket(context, l10n);
                      }
                      final entry = value.entries[index];
                      final tile = _entryTile(
                        context,
                        l10n,
                        value,
                        entry,
                        index,
                        editing,
                      );
                      if (defaultTargetPlatform == TargetPlatform.windows) {
                        return _WindowsRowDragStartListener(
                          key: ValueKey(entry.id),
                          index: index,
                          child: tile,
                        );
                      }
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(entry.id),
                        index: index,
                        child: tile,
                      );
                    },
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () =>
                  showAddSongsToSetlist(context, controller, value.id),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.setlistAddSongs),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteBasket(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: const ValueKey('setlist-delete-basket'),
      child: Container(
        key: _deleteBasketGeometryKey,
        height: 64,
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.error.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Text(
              l10n.actionRemove,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPointerOverDeleteBasket() {
    final position = _dragPosition;
    final renderObject = _deleteBasketGeometryKey.currentContext
        ?.findRenderObject();
    if (position == null ||
        renderObject is! RenderBox ||
        !renderObject.hasSize) {
      return false;
    }
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return rect.contains(position);
  }

  void _clearDragState() {
    _clearDragVisualState();
    _deleteBasketDropPending = false;
  }

  void _clearDragVisualState() {
    _draggingEntryId = null;
    _draggingEntryIndex = null;
    _dragPosition = null;
  }

  Future<void> _removeEntryFromSetlist(
    BuildContext context,
    SetlistCardData setlist,
    SetlistEntryData entry,
    bool editing,
  ) async {
    final title = entry.missing
        ? AppLocalizations.of(context).setlistSongMissing
        : entry.title;
    final removed = await controller.removeSetlistEntryWithUndo(
      setlist.id,
      entry.id,
      name: _typedName(editing),
      notes: _typedNotes(editing),
    );
    if (removed == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.setlistEntryRemoved(title)),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => controller.restoreSetlistEntry(removed),
        ),
      ),
    );
  }

  Future<void> _handleEntrySongAction(
    BuildContext context,
    SetlistCardData setlist,
    SetlistEntryData entry,
    bool editing,
    String action,
  ) async {
    if (editing && action == 'edit') {
      final typedName = _name.text.trim();
      final name = typedName.isEmpty ? setlist.title : typedName;
      final notes = setlist.notes;
      if (name != setlist.title || notes != setlist.notes) {
        await controller.saveSetlistDetails(name: name, notes: notes);
        if (!context.mounted) return;
        final saved = controller.state.activeSetlist;
        // A conflict or failed save must leave the typed draft on screen.
        if (saved?.id != setlist.id ||
            saved?.title != name ||
            saved?.notes != notes) {
          return;
        }
      }
    }
    if (!context.mounted) return;
    await handleSongMenuAction(context, controller, entry.songId, action);
  }

  Widget _entryTile(
    BuildContext context,
    AppLocalizations l10n,
    SetlistCardData value,
    SetlistEntryData entry,
    int index,
    bool editing,
  ) {
    final title = entry.missing ? l10n.setlistSongMissing : entry.title;
    final details = <String>[
      if (!entry.missing && entry.artist.isNotEmpty) entry.artist,
      if (!entry.missing && entry.durationSeconds != null)
        formatDuration(entry.durationSeconds!),
      if (entry.keyOverride != null)
        '${l10n.editorKeyField}: ${entry.keyOverride}',
      if (entry.capoOverride != null)
        '${l10n.editorCapoField}: ${entry.capoOverride}',
    ];
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return ListTile(
      dense: !desktop,
      visualDensity: desktop ? VisualDensity.standard : VisualDensity.compact,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 8),
      minLeadingWidth: 24,
      leading: Text(
        '${index + 1}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      title: Text(title),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      onTap: entry.missing
          ? null
          : () => controller.openSetlistEntry(value.id, entry.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: l10n.songMenuLabel,
            icon: const Icon(Icons.more_horiz_rounded),
            itemBuilder: (_) => [
              if (!entry.missing) ...[
                ...buildLibraryActionMenu(
                  l10n,
                  actions: {...songLibraryActions, 'override'},
                ),
              ],
              PopupMenuItem(
                value: 'remove_entry',
                child: Text(l10n.setlistRemoveSong(title)),
              ),
            ],
            onSelected: (action) {
              if (action == 'remove_entry') {
                unawaited(
                  _removeEntryFromSetlist(context, value, entry, editing),
                );
              } else if (action == 'override') {
                editEntryOverrides(
                  context,
                  controller,
                  value.id,
                  entry,
                  name: _typedName(editing),
                  notes: _typedNotes(editing),
                );
              } else {
                unawaited(
                  _handleEntrySongAction(
                    context,
                    value,
                    entry,
                    editing,
                    action,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Mouse drags begin after movement; touch still requires a long press so a
/// swipe can scroll. The gesture arena leaves normal row/menu clicks intact.
class _WindowsRowDragStartListener extends ReorderableDragStartListener {
  const _WindowsRowDragStartListener({
    super.key,
    required super.index,
    required super.child,
  });

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) {
      if (event.buttons != kPrimaryButton) return;
      final MultiDragGestureRecognizer recognizer;
      if (event.kind == PointerDeviceKind.mouse) {
        recognizer = ImmediateMultiDragGestureRecognizer(
          debugOwner: this,
          supportedDevices: const {PointerDeviceKind.mouse},
          allowedButtonsFilter: (buttons) => buttons == kPrimaryButton,
        );
      } else {
        recognizer = DelayedMultiDragGestureRecognizer(debugOwner: this);
      }
      recognizer.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
      final list = SliverReorderableList.maybeOf(context);
      if (list == null) {
        recognizer.dispose();
        return;
      }
      list.startItemDragReorder(
        index: index,
        event: event,
        recognizer: recognizer,
      );
    },
    child: child,
  );
}
