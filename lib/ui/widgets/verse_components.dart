import 'package:flutter/material.dart';
import '../format.dart';
import '../verse_ui_state.dart';

/// The approved Singbook mark, composed over a theme-aware brand surface.
class SingbookMark extends StatelessWidget {
  const SingbookMark({
    super.key,
    this.size = 36,
    this.excludeSemantics = false,
  });
  final double size;

  /// Hide the mark from assistive technology when a visible wordmark beside
  /// it already announces the brand.
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Singbook',
    excludeSemantics: excludeSemantics,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .23),
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .035),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Image.asset(
          'assets/branding/singbook-mark-foreground.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.library_music_rounded,
            size: size * .68,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    ),
  );
}

class VerseIconButton extends StatelessWidget {
  const VerseIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    isSelected: selected,
    style: IconButton.styleFrom(
      minimumSize: const Size(48, 48),
      fixedSize: const Size(48, 48),
      foregroundColor: selected ? Theme.of(context).colorScheme.primary : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class VerseArtwork extends StatelessWidget {
  const VerseArtwork({super.key, this.url, this.size = 48, this.rounded = 12});
  final String? url;
  final double size, rounded;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(rounded),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url!.isEmpty
            ? ColoredBox(
                color: color.primaryContainer.withValues(alpha: .6),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: color.primary,
                  size: size * .45,
                ),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: pixels,
                cacheHeight: pixels,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: color.primaryContainer.withValues(alpha: .6),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: color.primary,
                    size: size * .45,
                  ),
                ),
              ),
      ),
    );
  }
}

class VerseSectionLabel extends StatelessWidget {
  const VerseSectionLabel(this.label, {super.key, this.trailing, this.action});
  final String label;
  final String? trailing;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: action,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text(trailing!),
          ),
      ],
    ),
  );
}

class VerseEmptyState extends StatelessWidget {
  const VerseEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? message, actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).height < 430;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: compact ? 8 : 44),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 40 : 64,
                height: compact ? 40 : 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(compact ? 14 : 22),
                ),
                child: Icon(
                  icon,
                  size: compact ? 22 : 28,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: compact ? 8 : 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: compact ? 8 : 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A consistent final list row for creating another library item.
class LibraryCreateShortcut extends StatelessWidget {
  const LibraryCreateShortcut({
    super.key,
    required this.label,
    required this.onPressed,
    this.margin = EdgeInsets.zero,
    this.minHeight = 72,
    this.songRowStyle = false,
  });

  final String label;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry margin;
  final double minHeight;
  final bool songRowStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Card(
          margin: margin,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: songRowStyle ? 64 : minHeight,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.add_rounded,
                          color: colors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style:
                            (songRowStyle
                                    ? Theme.of(context).textTheme.titleSmall
                                    : Theme.of(context).textTheme.titleMedium)
                                ?.copyWith(
                                  fontWeight: songRowStyle
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SongRow extends StatelessWidget {
  const SongRow({
    super.key,
    required this.song,
    required this.accessibilityLabel,
    required this.favoriteAddLabel,
    required this.favoriteRemoveLabel,
    required this.menuLabel,
    required this.onOpen,
    this.onFavorite,
    this.onMenu,
    this.menuWidget,
    this.caption,
    this.showFavorite = true,
  });
  final SongCardData song;
  final String accessibilityLabel,
      favoriteAddLabel,
      favoriteRemoveLabel,
      menuLabel;
  final VoidCallback onOpen;
  final VoidCallback? onFavorite, onMenu;
  final Widget? menuWidget;
  final String? caption;
  final bool showFavorite;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // The spoken label carries what is shown (album, length, caption) too,
    // leaving out empty parts such as a missing artist.
    final spoken = [
      accessibilityLabel.replaceAll(RegExp(r'[,\s]+$'), ''),
      if (song.sourceVariantLabel case final variant?)
        formatSourceVariantLabel(variant),
      if (caption != null) caption,
      if (caption == null && song.album?.isNotEmpty == true) song.album,
      if (caption == null && song.durationSeconds != null)
        formatDuration(song.durationSeconds!),
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    // Only the open area is one labelled button; the favorite and menu
    // buttons are siblings, so screen readers announce each exactly once.
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: spoken,
            excludeSemantics: true,
            onTap: onOpen,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    VerseArtwork(url: song.artworkUrl, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          if (song.sourceVariantLabel case final variant?)
                            Text(
                              formatSourceVariantLabel(variant),
                              key: ValueKey('song-variant-${song.id}'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            caption ??
                                [
                                      song.artist,
                                      if (song.album?.isNotEmpty == true)
                                        song.album,
                                      if (song.durationSeconds != null)
                                        formatDuration(song.durationSeconds!),
                                    ]
                                    .whereType<String>()
                                    .where((e) => e.isNotEmpty)
                                    .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showFavorite && onFavorite != null)
          VerseIconButton(
            icon: song.favorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            tooltip: song.favorite ? favoriteRemoveLabel : favoriteAddLabel,
            selected: song.favorite,
            onPressed: onFavorite,
          ),
        if (menuWidget != null)
          menuWidget!
        else if (onMenu != null)
          VerseIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: menuLabel,
            onPressed: onMenu,
          ),
      ],
    );
  }
}
