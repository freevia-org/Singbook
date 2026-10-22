import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../localized_labels.dart';
import '../verse_ui_state.dart';
import 'source_version_widgets.dart';

void showComparisonVersionInfo(
  BuildContext context, {
  required VerseUiController controller,
  required SourceVersionData version,
}) {
  final referenceId = controller.state.comparison?.reference.id;
  final id = versionSelectionId(version);
  _showDetails(context, controller, (context) {
    final comparison = controller.state.comparison;
    final selected = comparison?.selected;
    final current = comparison != null && comparison.reference.id == referenceId
        ? selected != null && versionSelectionId(selected) == id
              ? selected
              : comparisonVersions(
                  comparison,
                ).where((item) => versionSelectionId(item) == id).firstOrNull
        : null;
    final value = current ?? version;
    final l10n = AppLocalizations.of(context);
    return [
      _heading(context, l10n.searchVersionDetails),
      _field(l10n.searchSourceLabel, versionName(l10n, value)),
      _field(l10n.editorTitleField, value.title),
      _field(l10n.editorArtistField, value.artist),
      _field(l10n.editorAlbumField, value.album),
      if (value.durationSeconds != null)
        _field(
          l10n.searchVersionDuration,
          formatDuration(value.durationSeconds!),
        ),
      _field(
        l10n.searchSongMatch,
        value.isChecking
            ? l10n.searchVersionChecking
            : value.sameRecording
            ? l10n.searchMatchExact
            : value.matchSummary.isEmpty
            ? l10n.searchMatchUnverified
            : localizedMatchReason(l10n, value.matchSummary),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (value.hasLyrics)
              Chip(label: Text(l10n.providerCapabilityLyrics)),
            if (value.hasChords)
              Chip(label: Text(l10n.providerCapabilityChords)),
            if (value.hasTiming) Chip(label: Text(l10n.playerTimedLyrics)),
          ],
        ),
      ),
      ..._metadataFields(l10n, value.metadata),
      if (value.rating != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            '${l10n.searchRating(value.rating.toString())}'
            '${value.ratingCount == null ? '' : ' (${value.ratingCount})'}',
          ),
        ),
      if (value.sourceUrl != null) _url(value.sourceUrl!),
      if (value.contributions.isNotEmpty) ...[
        _section(context, l10n.searchContributions),
        for (final contribution in value.contributions) ...[
          _field(
            contribution.providerName,
            contribution.roles.map((role) => _role(l10n, role)).join(' · '),
          ),
          if (contribution.sourceUrl != null &&
              contribution.sourceUrl != value.sourceUrl)
            _url(contribution.sourceUrl!),
        ],
      ],
      if (comparison != null && comparison.reference.id == referenceId) ...[
        _section(context, l10n.searchSelectedRecording),
        _field(l10n.editorTitleField, comparison.reference.title),
        _field(l10n.editorArtistField, comparison.reference.artist),
        _field(l10n.editorAlbumField, comparison.reference.album),
        if (comparison.reference.durationSeconds != null)
          _field(
            l10n.editorDurationField,
            formatDuration(comparison.reference.durationSeconds!),
          ),
      ],
    ];
  }, key: const ValueKey('version-info-sheet'));
}

void showComparisonSourceChecks(
  BuildContext context, {
  required VerseUiController controller,
}) {
  final initial = controller.state.comparison;
  _showDetails(context, controller, (context) {
    final live = controller.state.comparison;
    final comparison = live?.reference.id == initial?.reference.id
        ? live
        : initial;
    final l10n = AppLocalizations.of(context);
    final checks = comparison?.providerChecks ?? const [];
    final unavailable = checks
        .where(
          (check) => check.state == 'failed' || check.state == 'unavailable',
        )
        .length;
    return [
      _heading(context, l10n.searchProviderChecks),
      if (checks.isEmpty) _paragraph(l10n.searchCheckNoHistory),
      if (unavailable > 0)
        _paragraph(l10n.searchSourcesUnavailableCount(unavailable)),
      for (final check in checks)
        ListTile(
          key: ValueKey('discovery-provider-${check.id}'),
          leading: Icon(
            _statusIcon(check.state),
            color: _statusColor(context, check.state),
          ),
          title: Text(check.name),
          subtitle: Text(_status(l10n, check.state)),
          trailing: Icon(_chevron(context)),
          onTap: () => _showProviderDetails(context, controller, check),
        ),
      if (comparison != null &&
          !comparison.discovering &&
          (comparison.discoveryError != null ||
              comparison.noUsableLyrics ||
              checks.any((check) => check.state == 'failed')))
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.searchDiscoveryRetry),
            onPressed: () {
              Navigator.pop(context);
              unawaited(controller.retrySelectedSongDiscovery());
            },
          ),
        ),
    ];
  }, key: const ValueKey('source-checks-sheet'));
}

