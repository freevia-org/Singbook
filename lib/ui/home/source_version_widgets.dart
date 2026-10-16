import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../verse_ui_state.dart';

/// The same choices are used by the comparison list and the full preview.
List<SourceVersionData> comparisonVersions(SearchComparisonData comparison) {
  final suggested = comparison.suggested;
  final explicitUnderlying =
      suggested?.sourceCount == 1 &&
      suggested?.underlyingSourceId == comparison.selectedVersionId;
  return [
    if (suggested != null && !explicitUnderlying) suggested,
    ...comparison.alternatives.where(
      (version) =>
          version.id != suggested?.id &&
          !(suggested?.sourceCount == 1 &&
              version.id == suggested?.underlyingSourceId &&
              version.id != comparison.selectedVersionId &&
              version.durationSeconds == suggested?.durationSeconds &&
              version.hasChords == suggested?.hasChords &&
              version.hasTiming == suggested?.hasTiming),
    ),
  ];
}

String versionName(AppLocalizations l10n, SourceVersionData version) =>
    version.sourceCount != null && version.sourceCount! > 1
    ? l10n.searchCombinedFromSources(version.sourceCount!)
    : version.providerName.isNotEmpty
    ? version.providerName
    : l10n.searchSuggested;

/// A single-source recommendation is displayed under that source's name.
/// Choosing it must pin that source rather than a future combined recipe.
String versionSelectionId(SourceVersionData version) =>
    version.sourceCount == 1 && version.underlyingSourceId != null
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
