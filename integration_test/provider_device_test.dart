import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/domain/combine.dart';
import 'package:singbook/domain/chordpro.dart';
import 'package:singbook/domain/arrangement.dart';

String _normCanaryIdentity(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

List<String> _wordsCanary(String body) => plainLyrics(body)
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .split(' ')
    .where((word) => word.isNotEmpty)
    .toList();

double _coverageCanary(List<String> left, List<String> right) {
  final available = <String, int>{};
  for (final word in right) {
    available[word] = (available[word] ?? 0) + 1;
  }
  var matched = 0;
  for (final word in left) {
    if ((available[word] ?? 0) > 0) {
      matched++;
      available[word] = available[word]! - 1;
    }
  }
  return left.isEmpty ? 0 : matched / left.length;
}

List<String> _bigramsCanary(List<String> words) => [
  for (var index = 0; index + 1 < words.length; index++)
    '${words[index]} ${words[index + 1]}',
];

/// MANUAL LIVE SMOKE TEST. It talks to the real third-party providers over the
/// internet, so it is NOT part of CI and a red run can simply mean an outage or
/// a blocked provider. It therefore adapts to the provider registry (no
/// hard-coded counts), skips when the Genius token is missing or Genius cannot
/// find the reference song, and tolerates individual providers being down.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native provider discovery keeps real lyrics and timing',
    (tester) async {
      await tester.runAsync(() async {
        const token = String.fromEnvironment('GENIUS_ACCESS_TOKEN');
        if (token.isEmpty) {
          markTestSkipped(
            'GENIUS_ACCESS_TOKEN missing: use --dart-define-from-file=config/local.defines.json',
          );
          return;
        }
        final transport = ProviderTransport();
        final providers = [
          ...createCoreProviders(transport: transport, geniusToken: token),
          ...createExtraProviders(transport: transport),
        ];
        expect(providers, isNotEmpty);
        expect(
          providers.map((p) => p.definition.id).toSet().length,
          providers.length,
          reason: 'Provider ids must be unique.',
        );
        final service = SourceDiscoveryService(providers),
            checks = <ProviderCheck>[];
        try {
          final found = await service.search('Lonely Stranger Eric Clapton');
          final selection = found
              .where(
                (s) =>
                    s.artist.toLowerCase() == 'eric clapton' &&
                    s.title.toLowerCase().startsWith('lonely stranger'),
              )
              .firstOrNull;
          if (selection == null) {
            markTestSkipped(
              'Genius did not return the reference song (outage, token or catalog change).',
            );
            return;
          }
          final results = await service.discover(
            selection,
            enabledIds: providers.map((p) => p.definition.id).toSet(),
            onProgress: (check) {
              checks.add(check);
              if (check.state != 'pending') {
                debugPrint(
                  'VERSE_PROVIDER ${jsonEncode({'id': check.providerId, 'state': check.state, 'code': check.code, if (check.result != null) 'match': check.result!.matchKind.name, if (check.result != null) 'chords': check.result!.hasChords, if (check.result != null) 'characters': check.result!.body.length, if (check.result != null) 'timingTracks': check.result!.timingTracks.length, if (check.result != null) 'cues': check.result!.timingTracks.fold<int>(0, (sum, t) => sum + t.cues.length), if (check.result != null) 'metadataOnly': check.result!.body.isEmpty && check.result!.metadata.isNotEmpty})}',
                );
              }
            },
          );
          final usable = results.any(
            (r) =>
                r.matchKind != MatchKind.rejected && r.body.trim().isNotEmpty,
          );
          if (!usable) {
            final settled = checks.where((c) => c.state != 'pending');
            // Every provider failed with an error code: treat it as an outage
            // of the test environment rather than a regression.
            if (settled.isNotEmpty && settled.every((c) => c.code != null)) {
              markTestSkipped(
                'Every provider reported a failure code; assuming an outage.',
              );
              return;
            }
          }
          expect(
            usable,
            true,
            reason: 'At least one real provider must return usable lyrics.',
          );
          // A denial/outage may legitimately produce a terminal failure; an
          // uncaught HTTP103 parser crash is never acceptable. Only require
          // that a registered songsterr provider reaches a terminal state.
          if (providers.any((p) => p.definition.id == 'songsterr')) {
            expect(
              checks.any(
                (c) => c.providerId == 'songsterr' && c.state != 'pending',
              ),
              true,
            );
          }
          for (final source in results) {
            for (final track in source.timingTracks) {
              expect(
                track.raw,
                isNotNull,
                reason: 'Native import must retain source timing.',
              );
              expect(track.raw!.isNotEmpty, true);
            }
          }
          expect(
            checks
                .where((c) => c.state != 'pending')
                .map((c) => c.providerId)
                .toSet()
                .length,
            providers.length,
            reason: 'Every registered provider must reach a terminal state.',
          );
          final combined = combineSources(selection, results);
          final reopened = ChordProCodec().decode(
            ChordProCodec().encode(combined),
          );
          expect(reopened.timingTracks.length, combined.timingTracks.length);
          final selectedSourceId = combined.extra['selectedSourceId'] as String;
          final excludedIncomplete =
              (combined.extra['excludedIncompleteSourceIds'] as List? ?? [])
                  .whereType<String>()
                  .toSet();
          final eligibleChordCandidates = results.where((source) {
            return source.matchKind != MatchKind.rejected &&
                source.hasChords &&
                _normCanaryIdentity(source.candidate.artist) ==
                    _normCanaryIdentity(selection.artist) &&
                _normCanaryIdentity(source.candidate.title) ==
                    _normCanaryIdentity(selection.title);
          }).toList();
          final lyricReferences =
              results
                  .where(
                    (source) =>
                        source.matchKind != MatchKind.rejected &&
                        source.matchKind != MatchKind.unverified &&
                        !source.hasChords &&
                        _normCanaryIdentity(source.candidate.artist) ==
                            _normCanaryIdentity(selection.artist) &&
                        _normCanaryIdentity(source.candidate.title) ==
                            _normCanaryIdentity(selection.title),
                  )
                  .toList()
                ..sort(
                  (a, b) => plainLyrics(
                    b.body,
                  ).length.compareTo(plainLyrics(a.body).length),
                );
          if (lyricReferences.isNotEmpty) {
            final reference = _wordsCanary(lyricReferences.first.body);
            for (final candidate in eligibleChordCandidates) {
              final chart = _wordsCanary(candidate.body);
              final forward = _coverageCanary(chart, reference);
              final reverse = _coverageCanary(reference, chart);
              final bigramForward = _coverageCanary(
                _bigramsCanary(chart),
                _bigramsCanary(reference),
              );
              final bigramReverse = _coverageCanary(
                _bigramsCanary(reference),
                _bigramsCanary(chart),
              );
              debugPrint(
                'VERSE_CHART_COVERAGE ${jsonEncode({'provider': candidate.candidate.providerId, 'chartTokens': chart.length, 'referenceProvider': lyricReferences.first.candidate.providerId, 'referenceTokens': reference.length, 'forward': forward, 'reverse': reverse, 'bigramForward': bigramForward, 'bigramReverse': bigramReverse, 'clearsCompletenessGates': chart.length < 12 || reference.length < 12 || (forward >= .80 && reverse >= .85 && bigramForward >= .65 && bigramReverse >= .65)})}',
              );
            }
          }
          expect(
            combined.sources.map((source) => source.id).toSet(),
            results
                // Search-evidence-only hits are observations, not documents.
                .where((source) => source.extra['searchEvidenceOnly'] != true)
                .map((source) => source.id)
                .toSet(),
            reason:
                'Combining must retain all provider results for attribution.',
          );
          final selectedSource = results.singleWhere(
            (source) => source.id == selectedSourceId,
          );
          expect(selectedSource.matchKind, isNot(MatchKind.rejected));
          if (combined.hasChords) {
            // The selected lyric source may be enriched by a different chart.
            final chordSources =
                (combined.extra['chordSourceIds'] as List? ?? [])
                    .whereType<String>()
                    .toSet();
            expect(chordSources, isNotEmpty);
            for (final id in chordSources) {
              final source = results.singleWhere((source) => source.id == id);
              expect(source.hasChords, true);
              expect(source.matchKind, isNot(MatchKind.rejected));
            }
          } else {
            for (final candidate in eligibleChordCandidates) {
              expect(
                excludedIncomplete.contains(candidate.id),
                true,
                reason:
                    'A matching chord source must be marked incomplete when no chart is selected.',
              );
            }
          }
          debugPrint(
            'VERSE_COMBINED ${jsonEncode({'sources': combined.sources.length, 'chords': combined.hasChords, 'selectedSource': selectedSourceId, 'excludedIncompleteChordSources': eligibleChordCandidates.where((s) => excludedIncomplete.contains(s.id)).map((s) => s.candidate.providerId).toList(), 'eligibleChordSourceCount': eligibleChordCandidates.length, 'timingTracks': combined.timingTracks.length, 'retainedInSingleFile': reopened.timingTracks.length})}',
          );
        } finally {
          await transport.close();
        }
      });
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    'native open catalog returns an attributed original chord sheet',
    (tester) async {
      await tester.runAsync(() async {
        final transport = ProviderTransport();
        try {
          final provider = SeanMcGrathProvider(transport);
          final candidates = await provider.search('Be Here Soon');
          final song = candidates
              .where((c) => c.title.toLowerCase() == 'be here soon')
              .firstOrNull;
          if (song == null) {
            markTestSkipped(
              'The open catalog did not return the reference song (outage or catalog change).',
            );
            return;
          }
          final result = await provider.resolve(song);
          expect(result.body.trim().isNotEmpty, true);
          expect(result.hasChords, true);
          expect(result.attribution, isNotNull);
          debugPrint(
            'VERSE_OPEN_CANARY ${jsonEncode({'provider': result.candidate.providerId, 'title': result.candidate.title, 'chords': result.hasChords, 'characters': result.body.length, 'metadataFields': result.metadata.keys.toList(), 'hasAttribution': result.attribution != null})}',
          );
        } finally {
          await transport.close();
        }
      });
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
