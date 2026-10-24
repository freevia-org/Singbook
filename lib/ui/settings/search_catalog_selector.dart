import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../verse_ui_state.dart';

/// The search catalog choice shown in Settings > Sources. It renders nothing
/// while no catalog is available. When other enabled catalogs are searched
/// too, it is labelled as the preferred source, whose rows open first.
class SearchCatalogSelector extends StatelessWidget {
  const SearchCatalogSelector({
    super.key,
    required this.controller,
    required this.state,
  });

  final VerseUiController controller;
  final VerseUiState state;

  @override
  Widget build(BuildContext context) {
    if (state.searchCatalogs.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return InputDecorator(
      key: const ValueKey('search-catalog-selector'),
      isEmpty: state.searchCatalogId == null,
      decoration: InputDecoration(
        labelText: state.searchIncludesOtherSources
            ? l10n.searchPreferredSourceLabel
            : l10n.searchSourceLabel,
        helperText: state.searchIncludesOtherSources
            ? l10n.searchPreferredSourceHint
            : null,
        helperMaxLines: 3,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              state.searchCatalogs.any(
                (catalog) => catalog.id == state.searchCatalogId,
              )
              ? state.searchCatalogId
              : null,
          isExpanded: true,
          items: [
            for (final catalog in state.searchCatalogs)
              DropdownMenuItem(
                value: catalog.id,
                child: Text(
                  catalog.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) unawaited(controller.setSearchCatalog(value));
          },
        ),
      ),
    );
  }
}
