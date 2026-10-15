import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../library_actions.dart';
import '../verse_ui_state.dart';
import '../widgets/subpage_header.dart';
import '../widgets/verse_components.dart';

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
    final needle = _query.toLowerCase();
    final lists = state.setlists
        .where(
          (value) =>
              '${value.title} ${value.notes}'.toLowerCase().contains(needle),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.accessibilityClearSearch,
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: l10n.setlistCreate,
                onPressed: () =>
                    widget.controller.createSetlist(name: l10n.setlistCreate),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: lists.isEmpty
              ? VerseEmptyState(
                  icon: Icons.queue_music_rounded,
                  title: state.setlists.isEmpty
                      ? l10n.setlistsEmpty
                      : l10n.setlistsEmptySearch,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 640;
                    final columns = wide ? 2 : 1;
                    final cardWidth = wide
                        ? (constraints.maxWidth - 40) / 2
                        : constraints.maxWidth - 32;
                    return ListView.builder(
                      key: wide ? const ValueKey('tablet-setlists-grid') : null,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: (lists.length + columns - 1) ~/ columns,
                      itemBuilder: (context, rowIndex) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(columns, (column) {
                            final index = rowIndex * columns + column;
                            return Padding(
                              padding: EdgeInsets.only(
                                right: column == 0 && wide ? 8 : 0,
                              ),
                              child: SizedBox(
                                width: cardWidth.toDouble(),
                                child: index < lists.length
                                    ? _setlistCard(context, l10n, lists[index])
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => controller.openSetlist(value.id),
                    child: Text(
                      value.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .72,
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'share',
                      child: Text(l10n.setlistShare),
                    ),
                    PopupMenuItem(
                      value: 'share_pdf',
                      child: Text(l10n.setlistSharePdf),
                    ),
                    PopupMenuItem(
                      value: 'print',
                      child: Text(l10n.setlistPrint),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Text(l10n.settingsCopySong),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(l10n.actionDuplicate),
                    ),
                    PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.actionDelete),
                    ),
                  ],
                  onSelected: (action) => handleSetlistAction(
                    context,
                    controller,
                    value.id,
                    action,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => setState(
                () => expanded
                    ? _expanded.remove(value.id)
                    : _expanded.add(value.id),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.setlistSongsCount(value.songTitles.length)}  ·  ${l10n.setlistDurationUnknown}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
            if (preview.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AnimatedOpacity(
                  opacity: expanded ? 1 : .72,
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    preview.map((song) => '•  $song').join('\n'),
                    maxLines: expanded ? null : 2,
                    overflow: expanded
                        ? TextOverflow.visible
                        : TextOverflow.fade,
                    style: Theme.of(context).textTheme.bodySmall,
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
  late final TextEditingController _notes;
  String? _loadedSetlistId;
  VerseUiController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final value = controller.state.activeSetlist;
    _loadedSetlistId = value?.id;
    _name = TextEditingController(text: value?.title ?? '');
    _notes = TextEditingController(text: value?.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant SetlistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = controller.state.activeSetlist;
    if (value != null && value.id != _loadedSetlistId) {
      _loadedSetlistId = value.id;
      _name.text = value.title;
      _notes.text = value.notes;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Text typed into the open editing form, or null when not editing, so
  /// reordering or removing songs saves it together with the change.
  String? _typedName(bool editing) => editing ? _name.text : null;
  String? _typedNotes(bool editing) => editing ? _notes.text : null;

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
          onBack: controller.back,
          actions: [
            if (editing)
              IconButton(
                tooltip: l10n.actionSave,
                onPressed: () => controller.saveSetlistDetails(
                  name: _name.text,
                  notes: _notes.text,
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
              itemBuilder: (_) => [
                PopupMenuItem(value: 'share', child: Text(l10n.setlistShare)),
                PopupMenuItem(
                  value: 'share_pdf',
                  child: Text(l10n.setlistSharePdf),
                ),
                PopupMenuItem(value: 'print', child: Text(l10n.setlistPrint)),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.setlistDuplicate),
                ),
                PopupMenuItem(value: 'delete', child: Text(l10n.actionRemove)),
                PopupMenuItem(
                  value: 'copy',
                  child: Text(l10n.settingsCopySong),
                ),
              ],
              onSelected: (action) =>
                  handleSetlistAction(context, controller, value.id, action),
            ),
          ],
        ),
        if (editing)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l10n.setlistNameHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: l10n.setlistNotes),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: value.entries.isEmpty
              ? VerseEmptyState(
                  icon: Icons.queue_music_rounded,
                  title: l10n.setlistSongsEmpty,
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  itemCount: value.entries.length,
                  onReorderItem: (oldIndex, newIndex) async {
                    final entries = [...value.entries];
                    final item = entries.removeAt(oldIndex);
                    entries.insert(newIndex, item);
                    await controller.saveSetlistDetails(
                      name: editing ? _name.text : value.title,
                      notes: editing ? _notes.text : value.notes,
                      entryOrder: [for (final entry in entries) entry.id],
                    );
                  },
                  itemBuilder: (context, index) => _entryTile(
                    context,
                    l10n,
                    value,
                    value.entries[index],
                    index,
                    editing,
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

  Widget _entryTile(
    BuildContext context,
    AppLocalizations l10n,
    SetlistCardData value,
    SetlistEntryData entry,
    int index,
    bool editing,
  ) {
    final title = entry.missing ? l10n.setlistSongMissing : entry.title;
    return ListTile(
      key: ValueKey(entry.id),
      leading: Text(
        '${index + 1}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      title: Text(title),
      subtitle: entry.missing || entry.artist.isEmpty
          ? null
          : Text(entry.artist),
      onTap: entry.missing
          ? null
          : () => controller.openSetlistEntry(value.id, entry.id),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!entry.missing)
            PopupMenuButton<String>(
              tooltip: l10n.navMore,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'override',
                  child: Text(l10n.setlistEntryOverride),
                ),
              ],
              onSelected: (_) => editEntryOverrides(
                context,
                controller,
                value.id,
                entry,
                name: _typedName(editing),
                notes: _typedNotes(editing),
              ),
            ),
          IconButton(
            tooltip: l10n.setlistRemoveSong(title),
            onPressed: () => controller.removeSetlistEntry(
              value.id,
              entry.id,
              name: _typedName(editing),
              notes: _typedNotes(editing),
            ),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          ReorderableDragStartListener(
            key: ValueKey('setlist-entry-drag-${entry.id}'),
            index: index,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: Icon(Icons.drag_handle_rounded)),
            ),
          ),
        ],
      ),
    );
  }
}