void _showProviderDetails(
  BuildContext context,
  VerseUiController controller,
  SearchProviderCheckData initial,
) {
  final referenceId = controller.state.comparison?.reference.id;
  _showDetails(context, controller, (context) {
    final comparison = controller.state.comparison;
    final live = comparison?.reference.id == referenceId
        ? comparison?.providerChecks
              .where((item) => item.id == initial.id)
              .firstOrNull
        : null;
    final check = live ?? initial;
    final l10n = AppLocalizations.of(context);
    return [
      _heading(context, check.name),
      _paragraph(_status(l10n, check.state)),
      if (check.code != null) ..._codeDetails(context, check.code!),
      if (check.operations.isEmpty && check.state == 'pending')
        _paragraph(l10n.searchCheckQueued),
      if (check.operations.isNotEmpty)
        _section(context, l10n.searchCheckOperations),
      for (final operation in check.operations)
        KeyedSubtree(
          key: ValueKey('source-operation-${operation.id}'),
          child: ExpansionTile(
            // Reveal a new failure even when this row was already visible.
            key: ValueKey(
              '${operation.id}:${operation.state == 'failed' || operation.state == 'rejected'}',
            ),
            initiallyExpanded:
                operation.state == 'failed' || operation.state == 'rejected',
            leading: Icon(
              _statusIcon(operation.state),
              color: _statusColor(context, operation.state),
            ),
            title: Text(_phase(l10n, operation.phase)),
            subtitle: Text(_status(l10n, operation.state)),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (operation.query?.isNotEmpty == true)
                _paragraph(operation.query!, selectable: true),
              _field(l10n.editorTitleField, operation.title),
              _field(l10n.editorArtistField, operation.artist),
              if (operation.sourceUrl != null) _url(operation.sourceUrl!),
              if (operation.resultCount != null)
                _paragraph(l10n.searchResultCount(operation.resultCount!)),
              if (operation.elapsedMilliseconds != null)
                _paragraph(
                  l10n.playerElapsed('${operation.elapsedMilliseconds} ms'),
                ),
              if (operation.code != null)
                ..._codeDetails(context, operation.code!),
            ],
          ),
        ),
    ];
  }, key: ValueKey('source-check-details-${initial.id}'));
}

void _showDetails(
  BuildContext context,
  Listenable controller,
  List<Widget> Function(BuildContext) content, {
  required Key key,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final desktopLandscape = size.width >= 840 && size.width > size.height;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: size.height < 480
              ? .95
              : desktopLandscape || largeText
              ? .85
              : .65,
          minChildSize: .3,
          maxChildSize: .95,
          builder: (context, scroll) => AnimatedBuilder(
            animation: controller,
            builder: (context, _) => ListView(
              key: key,
              controller: scroll,
              padding: const EdgeInsets.only(bottom: 20),
              children: content(context),
            ),
          ),
        ),
      );
    },
  );
}

Widget _heading(BuildContext context, String text) => ListTile(
  title: Text(text, style: Theme.of(context).textTheme.titleLarge),
  trailing: IconButton(
    tooltip: AppLocalizations.of(context).navClose,
    icon: const Icon(Icons.close_rounded),
    onPressed: () => Navigator.pop(context),
  ),
);

Widget _section(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
  child: Text(text, style: Theme.of(context).textTheme.titleMedium),
);

String? _value(Object? value) {
  if (value is List) {
    final values = value.map(_value).whereType<String>().toSet();
    return values.isEmpty ? null : values.join('\n');
  }
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ||
          const {'unknown', 'null', 'n/a'}.contains(text.toLowerCase())
      ? null
      : text;
}

Widget _field(String label, Object? value) {
  final text = _value(value);
  if (text == null) return const SizedBox.shrink();
  return Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          SelectableText(text),
        ],
      ),
    ),
  );
}

Widget _paragraph(String text, {bool selectable = false}) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
  child: selectable ? SelectableText(text) : Text(text),
);

Widget _url(String value) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: SelectableText(value),
  ),
);

