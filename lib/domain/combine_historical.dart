part of 'combine.dart';

bool explicitHistoricalWorkMatches(
  SongCandidate selected,
  SourceResult source,
) {
  final candidate = source.candidate;
  final metadata = source.metadata;
  final revision = metadata['revision'];
  final selectedPageId = int.tryParse(selected.id);
  if (source.matchKind != MatchKind.sameSong ||
      source.matchReason != 'explicit_historical_work' ||
      selected.providerId != 'wikisource' ||
      candidate.providerId != 'wikisource' ||
      !RegExp(r'^[1-9]\d*$').hasMatch(selected.id) ||
      selectedPageId == null ||
      selectedPageId <= 0 ||
      candidate.id != selected.id ||
      _identityNorm(selected.title) != _identityNorm(candidate.title) ||
      (selected.artist.trim().isNotEmpty &&
          _identityNorm(selected.artist) != _identityNorm(candidate.artist)) ||
      metadata['identityScope'] != 'historicalText' ||
      candidate.metadata['identityScope'] != 'historicalText' ||
      metadata['resolvedPageId'] != selected.id ||
      candidate.metadata['resolvedPageId'] != selected.id ||
      metadata['resolvedTitle'] != candidate.title ||
      candidate.metadata['resolvedTitle'] != candidate.title ||
      revision is! int ||
      revision <= 0 ||
      candidate.metadata['revision'] is! int ||
      candidate.metadata['revision'] != revision ||
      source.extra['revision'] is! String ||
      source.extra['revision'] != revision.toString()) {
    return false;
  }
  final tags = metadata['copyrightTags'];
  final candidateTags = candidate.metadata['copyrightTags'];
  if (tags is! List ||
      tags.isEmpty ||
      jsonEncode(tags) != jsonEncode(candidateTags)) {
    return false;
  }
  final rights = jsonMap(source.extra['rights']);
  final permissions = jsonMap(rights['permissions']);
  final rightsTags = permissions['tags'];
  return rights['source'] == 'wikisource' &&
      rights['sourceId'] == selected.id &&
      rights['license'] is String &&
      (rights['license'] as String).trim().isNotEmpty &&
      permissions['status'] == 'per_work_and_jurisdiction' &&
      rightsTags is List &&
      rightsTags.isNotEmpty &&
      jsonEncode(tags) == jsonEncode(rightsTags);
}

String _historicalPayload(Object? value) {
  Object? ordered(Object? item) {
    if (item is Map) {
      final keys = item.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(item[key])};
    }
    if (item is List) return item.map(ordered).toList();
    return item;
  }

  return jsonEncode(ordered(value));
}

/// An unchanged version read from the local library, never fresh extraction
/// proof. This capability is not serialized. Production callers construct it
/// only at AppController's repository-backed saved comparison boundary.
class HistoricalCacheUse {
  HistoricalCacheUse._(this._source, this._payload, this._selection);
  final SourceResult _source;
  final String _payload, _selection;

  static HistoricalCacheUse? fromLibrarySnapshot(
    SongDocument stored,
    SongCandidate selected,
    SourceResult source,
  ) {
    if (stored.extensionError != null ||
        !_legacyHistoricalWork(stored, selected, source)) {
      return null;
    }
    final payload = _historicalPayload(source.toJson());
    if (!stored.sources.any(
      (item) =>
          item.id == source.id && _historicalPayload(item.toJson()) == payload,
    )) {
      return null;
    }
    return HistoricalCacheUse._(
      source,
      payload,
      _historicalPayload(selected.toJson()),
    );
  }

  bool allows(SongCandidate selected, SourceResult source) =>
      identical(source, _source) &&
      _selection == _historicalPayload(selected.toJson()) &&
      _payload == _historicalPayload(source.toJson());

  /// Carry only an already authorized unchanged object into the synchronous
  /// save snapshot. A new provider result with the same ID cannot acquire use.
  HistoricalCacheUse? capture(
    SongCandidate selected,
    SourceResult original,
    SourceResult snapshot,
  ) =>
      allows(selected, original) &&
          _payload == _historicalPayload(snapshot.toJson())
      ? HistoricalCacheUse._(snapshot, _payload, _selection)
      : null;
}

