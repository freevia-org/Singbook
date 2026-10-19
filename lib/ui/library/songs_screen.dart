import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../library_actions.dart';
import '../verse_ui_state.dart';
import '../widgets/verse_components.dart';
import 'collation.dart';

/// First character of a title with diacritics folded and upper-cased ("Éclair"
/// is filed under E); `#` for an untitled song. Matches the order of
/// [sortedByTitle], so each letter forms one contiguous section.
String songIndexLetter(String title) => titleIndexLetter(title);

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key, required this.controller});
  final VerseUiController controller;
  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _letterKeys = <String, GlobalKey>{};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  void _jumpToLetter(
    String letter,
    List<SongCardData> songs, {
    bool animate = true,
  }) {
    final index = songs.indexWhere((s) => songIndexLetter(s.title) == letter);
    if (index < 0 || !_scroll.hasClients) return;
    final target = _letterKeys[letter]?.currentContext;
    if (target != null && target.mounted) {
      Scrollable.ensureVisible(
        target,
        duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
        curve: Curves.easeOut,
      );
      return;
    }
    // The section header is not built yet: jump near it using the average row
    // extent, then align precisely once it exists.
    final position = _scroll.position;
    final perSong =
        (position.maxScrollExtent + position.viewportDimension) / songs.length;
    final offset = (index * perSong).clamp(0.0, position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(offset);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final built = _letterKeys[letter]?.currentContext;
      if (mounted && built != null && built.mounted) {
        Scrollable.ensureVisible(built, duration: Duration.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state;
    final l10n = AppLocalizations.of(context);
    final needle = foldForSearch(_query);
    final conflictsOnly = state.songsConflictFilter;
    final songs = sortedByTitle(
      state.songs
          .where((song) => !conflictsOnly || song.isConflictCopy)
          .where(
            (song) => foldForSearch(
              '${song.title} ${song.artist} ${song.album ?? ''}',
            ).contains(needle),
          ),
      (song) => song.title,
    );
    // Letters in list order, so the rail always matches the list.
    final sortedLetters = <String>[];
    for (final song in songs) {
      final letter = songIndexLetter(song.title);
      if (sortedLetters.isEmpty || sortedLetters.last != letter) {
        sortedLetters.add(letter);
      }
    }
    final letters = sortedLetters.toSet();
    _letterKeys.removeWhere((letter, _) => !letters.contains(letter));
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
            ],
          ),
        ),
        if (conflictsOnly)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 12, 4),
            child: Row(
              key: const ValueKey('songs-conflict-filter'),
              children: [
                const Icon(Icons.call_split_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.songsConflictFilterActive)),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: controller.clearConflictFilter,
                  child: Text(l10n.songsConflictFilterClear),
                ),
              ],
            ),
          ),
        Expanded(
          child: songs.isEmpty
              ? VerseEmptyState(
                  icon: Icons.library_music_outlined,
                  title: conflictsOnly && _query.isEmpty
                      ? l10n.songsConflictEmpty
                      : _query.isEmpty
                      ? l10n.songsEmpty
                      : l10n.songsEmptySearch,
                )
              : LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      Expanded(
                        child: constraints.maxWidth >= 640
                            ? GridView.builder(
                                key: const ValueKey('tablet-songs-grid'),
                                controller: _scroll,
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 520,
                                      mainAxisExtent:
                                          112 +
                                          (MediaQuery.textScalerOf(
                                                        context,
                                                      ).scale(16) -
                                                      16)
                                                  .clamp(0.0, double.infinity)
                                                  .toDouble() *
                                              4,
                                    ),
                                itemCount: songs.length,
                                itemBuilder: (context, index) =>
                                    _songListItem(context, l10n, songs, index),
                              )
                            : ListView.builder(
                                controller: _scroll,
                                itemCount: songs.length,
                                itemBuilder: (context, index) =>
                                    _songListItem(context, l10n, songs, index),
                              ),
                      ),
                      if (sortedLetters.length > 5 &&
                          constraints.maxWidth < 640)
                        _LetterRail(
                          letters: sortedLetters,
                          label: l10n.songsAlphabetNavigation,
                          jumpLabel: l10n.songsJumpToLetter,
                          onSelect: (letter, {required bool animate}) =>
                              _jumpToLetter(letter, songs, animate: animate),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _songListItem(
    BuildContext context,
    AppLocalizations l10n,
    List<SongCardData> songs,
    int index,
  ) {
    final controller = widget.controller;
    final song = songs[index];
    final letter = songIndexLetter(song.title);
    final firstOfLetter =
        index == 0 || songIndexLetter(songs[index - 1].title) != letter;
    return Column(
      children: [
        if (firstOfLetter)
          VerseSectionLabel(
            key: _letterKeys.putIfAbsent(letter, GlobalKey.new),
            letter,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SongRow(
            song: song,
            accessibilityLabel: '${song.title}, ${song.artist}',
            favoriteAddLabel: l10n.songFavoriteAdd,
            favoriteRemoveLabel: l10n.songFavoriteRemove,
            menuLabel: l10n.songMenuLabel,
            onOpen: () => controller.openSong(song.id),
            onFavorite: () => controller.toggleSongFavorite(song.id),
            menuWidget: PopupMenuButton<String>(
              tooltip: l10n.songMenuLabel,
              icon: const Icon(Icons.more_horiz_rounded),
              itemBuilder: (_) => buildLibraryActionMenu(
                l10n,
                actions: const {
                  'edit',
                  'add',
                  'share',
                  'share_pdf',
                  'copy',
                  'print',
                  'delete',
                },
              ),
              onSelected: (action) =>
                  handleSongMenuAction(context, controller, song.id, action),
            ),
            caption: [
              if (song.isConflictCopy) l10n.songsConflictBadge,
              song.artist,
              song.album,
              if (song.playCount > 0) l10n.songsUsageCount(song.playCount),
            ].whereType<String>().where((text) => text.isNotEmpty).join(' · '),
          ),
        ),
        const Divider(indent: 76, endIndent: 16),
      ],
    );
  }
}

/// Alphabet index along the edge of the song list. The whole strip is one
/// touch target: tapping or sliding a finger along it selects the letter under
/// the finger, so individual letters need not be 48dp tall. Each letter is also
/// a labelled button for screen readers.
class _LetterRail extends StatelessWidget {
  const _LetterRail({
    required this.letters,
    required this.label,
    required this.jumpLabel,
    required this.onSelect,
  });
  final List<String> letters;
  final String label;
  final String Function(String letter) jumpLabel;
  final void Function(String letter, {required bool animate}) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: label,
      child: SizedBox(
        key: const ValueKey('songs-letter-rail'),
        width: 44,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Letters are at most 48dp tall; with many letters they shrink to
            // fit, and sliding along the strip still reaches every one.
            final slot = (constraints.maxHeight / letters.length).clamp(
              0.0,
              48.0,
            );
            final total = slot * letters.length;
            void pick(Offset position, {required bool animate}) {
              if (total <= 0) return;
              final index = (position.dy / total * letters.length)
                  .floor()
                  .clamp(0, letters.length - 1);
              onSelect(letters[index], animate: animate);
            }

            return Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    pick(details.localPosition, animate: true),
                onVerticalDragUpdate: (details) =>
                    pick(details.localPosition, animate: false),
                child: SizedBox(
                  width: 44,
                  height: total,
                  child: Column(
                    children: [
                      for (final letter in letters)
                        SizedBox(
                          height: slot,
                          child: Semantics(
                            button: true,
                            label: jumpLabel(letter),
                            excludeSemantics: true,
                            onTap: () => onSelect(letter, animate: true),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  letter,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
