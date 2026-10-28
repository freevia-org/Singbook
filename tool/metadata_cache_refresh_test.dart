// Opt-in, bounded cache-first reads. No production libraries or account writes.
// flutter test tool/metadata_cache_refresh_test.dart \
//   --dart-define=METADATA_REFRESH_RUN=true \
//   --dart-define=METADATA_REFRESH_BUDGET=120
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';
import 'src/metadata_response_cache.dart';
import 'src/metadata_corpus_identity.dart';

const _run = bool.fromEnvironment('METADATA_REFRESH_RUN');
const _ids = String.fromEnvironment('METADATA_REFRESH_IDS');
const _budget = int.fromEnvironment('METADATA_REFRESH_BUDGET');
const _cachePath = String.fromEnvironment(
  'METADATA_REFRESH_CACHE',
  defaultValue: 'artifacts/metadata-accuracy/cache',
);
const _credentials = String.fromEnvironment(
  'METADATA_REFRESH_CREDENTIALS',
  defaultValue: 'config/local.defines.json',
);

void main() {
  test(
    'bounded 100-song source cache refresh',
    () async {
      expect(_budget, greaterThan(0));
      var token = Platform.environment['GENIUS_ACCESS_TOKEN'] ?? '';
      if (token.isEmpty && File(_credentials).existsSync()) {
        token =
            (jsonDecode(File(_credentials).readAsStringSync())
                    as Map)['GENIUS_ACCESS_TOKEN']
                as String? ??
            '';
      }
      if (token.isEmpty) {
        throw StateError(
          'Existing Genius configuration required; no credentials were requested or created.',
        );
      }
      final directory = Directory(_cachePath)..createSync(recursive: true);
      final client = MetadataResponseCacheClient(
        directory,
        offline: false,
        networkBudget: _budget,
      );
      final transport = ProviderTransport(
        client: client,
        hostInterval: const Duration(milliseconds: 700),
        maxRetries: 0,
      );
      final service = SourceDiscoveryService([
        ...createCoreProviders(transport: transport, geniusToken: token),
        ...createExtraProviders(transport: transport),
      ], recordingKeys: RecordingKeyService(transport));
      final corpus =
          (jsonDecode(
                    File(
                      'tool/metadata_accuracy_corpus.json',
                    ).readAsStringSync(),
                  )
                  as Map)['songs']
              as List;
      final outcomes = <Map<String, Object?>>[];
      final previousReport = File('build/metadata_accuracy/report.json');
      final missing = <String>{
        if (previousReport.existsSync())
          for (final row
              in (jsonDecode(previousReport.readAsStringSync()) as Map)['songs']
                  as List)
            if (row['availability'] != null) row['id'] as String,
      };
      final ordered = [...corpus]
        ..sort((a, b) {
          if (_ids.isNotEmpty) {
            final wanted = _ids.split(',');
            final ai = wanted.indexOf(a['id'] as String),
                bi = wanted.indexOf(b['id'] as String);
            final order = (ai < 0 ? 1000 : ai).compareTo(bi < 0 ? 1000 : bi);
            if (order != 0) return order;
          }
          int priority(dynamic s) =>
              int.parse((s['id'] as String).split('-').last) > 88
              ? 0
              : missing.contains(s['id'])
              ? 1
              : 2;
          final order = priority(a).compareTo(priority(b));
          return order != 0
              ? order
              : (a['id'] as String).compareTo(b['id'] as String);
        });
      try {
        for (final raw in ordered) {
          if (_ids.isNotEmpty && !_ids.split(',').contains(raw['id'])) continue;
          if (client.networkAttempts >= _budget) break;
          final song = (raw as Map).cast<String, dynamic>();
          final title = song['title'] as String,
              artist = song['artist'] as String;
          final outcome = <String, Object?>{
            'id': song['id'],
            'title': title,
            'artist': artist,
          };
          try {
            SongCandidate? selected;
            for (final query in ['$title $artist', '$artist $title', title]) {
              final rows = await service.search(query);
              selected = rows
                  .where((c) => matchesCorpusCandidate(song, c))
                  .firstOrNull;
              if (selected != null || client.networkAttempts >= _budget) break;
            }
            final catalogMatched = selected != null;
            final reference = selected ?? corpusRequestCandidate(song);
            outcome.addAll({
              'catalogMatched': catalogMatched,
              'selectionBasis': catalogMatched
                  ? 'matched_catalog_candidate'
                  : 'requested_song_without_catalog_match',
              'candidateProvider': reference.providerId,
              'candidateId': reference.id,
            });
            final results = await service.discover(reference);
            outcome.addAll({
              'status': 'resolved',
              'sources':
                  results.map((r) => r.candidate.providerId).toSet().toList()
                    ..sort(),
            });
          } on ProviderException catch (e) {
            outcome.addAll({'status': 'unavailable', 'code': e.code});
          }
          outcomes.add(outcome);
          // Only public identities and counters, never response lyrics or tokens.
          // ignore: avoid_print
          print(
            'CACHE_REFRESH ${outcomes.length}/100 ${song['id']} ${outcome['status']} attempts=${client.networkAttempts}/$_budget',
          );
        }
      } finally {
        await transport.close();
        final report = {
          'budget': _budget,
          'networkSendAttempts': client.networkAttempts,
          'refused': client.overBudget,
          'cachedHits': client.hits,
          'statuses': {
            for (final e in client.statusCounts.entries) '${e.key}': e.value,
          },
          'processed': outcomes.length,
          'outcomes': outcomes,
        };
        File(
          'build/metadata_accuracy/cache-refresh.json',
        ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      }
    },
    skip: !_run,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