List<Widget> _metadataFields(
  AppLocalizations l10n,
  Map<String, Object?> metadata,
) => [
  _field(l10n.editorKeyField, metadata['key']),
  _field(l10n.editorCapoField, metadata['capo']),
  _field(l10n.editorTuningField, metadata['tuning']),
  _field(l10n.editorTempoField, metadata['tempo']),
  _field(
    l10n.editorTimeSignatureField,
    metadata['timeSignature'] ?? metadata['time'],
  ),
  _field(l10n.editorLanguageField, metadata['language']),
  _field(l10n.editorYearField, metadata['year']),
  _field(l10n.editorComposerField, [
    metadata['composer'],
    metadata['composers'],
  ]),
  _field(l10n.editorLyricistField, [
    metadata['lyricist'],
    metadata['lyricists'],
  ]),
  _field(l10n.searchVersionCredits, [
    metadata['credits'],
    metadata['writers'],
    metadata['author'],
  ]),
  _field(l10n.searchVersionMediaLinks, metadata['mediaLinks']),
];

String _role(AppLocalizations l10n, String role) => switch (role) {
  'lyrics' => l10n.providerCapabilityLyrics,
  'chords' => l10n.providerCapabilityChords,
  'timing' => l10n.playerTimedLyrics,
  _ => l10n.providerCapabilityMetadata,
};

String _status(AppLocalizations l10n, String state) => switch (state) {
  'pending' => l10n.searchProviderPending,
  'found' => l10n.searchProviderFound,
  'completed' => l10n.searchCheckCompleted,
  'rejected' => l10n.searchProviderRejected,
  'failed' => l10n.searchProviderFailed,
  'cancelled' => l10n.searchCheckCancelled,
  _ => l10n.searchProviderUnavailable,
};

String _phase(AppLocalizations l10n, String phase) => switch (phase) {
  'search' => l10n.providerCapabilitySearch,
  'fetch' => l10n.searchCheckFetch,
  'metadata' => l10n.providerCapabilityMetadata,
  'validate' => l10n.searchCheckValidate,
  'corroborate' => l10n.searchCheckCorroborate,
  _ => l10n.searchCheckOperations,
};

IconData _statusIcon(String state) => switch (state) {
  'pending' => Icons.hourglass_empty_rounded,
  'found' || 'completed' => Icons.check_circle_outline_rounded,
  'failed' => Icons.error_outline_rounded,
  'cancelled' => Icons.cancel_outlined,
  _ => Icons.info_outline_rounded,
};

Color _statusColor(BuildContext context, String state) =>
    state == 'failed' || state == 'rejected'
    ? Theme.of(context).colorScheme.error
    : Theme.of(context).colorScheme.primary;

IconData _chevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? Icons.chevron_left_rounded
    : Icons.chevron_right_rounded;

List<Widget> _codeDetails(BuildContext context, String code) {
  final l10n = AppLocalizations.of(context);
  final safe = RegExp(r'^[a-z][a-z0-9_]{0,95}$').hasMatch(code) ? code : null;
  final text = switch (safe) {
    'cancelled' => l10n.searchCheckCancelled,
    'ambiguous_match' => l10n.searchCheckAmbiguous,
    'identity_required' => l10n.searchCheckIdentity,
    'extraction_failed' => l10n.searchCheckExtraction,
    'provider_busy' => l10n.searchCheckBusy,
    'user_selection_required' ||
    'select_specific_work' => l10n.searchCheckSelection,
    'timeout' => l10n.searchCheckTimeout,
    'blocked' || 'access_denied' => l10n.searchCheckBlocked,
    'rate_limited' => l10n.searchCheckRateLimited,
    'network' || 'network_error' || 'offline' => l10n.searchCheckNetwork,
    'invalid_response' ||
    'layout_changed' ||
    'decode' => l10n.searchCheckInvalid,
    'not_configured' => l10n.searchCheckNotConfigured,
    'unavailable' => l10n.searchCheckNoLyrics,
    'same_recording' ||
    'same_song' ||
    'arrangement_requires_agreement' ||
    'uncorroborated_arrangement' ||
    'incomplete_or_different_lyrics' ||
    'identity_mismatch' => localizedMatchReason(l10n, safe),
    _ => l10n.searchCheckFailed,
  };
  return [
    _paragraph(text),
    if (safe != null) _field(l10n.searchCheckCode, safe),
  ];
}
