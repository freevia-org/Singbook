import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_maintenance.dart';

void main() {
  group('SourceMaintenanceHarness', () {
    test('reports healthy extraction with only shape metadata', () async {
      final report = await _runWith(_Provider());
      final probe = _probe(report);
      expect(probe['status'], 'healthy');
      expect(probe['bodyCharacters'], 19);
      expect(probe['candidateId'], startsWith('sha256:'));
      expect(probe.containsKey('body'), isFalse);
    });

    test(
      'reports disappearance of a required field as schema change',
      () async {
        final report = await _runWith(_Provider(body: ''));
        expect(_probe(report)['status'], 'changed_schema');
        expect(_probe(report)['missingFields'], ['body']);
      },
    );

    test('rejects a resolved song identity that changed', () async {
      final report = await _runWith(_Provider(resolvedId: 'other'));
      expect(_probe(report)['status'], 'identity_mismatch');
      expect(_probe(report)['reason'], 'resolved_candidate_changed');
    });

    test('reports a missing required metadata path as schema change', () async {
      final report = await SourceMaintenanceHarness(
        providers: [_Provider()],
      ).run(_catalog(requiredMetadataFields: ['license.status']));
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['missingMetadataFields'], ['license.status']);
    });

    test('does not accept raw timing without parsed cues', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(timingTracks: [_timing(cues: const [])]),
        ],
      ).run(_catalog(requiredFields: ['body', 'metadata', 'lineTiming']));
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['missingFields'], ['lineTiming']);
    });

    test('does not accept cues without retained raw timing data', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(timingTracks: [_timing(raw: '')]),
        ],
      ).run(_catalog(requiredFields: ['body', 'metadata', 'lineTiming']));
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['missingFields'], ['lineTiming']);
    });

    test('rejects unsupported timing granularity', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(timingTracks: [_timing(granularity: 'unsupported')]),
        ],
      ).run(_catalog(requiredFields: ['body', 'metadata', 'lineTiming']));
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['missingFields'], ['lineTiming']);
    });

    test('requires positioned word cues', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(timingTracks: [_timing(granularity: 'word')]),
        ],
      ).run(_catalog(requiredFields: ['body', 'metadata', 'wordTiming']));
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['missingFields'], ['wordTiming']);
    });

    test('one word track can prove its explicit line and word cues', () async {
      final cues = [
        const TimingCue(
          id: 'line-cue',
          occurrenceId: 'line-1',
          text: 'verified line',
          startUs: 1000000,
        ),
        const TimingCue(
          id: 'word-cue',
          occurrenceId: 'line-1',
          text: 'verified',
          startUs: 1000000,
          endUs: 1200000,
          graphemeStart: 0,
          graphemeEnd: 8,
        ),
      ];
      final report =
          await SourceMaintenanceHarness(
            providers: [
              _Provider(
                timingTracks: [_timing(granularity: 'word', cues: cues)],
              ),
            ],
          ).run(
            _catalog(
              capabilities: [
                'catalog',
                'lyrics',
                'metadata',
                'lineTiming',
                'wordTiming',
              ],
              requiredFields: [
                'body',
                'metadata',
                'timing',
                'lineTiming',
                'wordTiming',
              ],
            ),
          );
      final source = (report['sources'] as List).single as JsonMap;
      final coverage = source['coverage'] as JsonMap;
      expect(_probe(report)['status'], 'healthy');
      expect(coverage['verifiedCapabilities'], [
        'lineTiming',
        'lyrics',
        'metadata',
        'wordTiming',
      ]);
      expect(coverage['unverifiedCapabilities'], ['catalog']);
    });

    test('reports observed and unverified advertised capabilities', () async {
      final report =
          await SourceMaintenanceHarness(
            providers: [
              _Provider(timingTracks: [_timing()]),
            ],
          ).run(
            _catalog(
              capabilities: [
                'catalog',
                'lyrics',
                'metadata',
                'lineTiming',
                'wordTiming',
              ],
              requiredFields: ['body', 'metadata', 'lineTiming'],
            ),
          );
      final source = (report['sources'] as List).single as JsonMap;
      final coverage = source['coverage'] as JsonMap;
      expect(source['status'], 'partial_coverage');
      expect(_probe(report)['status'], 'healthy');
      expect(coverage['verifiedCapabilities'], [
        'lineTiming',
        'lyrics',
        'metadata',
      ]);
      expect(coverage['unverifiedCapabilities'], ['catalog', 'wordTiming']);
    });

    test('chords are checked only for chord-specific probes', () async {
      final provider = _Provider();
      final ordinaryProbe =
          await SourceMaintenanceHarness(providers: [provider]).run(
            _catalog(capabilities: ['catalog', 'lyrics', 'chords', 'metadata']),
          );
      final chordProbe = await SourceMaintenanceHarness(providers: [provider])
          .run(
            _catalog(
              capabilities: ['catalog', 'lyrics', 'chords', 'metadata'],
              requiredFields: ['body', 'metadata', 'chords'],
            ),
          );
      expect(_probe(ordinaryProbe)['status'], 'healthy');
      expect(_probe(chordProbe)['status'], 'changed_schema');
      expect(_probe(chordProbe)['missingFields'], ['chords']);
    });

    test(
      'reports missing credentials separately from transient failure',
      () async {
        final missing = await _runWith(
          _Provider(error: const ProviderException('not_configured')),
        );
        final transient = await _runWith(
          _Provider(error: StateError('network')),
        );
        expect(_probe(missing)['status'], 'not_configured');
        expect(_probe(transient)['status'], 'transient_error');
      },
    );

    test('disabled sources are reported as disabled without probing', () async {
      final catalog = _catalog(status: 'disabled');
      final report = await SourceMaintenanceHarness(
        providers: [_Provider()],
      ).run(catalog);
      final source = (report['sources'] as List).single as JsonMap;
      expect(source['status'], 'disabled');
      expect((source['probes'] as List).single['status'], 'disabled');
    });

    test(
      'offline mode reports coverage without claiming live health',
      () async {
        final report = await SourceMaintenanceHarness(
          providers: [_Provider()],
        ).run(_catalog(), offline: true);
        expect(
          (report['sources'] as List).single['status'],
          'offline_unverified',
        );
      },
    );

    test('active source without probes is a coverage gap', () async {
      final report = await SourceMaintenanceHarness(
        providers: [_Provider()],
      ).run(_catalog(includeProbe: false));
      expect((report['sources'] as List).single['status'], 'coverage_gap');
    });
  });
}