bool _legacyHistoricalWork(
  SongDocument stored,
  SongCandidate selected,
  SourceResult source,
) {
  final found = source.candidate;
  final metadata = source.metadata;
  final anchor =
      stored.selectedRecording ??
      (stored.extra['selectedSourceId'] == source.id ? found : null);
  if (anchor == null ||
      _historicalPayload(anchor.toJson()) !=
          _historicalPayload(selected.toJson()) ||
      selected.providerId != 'wikisource' ||
      found.providerId != 'wikisource' ||
      !RegExp(r'^[1-9]\d*$').hasMatch(selected.id) ||
      int.tryParse(selected.id) == null ||
      found.id != selected.id ||
      _identityNorm(selected.title).isEmpty ||
      _identityNorm(selected.title) != _identityNorm(found.title) ||
      (selected.artist.trim().isNotEmpty &&
          _identityNorm(selected.artist) != _identityNorm(found.artist)) ||
      selected.metadata['identityScope'] != 'historicalText' ||
      found.metadata['identityScope'] != 'historicalText' ||
      metadata['identityScope'] != 'historicalText' ||
      source.extra['sourceDocumentId'] != source.id ||
      source.extra['userSelectedImport'] != true ||
      plainLyrics(source.body).trim().isEmpty) {
    return false;
  }
  final acceptedLegacy =
      source.matchKind == MatchKind.sameSong &&
          source.matchReason == 'same_song' ||
      source.matchKind == MatchKind.sameRecording &&
          source.matchReason == 'same_recording';
  // The original matcher rejected the newly populated author even though the
  // person had selected that exact page and explicitly saved its source card.
  final rejectedAuthorFill =
      source.matchKind == MatchKind.rejected &&
      source.matchReason == 'identity_mismatch' &&
      stored.selectedRecording != null &&
      selected.artist.trim().isEmpty &&
      found.artist.trim().isNotEmpty &&
      stored.extra['savedSourceId'] == source.id &&
      stored.extra['selectedSourceId'] == source.id;
  if (!acceptedLegacy && !rejectedAuthorFill) return false;
  for (final facts in [found.metadata, metadata]) {
    if (facts.containsKey('resolvedPageId') &&
            facts['resolvedPageId'] != selected.id ||
        facts.containsKey('resolvedTitle') &&
            facts['resolvedTitle'] != found.title) {
      return false;
    }
  }
  final tags = metadata['copyrightTags'];
  final rights = jsonMap(source.extra['rights']);
  final permissions = jsonMap(rights['permissions']);
  final revision = metadata['revision'];
  if (tags is! List ||
      tags.isEmpty ||
      tags.any(
        (tag) =>
            tag is! String ||
            !RegExp(
              r'^Template:(?:PD-|Cc-by|CC0)',
              caseSensitive: false,
            ).hasMatch(tag),
      ) ||
      _historicalPayload(tags) !=
          _historicalPayload(found.metadata['copyrightTags']) ||
      _historicalPayload(tags) != _historicalPayload(permissions['tags']) ||
      rights['source'] != 'wikisource' ||
      rights['sourceId'] != selected.id ||
      permissions['status'] != 'per_work_and_jurisdiction' ||
      rights['license'] != tags.join('; ') ||
      revision is! int ||
      revision <= 0 ||
      found.metadata['revision'] != revision ||
      source.extra.containsKey('revision') &&
          source.extra['revision'] != revision.toString()) {
    return false;
  }
  bool pageUrl(Object? value) {
    if (value == null) return true;
    if (value is! String) return false;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'en.wikisource.org' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort && uri.port != 443) {
      return false;
    }
    if (uri.queryParameters.containsKey('curid')) {
      return (uri.path.isEmpty || uri.path == '/') &&
          uri.queryParameters.length == 1 &&
          uri.queryParametersAll['curid']?.length == 1 &&
          uri.queryParameters['curid'] == selected.id;
    }
    if (!uri.path.startsWith('/wiki/') || uri.hasQuery) return false;
    try {
      return _identityNorm(
            Uri.decodeComponent(uri.path.substring(6)).replaceAll('_', ' '),
          ) ==
          _identityNorm(found.title);
    } on FormatException {
      return false;
    }
  }

  return pageUrl(selected.url) &&
      pageUrl(found.url) &&
      pageUrl(rights['sourceUrl']) &&
      (!rights.containsKey('licenseUrl') ||
          rights['licenseUrl'] ==
              'https://en.wikisource.org/wiki/Wikisource:Copyright_policy');
}
