import 'dart:async';
import 'dart:math' as math;
import '../../domain/models.dart';
import '../provider.dart';

class ProviderCheck {
  const ProviderCheck({
    required this.providerId,
    required this.state,
    this.code,
    this.result,
  });
  final String providerId, state;
  final String? code;
  final SourceResult? result;
}

String normalizedIdentity(String text) => text
    .toLowerCase()
    .replaceAll(RegExp("['‘’]"), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();
String _titleKey(String title) => normalizedIdentity(
  title.replaceFirst(
    RegExp(
      r'\s*(?:\((?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\)|\[(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?\]|\s[-–—]\s(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?)\s*$',
      caseSensitive: false,
    ),
    '',
  ),
);
String arrangementTitle(String title) => title
    .replaceFirst(
      RegExp(
        r'\s*(?:\((?:(?:acoustic|live|unplugged|version)\s*)+\)|\[(?:(?:acoustic|live|unplugged|version)\s*)+\]|\s[-–—]\s(?:(?:acoustic|live|unplugged|version)\s*)+)\s*$',
        caseSensitive: false,
      ),
      '',
    )
    .trim();
Set<String> _versions(String value, {bool album = false}) {
  final labels = album
      ? [value]
      : RegExp(
          r'\(([^()]*)\)|\[([^\[\]]*)\]|\s[-–—]\s(.+)$',
        ).allMatches(value).map((m) => m[1] ?? m[2] ?? m[3]!).toList();
  final result = <String>{};
  for (final label in labels) {
    final text = normalizedIdentity(label);
    var remaining = text;
    final found = <String>{};
    for (final marker in [
      'live',
      'acoustic',
      'unplugged',
      'karaoke',
      'instrumental',
      'sped up',
      'slowed',
      'nightcore',
    ]) {
      final matches = RegExp('(?:^|\\s)$marker(?:\\s|\$)').hasMatch(text);
      if (!matches) continue;
      if (album) {
        final explicit =
            RegExp(
              '(?:[\\[(]\\s*|\\s[-–—]\\s+)$marker\\b',
              caseSensitive: false,
            ).hasMatch(value) ||
            (marker == 'live'
                ? RegExp(
                    r'^live(?:\s+\d{4})?\s*$|\blive\s+(?:at|in|from|on)\b|^live\s+\d{4}',
                    caseSensitive: false,
                  ).hasMatch(value)
                : RegExp('^$marker\\b', caseSensitive: false).hasMatch(value));
        if (!explicit) continue;
      }
      final version = marker == 'unplugged' ? 'acoustic' : marker;
      if (album) {
        result.add(version);
      } else {
        found.add(version);
        remaining = remaining.replaceAll(RegExp('\\b$marker\\b'),' ');
      }
    }
    if (!album && remaining.replaceAll(RegExp(r'\b(?:version|recording|performance|session)\b'),' ').trim().isEmpty) {
      result.addAll(found);
    }
  }
  return result;
}

bool sameSong(SongCandidate selected, SongCandidate result) {
  for (final id in selected.recordingIds.entries) {
    if (result.recordingIds.containsKey(id.key) && result.recordingIds[id.key] != id.value) {
      return false;
    }
  }
  if (_titleKey(selected.title) != _titleKey(result.title) ||
      normalizedIdentity(selected.artist) !=
          normalizedIdentity(result.artist)) {
    return false;
  }
  final a = _versions(selected.album ?? '', album: true),
      b = _versions(result.album ?? '', album: true);
  if (a.difference(b).isNotEmpty || b.difference(a).isNotEmpty) {
    if (selected.album != null && result.album != null) return false;
    if (selected.identity != result.identity &&
        !_versions(selected.title).containsAll({...a, ...b})) {
      return false;
    }
  }
  final sa = selected.durationSeconds, sb = result.durationSeconds;
  if (sa != null &&
      sb != null &&
      (sa - sb).abs() > math.min(15, math.max(8, sa * 0.02))) {
    return false;
  }
  return true;
}

bool sameArrangement(
  SongCandidate selected,
  SongCandidate result,
  LyricsProvider provider,
) {
  if (!provider.definition.capabilities.contains('chords') ||
      normalizedIdentity(selected.artist) !=
          normalizedIdentity(result.artist)) {
    return false;
  }
  final a = arrangementTitle(selected.title);
  var b = arrangementTitle(result.title);
  if (a != selected.title) {
    b = b.replaceFirst(RegExp(r'\s+acoustic$', caseSensitive: false), '');
  }
  return _titleKey(a) == _titleKey(b);
}

bool _sameAlbum(SongCandidate a, SongCandidate b) =>
    a.album != null &&
    b.album != null &&
    normalizedIdentity(a.album!) == normalizedIdentity(b.album!);
double _rank(SongCandidate selection, SongCandidate song) =>
    (_sameAlbum(selection, song) ? 100 : 0) +
    (normalizedIdentity(selection.title) == normalizedIdentity(song.title)
        ? 20
        : 0) +
    (selection.durationSeconds != null && song.durationSeconds != null
        ? 40 - (selection.durationSeconds! - song.durationSeconds!).abs()
        : 0);
SourceResult _matched(
  SourceResult result,
  MatchKind kind,
  String reason, {
  JsonMap extra = const {},
}) => SourceResult(
  candidate: result.candidate,
  body: result.body,
  metadata: result.metadata,
  timingTracks: result.timingTracks,
  matchKind: kind,
  matchReason: reason,
  attribution: result.attribution,
  retrievedAt: result.retrievedAt,
  extra: {...result.extra, ...extra},
);

Future<SourceResult> findMatchingSource(
  LyricsProvider provider,
  SongCandidate selection, {
  CancellationToken? cancel,
}) async {
  final metadataOnly =
      provider.definition.capabilities.contains('metadata') &&
      !provider.definition.capabilities.contains('lyrics') &&
      !provider.definition.capabilities.contains('chords');
  if (metadataOnly) {
    // Enrichment adapters have source-specific ambiguity checks and identity
    // lookup (for example MusicBrainz IDs or an exact Commons filename). Do not
    // bypass those checks by selecting the first generic search hit here.
    final result = await provider.resolve(selection, cancel: cancel);
    final song = result.candidate;
    if (song.providerId != provider.definition.id ||
        !sameSong(selection, song)) {
      return _matched(result, MatchKind.rejected, 'identity_mismatch');
    }
    if (result.metadata.isEmpty) throw const ProviderException('unavailable');
    final sharedId = selection.recordingIds.entries.any(
      (e) => song.recordingIds[e.key] == e.value,
    );
    final recordingScope = song.metadata['identityScope'] == 'recording';
    final exact =
        recordingScope &&
        (selection.identity == song.identity ||
            sharedId ||
            _sameAlbum(selection, song) &&
                selection.durationSeconds != null &&
                song.durationSeconds != null &&
                (selection.durationSeconds! - song.durationSeconds!).abs() <=
                    3);
    return _matched(
      result,
      exact ? MatchKind.sameRecording : MatchKind.sameSong,
      exact ? 'same_recording' : 'same_song',
    );
  }
  var attempts = 0;
  final seen = <String>{};
  // Every soft failure is kept (candidate id and code), not just the first.
  final unresolved = <ProviderException>[];
  Future<SourceResult?> attempt(SongCandidate candidate) async {
    cancel?.throwIfCancelled();
    if (!seen.add(candidate.id) ||
        candidate.metadata['instrumental'] == true ||
        candidate.metadata['hasLyrics'] == false ||
        attempts >= 3) {
      return null;
    }
    attempts++;
    SourceResult result;
    try {
      result = await provider.resolve(candidate, cancel: cancel);
    } on ProviderException catch (e) {
      if (e.code == 'unavailable') return null;
      if (e.code == 'extraction_failed') {
        unresolved.add(
          ProviderException(
            e.code,
            '${candidate.id}${e.message.isEmpty ? '' : ' (${e.message})'}',
          ),
        );
        return null;
      }
      rethrow;
    }
    final song = result.candidate,
        strict = sameSong(selection, result.candidate);
    if (song.providerId != provider.definition.id ||
        song.id != candidate.id ||
        !sameSong(candidate, song) ||
        (!strict && !sameArrangement(selection, song, provider))) {
      return _matched(result, MatchKind.rejected, 'identity_mismatch');
    }
    if (result.body.trim().isEmpty && !result.timingTracks.any((track)=>track.raw?.isNotEmpty == true)) {
      return null;
    }
    final scope = song.metadata['identityScope'];
    final exact = selection.identity == song.identity &&
        !{'composition','arrangement','image','work'}.contains(scope) &&
        !provider.definition.capabilities.contains('chords');
    final verifiedRecording =
        _sameAlbum(selection, song) &&
        selection.durationSeconds != null &&
        song.durationSeconds != null &&
        (selection.durationSeconds! - song.durationSeconds!).abs() <= 3 &&
        normalizedIdentity(selection.title) == normalizedIdentity(song.title);
    // Artist/title-only APIs cannot establish which recording supplied lyrics.
    final recording = provider.definition.id != 'lyricsovh' &&
        !{'composition','arrangement','image','work'}.contains(scope) &&
        (exact || verifiedRecording);
    return _matched(
      result,
      recording ? MatchKind.sameRecording : MatchKind.sameSong,
      recording
          ? 'same_recording'
          : strict
          ? 'same_song'
          : 'arrangement_requires_agreement',
      extra: !strict ? {'requiresLyricsAgreement': true} : {},
    );
  }

  if (selection.providerId == provider.definition.id) {
    final result = await attempt(selection);
    if (result != null) return result;
  }
  final artist = selection.artist.length <= 100
      ? selection.artist
      : selection.artist.substring(0, 100);
  var title = provider.definition.capabilities.contains('chords')
      ? arrangementTitle(selection.title)
      : selection.title;
  if (title.length > 199 - artist.length) {
    title = title.substring(0, 199 - artist.length);
  }
  final results = await provider.search('$title $artist', cancel: cancel);
  final candidates =
      results
          .take(100)
          .where(
            (s) =>
                s.providerId == provider.definition.id &&
                (sameSong(selection, s) ||
                    sameArrangement(selection, s, provider)),
          )
          .toList()
        ..sort((a, b) => _rank(selection, b).compareTo(_rank(selection, a)));
  for (final candidate in candidates) {
    if (attempts >= 3) break;
    final result = await attempt(candidate);
    if (result != null) return result;
  }
  if (unresolved.isEmpty) throw const ProviderException('unavailable');
  // 'blocked' is rethrown at once (hammering a bot wall helps nobody); layout
  // failures from every attempted candidate are reported together.
  throw ProviderException(
    unresolved.first.code,
    unresolved.map((e) => '${e.code}: ${e.message}').join('; '),
  );
}

/// Shared by the UI and headless device tests; no result is fabricated on failure.
class SourceDiscoveryService {
  SourceDiscoveryService(this.providers);
  final List<LyricsProvider> providers;
  List<ProviderDefinition> get definitions =>
      providers.map((p) => p.definition).toList();
  Future<List<SongCandidate>> search(
    String query, {
    String providerId = 'genius',
    CancellationToken? cancel,
  }) async {
    final matches = providers.where((p) => p.definition.id == providerId);
    if (matches.isEmpty) throw const ProviderException('not_configured');
    return matches.single.search(query, cancel: cancel);
  }

  Future<List<SourceResult>> discover(
    SongCandidate selection, {
    Set<String>? enabledIds,
    void Function(ProviderCheck)? onProgress,
    CancellationToken? cancel,
  }) async {
    final active = providers
        .where(
          (p) =>
              enabledIds?.contains(p.definition.id) ??
              p.definition.enabledByDefault,
        )
        .toList();
    final results = <SourceResult>[];
    var index = 0;
    for (final provider in active) {
      onProgress?.call(
        ProviderCheck(providerId: provider.definition.id, state: 'pending'),
      );
    }
    Future<void> worker() async {
      while (index < active.length) {
        cancel?.throwIfCancelled();
        final provider = active[index++], local = CancellationToken();
        cancel?.cancelled.then((_) => local.cancel());
        try {
          final result =
              await findMatchingSource(
                provider,
                selection,
                cancel: local,
              ).timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  local.cancel();
                  throw const ProviderException('timeout');
                },
              );
          cancel?.throwIfCancelled();
          results.add(result);
          onProgress?.call(
            ProviderCheck(
              providerId: provider.definition.id,
              state: result.matchKind == MatchKind.rejected
                  ? 'unavailable'
                  : 'found',
              code: result.matchKind == MatchKind.rejected
                  ? 'identity_mismatch'
                  : null,
              result: result,
            ),
          );
        } on ProviderException catch (e) {
          cancel?.throwIfCancelled();
          onProgress?.call(
            ProviderCheck(
              providerId: provider.definition.id,
              state: e.code == 'unavailable' ? 'unavailable' : 'failed',
              code: e.code,
            ),
          );
        } catch (_) {
          cancel?.throwIfCancelled();
          onProgress?.call(
            ProviderCheck(
              providerId: provider.definition.id,
              state: 'failed',
              code: 'invalid_response',
            ),
          );
        }
      }
    }

    await Future.wait(
      List.generate(math.min(3, active.length), (_) => worker()),
    );
    // Chord sources describe arrangements: corroborate their words against the
    // strongest full lyric reference before making them eligible for combining.
    final references =
        results
            .where(
              (r) =>
                  r.matchKind != MatchKind.rejected &&
                  !r.hasChords &&
                  r.body.trim().isNotEmpty && _words(r.body).toSet().length >= 12,
            )
            .toList()
          ..sort(
            (a, b) => _words(b.body).toSet().length.compareTo(_words(a.body).toSet().length),
          );
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      if (!result.hasChords || result.matchKind == MatchKind.rejected) continue;
      if (references.isEmpty) {
        if (result.extra['requiresLyricsAgreement'] == true) {
          results[i] = _matched(
            result,
            MatchKind.rejected,
            'uncorroborated_arrangement',
          );
        }
      } else if (!_agreement(result.body, references.first.body)) {
        results[i] = _matched(
          result,
          MatchKind.rejected,
          'incomplete_or_different_lyrics',
        );
      }
      if (results[i].matchKind == MatchKind.rejected) {
        onProgress?.call(
          ProviderCheck(
            providerId: result.candidate.providerId,
            state: 'unavailable',
            code: results[i].matchReason,
            result: results[i],
          ),
        );
      }
    }
    return results;
  }
}

List<String> _words(String body) => normalizedIdentity(
  body
      .replaceAll(RegExp(r'\{[^}\n]*\}'), ' ')
      .replaceAll(RegExp(r'(?<!\\)\[[^\]\n]*\]'), ''),
).split(' ').where((w) => w.isNotEmpty).toList();
bool _agreement(String chart, String reference) {
  final a = _words(chart),
      b = _words(reference),
      aa = a.toSet(),
      bb = b.toSet(),
      common = a.toSet().intersection(b.toSet());
  if (common.length < 12 ||
      common.length / aa.length < .8 ||
      common.length / bb.length < .85) {
    return false;
  }
  Set<String> bigrams(List<String> words) => {
    for (var i = 1; i < words.length; i++) '${words[i - 1]} ${words[i]}',
  };
  final ab = bigrams(a),
      ba = bigrams(b),
      both = bigrams(a).intersection(bigrams(b));
  return ab.isNotEmpty &&
      ba.isNotEmpty &&
      both.length / ab.length >= .65 &&
      both.length / ba.length >= .65;
}