Future<JsonMap> _runWith(_Provider provider) =>
    SourceMaintenanceHarness(providers: [provider]).run(_catalog());

JsonMap _probe(JsonMap report) =>
    ((report['sources'] as List).single as JsonMap)['probes'] is List
    ? (((((report['sources'] as List).single as JsonMap)['probes'] as List)
              .single)
          as JsonMap)
    : <String, dynamic>{};

SourceCatalog _catalog({
  String status = 'active',
  bool includeProbe = true,
  List<String> requiredMetadataFields = const [],
  List<String> capabilities = const ['catalog', 'lyrics', 'metadata'],
  List<String> requiredFields = const ['body', 'metadata'],
}) => SourceCatalog.fromJson({
  'schemaVersion': 1,
  'extractionSchemaVersion': 1,
  'revision': 1,
  'publishedAt': '2026-10-15T00:00:00Z',
  'sources': [
    {
      'id': 'fake',
      'name': 'Fake source',
      'adapter': 'builtin',
      'status': status,
      'revision': 1,
      'capabilities': capabilities,
      'enabledByDefault': true,
      'accessMode': 'public',
      'website': 'https://fake.example.org',
      'hosts': [],
      'probes': [
        if (includeProbe)
          {
            'id': 'known-song',
            'candidate': {
              'providerId': 'fake',
              'id': 'song-1',
              'title': 'Known Song',
              'artist': 'Known Artist',
            },
            'expectedTitle': 'Known Song',
            'expectedArtist': 'Known Artist',
            'requiredFields': requiredFields,
            if (requiredMetadataFields.isNotEmpty)
              'requiredMetadataFields': requiredMetadataFields,
          },
      ],
    },
  ],
});

class _Provider implements LyricsProvider {
  _Provider({
    this.body = 'verified lyric body',
    this.resolvedId,
    this.error,
    this.timingTracks = const [],
  });
  final String body;
  final String? resolvedId;
  final Object? error;
  final List<TimingTrack> timingTracks;

  @override
  ProviderDefinition get definition => const ProviderDefinition(
    id: 'fake',
    name: 'Fake source',
    capabilities: {'catalog', 'lyrics', 'metadata'},
  );

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [
    const SongCandidate(
      providerId: 'fake',
      id: 'song-1',
      title: 'Known Song',
      artist: 'Known Artist',
    ),
  ];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async {
    if (error != null) throw error!;
    final resolved = SongCandidate(
      providerId: 'fake',
      id: resolvedId ?? candidate.id,
      title: 'Known Song',
      artist: 'Known Artist',
    );
    return SourceResult(
      candidate: resolved,
      body: body,
      metadata: const {'kind': 'test'},
      timingTracks: timingTracks,
    );
  }
}

TimingTrack _timing({
  String granularity = 'line',
  String raw = '[00:01.00] verified lyric body',
  List<TimingCue>? cues,
}) => TimingTrack(
  id: 'track-1',
  sourceDocumentId: 'song-1',
  sourceLyrics: 'verified lyric body',
  format: 'lrc',
  raw: raw,
  granularity: granularity,
  cues:
      cues ??
      const [
        TimingCue(
          id: 'cue-1',
          occurrenceId: 'line-1',
          text: 'verified lyric body',
          startUs: 1000000,
        ),
      ],
);
