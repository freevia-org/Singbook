import 'dart:convert';

import 'edition_identity.dart';
import 'models.dart';

String _identity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

bool _present(Object? value) =>
    value != null &&
    (value is! String || value.trim().isNotEmpty) &&
    (value is! Iterable || value.isNotEmpty) &&
    (value is! Map || value.isNotEmpty);

double? _seconds(Object? value) {
  if (value is! num) return null;
  final seconds = value.toDouble();
  return seconds.isFinite && seconds > 0 && seconds <= 86400 ? seconds : null;
}

String? _album(SongCandidate candidate, [JsonMap metadata = const {}]) {
  for (final value in [
    candidate.album,
    metadata['album'],
    candidate.metadata['album'],
  ]) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

double? _duration(SongCandidate candidate, [JsonMap metadata = const {}]) =>
    _seconds(candidate.durationSeconds) ??
    _seconds(metadata['durationSeconds']) ??
    _seconds(candidate.metadata['durationSeconds']) ??
    _seconds(metadata['duration']) ??
    _seconds(candidate.metadata['duration']);

bool _conflictingIds(SongCandidate first, SongCandidate second) =>
    first.recordingIds.entries.any(
      (entry) =>
          second.recordingIds.containsKey(entry.key) &&
          second.recordingIds[entry.key] != entry.value,
    );

bool _secureArtwork(Object? value) {
  final uri = value is String ? Uri.tryParse(value) : null;
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}

bool _consistentFacts(SourceResult source) {
  final candidate = source.candidate;
  final durations = [
    candidate.durationSeconds,
    candidate.metadata['durationSeconds'],
    candidate.metadata['duration'],
    source.metadata['durationSeconds'],
    source.metadata['duration'],
  ].map(_seconds).whereType<double>().toList()..sort();
  final albums =
      [candidate.album, candidate.metadata['album'], source.metadata['album']]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .map(_identity)
          .toSet();
  return albums.length <= 1 &&
      (durations.isEmpty || durations.last - durations.first <= 3);
}

class _DisplayDonor {
  final SourceResult source;
  final String? album;
  final double? duration;
  final bool verified;
  _DisplayDonor(this.source, this.verified)
    : album = _album(source.candidate, source.metadata),
      duration = _duration(source.candidate, source.metadata);

  JsonMap get facts => {
    ...source.candidate.metadata,
    ...source.metadata,
    if (album != null) 'album': album,
    if (duration != null) 'durationSeconds': duration,
  };
}

/// Complements display facts only, after recording/timing/arrangement decisions.
///
/// Evidence always comes from the original selected candidate and source
/// documents. Filled album/duration fields never become recording evidence.
SongDocument enrichCombinedDisplayMetadata(
  SongDocument song, {
  required bool Function(SongCandidate, SourceResult) isSameRecording,
}) {
  final selected = song.selectedRecording;
  if (selected == null) return song;
  const excludedScopes = {
    'historicalText',
    'composition',
    'work',
    'artist',
    'image',
    'arrangement',
  };
  if (selected.providerId == 'wikisource' ||
      excludedScopes.contains(selected.metadata['identityScope']) ||
      excludedScopes.contains(selected.extra['identityScope']) ||
      selected.metadata['pendingMatchCheck'] == true ||
      selected.extra['pendingMatchCheck'] == true) {
    return song;
  }
  final title = _identity(selected.title), artist = _identity(selected.artist);
  if (title.isEmpty || artist.isEmpty) return song;
  final selectedAlbum = _album(selected);
  final selectedDuration = _duration(selected);
  // Existing display facts can veto contradictory donors, but cannot prove a
  // match. This also protects manual edits made after the original selection.
  final displayedAlbum = song.metadata['album'];
  final displayedDuration = _seconds(song.metadata['durationSeconds']);
  final donors = <_DisplayDonor>[];
  for (final source in song.sources) {
    final candidate = source.candidate;
    if (!{
          MatchKind.sameSong,
          MatchKind.sameRecording,
        }.contains(source.matchKind) ||
        source.extra['pendingMatchCheck'] == true ||
        source.metadata['pendingMatchCheck'] == true ||
        candidate.metadata['pendingMatchCheck'] == true ||
        candidate.extra['pendingMatchCheck'] == true ||
        candidate.providerId == 'wikisource' ||
        [
          candidate.metadata,
          candidate.extra,
          source.metadata,
          source.extra,
        ].any((map) => excludedScopes.contains(map['identityScope'])) ||
        title != _identity(candidate.title) ||
        artist != _identity(candidate.artist) ||
        _conflictingIds(selected, candidate) ||
        !_consistentFacts(source) ||
        !explicitEditionsCompatible(
          selected,
          candidate,
          metadata: source.metadata,
          extra: source.extra,
        )) {
      continue;
    }
    final donor = _DisplayDonor(source, isSameRecording(selected, source));
    if (selectedAlbum != null &&
        donor.album != null &&
        _identity(selectedAlbum) != _identity(donor.album!)) {
      continue;
    }
    if (selectedDuration != null &&
        donor.duration != null &&
        (selectedDuration - donor.duration!).abs() > 3) {
      continue;
    }
    if (displayedAlbum is String &&
        displayedAlbum.trim().isNotEmpty &&
        donor.album != null &&
        _identity(displayedAlbum) != _identity(donor.album!)) {
      continue;
    }
    if (displayedDuration != null &&
        donor.duration != null &&
        (displayedDuration - donor.duration!).abs() > 3) {
      continue;
    }
    donors.add(donor);
  }
  donors.sort((a, b) {
    final identity = a.source.id.compareTo(b.source.id);
    return identity != 0
        ? identity
        : jsonEncode(a.facts).compareTo(jsonEncode(b.facts));
  });

  // An original selected/resolved recording may anchor an album. Neither this
  // set nor the sparse consensus reads the output song's enriched metadata.
  final albums = <String>{
    if (selectedAlbum != null) _identity(selectedAlbum),
    for (final donor in donors)
      if (donor.verified && donor.album != null) _identity(donor.album!),
  };
  final sparse = donors
      .where((d) => d.album != null && d.duration != null)
      .toList();
  final sparseAlbums = sparse.map((d) => _identity(d.album!)).toSet();
  final sparseDurations = sparse.map((d) => d.duration!).toList()..sort();
  final consistentIds = !sparse.any(
    (first) => sparse.any(
      (second) =>
          _conflictingIds(first.source.candidate, second.source.candidate),
    ),
  );
  bool editionsAgree(_DisplayDonor first, _DisplayDonor second) =>
      explicitEditionsCompatible(
        first.source.candidate,
        second.source.candidate,
        selectedMetadata: first.source.metadata,
        selectedExtra: first.source.extra,
        metadata: second.source.metadata,
        extra: second.source.extra,
      );
  final consistentEditions = !sparse.any(
    (first) => sparse.any((second) => !editionsAgree(first, second)),
  );
  final consensus =
      albums.isEmpty &&
      sparse.map((d) => d.source.candidate.providerId).toSet().length >= 2 &&
      sparseAlbums.length == 1 &&
      donors
          .where((d) => d.album != null)
          .every((d) => sparseAlbums.contains(_identity(d.album!))) &&
      sparseDurations.last - sparseDurations.first <= 3 &&
      consistentIds &&
      consistentEditions;
  final eligible = donors
      .where(
        (donor) =>
            donors.every((other) => editionsAgree(donor, other)) &&
            (donor.verified ||
                donor.album != null &&
                    (albums.length == 1 &&
                            albums.contains(_identity(donor.album!)) ||
                        consensus &&
                            sparseAlbums.contains(_identity(donor.album!)))),
      )
      .toList();
  if (eligible.isEmpty) return song;

  final metadata = {...song.metadata};
  final origins = {...jsonMap(song.extra['fieldOrigins'])};
  final contributors = <String, Set<String>>{
    for (final entry in jsonMap(song.extra['fieldContributors']).entries)
      entry.key: (entry.value is List ? entry.value as List : const [])
          .whereType<String>()
          .toSet(),
  };
  final conflicts = <String, dynamic>{
    for (final entry in jsonMap(song.extra['conflicts']).entries)
      entry.key: entry.value is List ? [...entry.value as List] : entry.value,
  };
  const fields = {
    'album',
    'artworkUrl',
    'duration',
    'durationSeconds',
    'releaseDate',
    'year',
    'label',
    'labels',
    'genre',
    'genres',
    'composers',
    'lyricists',
    'writers',
    'producers',
    'performers',
    'credits',
    'artistCredits',
  };
  for (final field in fields) {
    if (origins[field] == 'user') continue;
    final claims = <({String sourceId, dynamic value})>[];
    for (final donor in eligible) {
      // A matching display artist/album cannot validate structured artist IDs.
      // Credit-only MusicBrainz mappings are checked in combineSources instead.
      if (field == 'artistCredits' &&
          donor.source.candidate.providerId == 'musicbrainz' &&
          !donor.verified) {
        continue;
      }
      final value = donor.facts[field];
      if (!_present(value)) continue;
      if (field == 'album' && value is! String) continue;
      if (field == 'duration' && _seconds(value) == null) continue;
      if (field == 'artworkUrl') {
        if (!_secureArtwork(value)) continue;
      }
      claims.add((sourceId: donor.source.id, value: value));
    }
    if (claims.isEmpty) continue;
    final current = metadata[field];
    final invalidAutomatic =
        origins[field] != selected.identity &&
        _present(current) &&
        (field == 'artworkUrl' && !_secureArtwork(current) ||
            {'duration', 'durationSeconds'}.contains(field) &&
                _seconds(current) == null);
    final listClaims = claims.where((claim) => claim.value is List).toList();
    if ((current == null || current is List) &&
        listClaims.length == claims.length) {
      final values = <dynamic>[if (current is List) ...current];
      final seen = values.map(jsonEncode).toSet();
      for (final claim in listClaims) {
        for (final value in claim.value as List) {
          if (_present(value) && seen.add(jsonEncode(value))) values.add(value);
        }
        contributors.putIfAbsent(field, () => {}).add(claim.sourceId);
      }
      if (values.isNotEmpty) {
        metadata[field] = values;
        origins.putIfAbsent(field, () => listClaims.first.sourceId);
      }
      continue;
    }
    final values = claims.map((claim) => jsonEncode(claim.value)).toSet();
    // Artwork alternatives represent different images of the same proven
    // edition. Choose by stable source ID; retain every distinct claim below.
    if ((!_present(current) || invalidAutomatic) &&
        (values.length == 1 ||
            field == 'artworkUrl' ||
            field == 'durationSeconds' &&
                claims.every((claim) => _seconds(claim.value) != null) &&
                claims
                            .map((claim) => _seconds(claim.value)!)
                            .reduce((a, b) => a > b ? a : b) -
                        claims
                            .map((claim) => _seconds(claim.value)!)
                            .reduce((a, b) => a < b ? a : b) <=
                    3)) {
      metadata[field] = claims.first.value;
      origins[field] = claims.first.sourceId;
    }
    for (final claim in claims) {
      if (jsonEncode(metadata[field]) == jsonEncode(claim.value)) {
        contributors.putIfAbsent(field, () => {}).add(claim.sourceId);
      }
    }
    final chosen = metadata[field];
    if (invalidAutomatic ||
        values.length > 1 ||
        _present(chosen) &&
            claims.any(
              (claim) => jsonEncode(claim.value) != jsonEncode(chosen),
            )) {
      final alternatives =
          conflicts.putIfAbsent(
                field,
                () => <dynamic>[
                  if (_present(current) &&
                      song.extra['fieldOrigins'] is Map &&
                      jsonMap(song.extra['fieldOrigins'])[field] is String)
                    {
                      'sourceId': jsonMap(song.extra['fieldOrigins'])[field],
                      'value': current,
                    },
                ],
              )
              as List;
      final seen = alternatives.map(jsonEncode).toSet();
      for (final claim in claims) {
        final value = {'sourceId': claim.sourceId, 'value': claim.value};
        if (seen.add(jsonEncode(value))) alternatives.add(value);
      }
    }
  }
  return song.copyWith(
    metadata: metadata,
    revision: song.revision,
    updatedAt: song.updatedAt,
    extra: {
      ...song.extra,
      'fieldOrigins': origins,
      'fieldContributors': {
        for (final entry in contributors.entries)
          entry.key: entry.value.toList()..sort(),
      },
      if (conflicts.isNotEmpty) 'conflicts': conflicts,
    },
  );
}

/// Album, duration and artwork shown on a search result or version card.
class DisplayMetadata {
  const DisplayMetadata({this.album, this.durationSeconds, this.artworkUrl});
  final String? album, artworkUrl;
  final double? durationSeconds;
  bool get isComplete =>
      album != null && durationSeconds != null && artworkUrl != null;
}

/// Fills one row's missing display facts from other rows of the same song,
/// such as another catalog's hit in the same search. Like
/// [enrichCombinedDisplayMetadata] this is display only: candidates, their
/// identities and saved provenance are unchanged, and nothing here is
/// recording evidence.
///
/// A donor must have the same title and artist, compatible explicit editions,
/// no conflicting recording IDs, and must not contradict a known album or
/// duration (within 3 seconds). Known facts are never replaced. Once an album
/// is known, donors naming another album are skipped, so artwork and duration
/// stay with one release; donors from the row's own album are tried first.
DisplayMetadata displayMetadataFor(
  SongCandidate target, [
  Iterable<SongCandidate> donors = const [],
]) {
  String? artworkOf(SongCandidate candidate) {
    final value = candidate.metadata['artworkUrl'];
    return _secureArtwork(value) ? (value as String).trim() : null;
  }

  var album = _album(target);
  var duration = _duration(target);
  var artwork = artworkOf(target);
  const excludedScopes = {
    'historicalText',
    'composition',
    'work',
    'artist',
    'image',
    'arrangement',
  };
  bool excluded(SongCandidate candidate) =>
      candidate.providerId == 'wikisource' ||
      excludedScopes.contains(candidate.metadata['identityScope']) ||
      excludedScopes.contains(candidate.extra['identityScope']) ||
      candidate.metadata['pendingMatchCheck'] == true ||
      candidate.extra['pendingMatchCheck'] == true;
  final title = _identity(target.title), artist = _identity(target.artist);
  if (title.isEmpty || artist.isEmpty || excluded(target)) {
    return DisplayMetadata(
      album: album,
      durationSeconds: duration,
      artworkUrl: artwork,
    );
  }
  final targetAlbum = album == null ? null : _identity(album);
  final ordered = donors.toList().asMap().entries.toList()
    ..sort((a, b) {
      int rank(SongCandidate candidate) {
        final found = _album(candidate);
        return targetAlbum != null &&
                found != null &&
                _identity(found) == targetAlbum
            ? 0
            : 1;
      }

      final score = rank(a.value).compareTo(rank(b.value));
      return score != 0 ? score : a.key.compareTo(b.key);
    });
  for (final donor in ordered.map((entry) => entry.value)) {
    if (album != null && duration != null && artwork != null) break;
    if (excluded(donor) ||
        title != _identity(donor.title) ||
        artist != _identity(donor.artist) ||
        _conflictingIds(target, donor) ||
        !explicitEditionsCompatible(target, donor)) {
      continue;
    }
    final donorAlbum = _album(donor), donorDuration = _duration(donor);
    if (album != null &&
        donorAlbum != null &&
        _identity(album) != _identity(donorAlbum)) {
      continue;
    }
    if (duration != null &&
        donorDuration != null &&
        (duration - donorDuration).abs() > 3) {
      continue;
    }
    album ??= donorAlbum;
    duration ??= donorDuration;
    artwork ??= artworkOf(donor);
  }
  return DisplayMetadata(
    album: album,
    durationSeconds: duration,
    artworkUrl: artwork,
  );
}
