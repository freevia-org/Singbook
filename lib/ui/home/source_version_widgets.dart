import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../verse_ui_state.dart';

/// The same choices are used by the comparison list and the full preview.
List<SourceVersionData> comparisonVersions(SearchComparisonData comparison) {
  final suggested = comparison.suggested;
  return [
    ?suggested,
    ...comparison.alternatives.where((version) => version.id != suggested?.id),
  ];
}

String versionName(AppLocalizations l10n, SourceVersionData version) =>
    version.id == 'combined'
    ? l10n.searchCombinedFromSources(version.sourceCount ?? 1)
    : version.providerName.isNotEmpty
    ? version.providerName
    : l10n.searchSuggested;

/// The combined recommendation is a distinct choice even when only one source
/// currently contributes; choosing a provider tab pins that source directly.
String versionSelectionId(SourceVersionData version) =>
    version.id != 'combined' &&
        version.sourceCount == 1 &&
        version.underlyingSourceId != null
    ? version.underlyingSourceId!
    : version.id;

class SourceContributions extends StatelessWidget {
  const SourceContributions({super.key, required this.version});
  final SourceVersionData version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if ((version.sourceCount ?? 0) < 2 || version.contributions.isEmpty) {
      return const SizedBox.shrink();
    }
    String role(String value) => switch (value) {
      'lyrics' => l10n.providerCapabilityLyrics,
      'chords' => l10n.providerCapabilityChords,
      'timing' => l10n.playerTimedLyrics,
      _ => l10n.searchMetadata,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchContributions,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        for (final contribution in version.contributions)
          Text(
            '${contribution.providerName} · ${contribution.roles.map(role).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
