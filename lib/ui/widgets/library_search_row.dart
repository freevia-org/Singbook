import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'verse_components.dart';

/// The filter field above a library list (songs, setlists) with its clear and
/// submit buttons and the favorites-only toggle.
class LibrarySearchRow extends StatelessWidget {
  const LibrarySearchRow({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.favoritesOnly,
    required this.onFavoritesOnlyChanged,
  });

  final TextEditingController controller;

  /// The text currently filtering the list; the clear button shows with it.
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool favoritesOnly;

  /// Null hides the favorites toggle (another filter owns the list).
  final ValueChanged<bool>? onFavoritesOnlyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onFavoritesOnlyChanged = this.onFavoritesOnlyChanged;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (query.isNotEmpty)
                      IconButton(
                        tooltip: l10n.accessibilityClearSearch,
                        onPressed: onClear,
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
          if (onFavoritesOnlyChanged != null)
            VerseIconButton(
              key: const ValueKey('favorites-filter-button'),
              tooltip: l10n.searchFavoritesTab,
              selected: favoritesOnly,
              onPressed: () => onFavoritesOnlyChanged(!favoritesOnly),
              icon: favoritesOnly
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
        ],
      ),
    );
  }
}
