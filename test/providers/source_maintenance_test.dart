import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/timing.dart';
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

    test(
      'distinguishes empty search availability from wrong identities',
      () async {
        final empty = await SourceMaintenanceHarness(
          providers: [_Provider(searchResults: const [])],
        ).run(_catalog(searchProbe: true));
        expect(_probe(empty)['status'], 'unavailable');
        expect(_probe(empty)['reason'], 'empty_search_results');

        final wrong = await SourceMaintenanceHarness(
          providers: [
            _Provider(
              searchResults: const [
                SongCandidate(
                  providerId: 'fake',
                  id: 'other',
                  title: 'Other song',
                  artist: 'Other artist',
                ),
              ],
            ),
          ],
        ).run(_catalog(searchProbe: true));
        expect(_probe(wrong)['status'], 'identity_mismatch');
        expect(_probe(wrong)['reason'], 'expected_candidate_not_found');
      },
    );

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

    test('retains unsupported TTML sequence without verifying timing', () async {
      const raw =
          '<tt><body timeContainer="seq"><p begin="1s">Synthetic words</p></body></tt>';
      final track = parseTtml(raw, sourceDocumentId: 'test-sequence');
      expect(track.status, TimingStatus.unsupported);
      expect(track.cues, isNotEmpty);
      expect(track.raw, raw);
      final report =
          await SourceMaintenanceHarness(
            providers: [
              _Provider(timingTracks: [track]),
            ],
          ).run(
            _catalog(
              requiredFields: ['body', 'timing', 'lineTiming', 'wordTiming'],
            ),
          );
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['missingFields'], [
        'timing',
        'lineTiming',
        'wordTiming',
      ]);
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

    test(
      'reports consent requirements without exposing other error messages',
      () async {
        final consent = await _runWith(
          _Provider(
            error: const ProviderException('blocked', 'consent_required'),
          ),
        );
        expect(_probe(consent)['status'], 'blocked');
        expect(_probe(consent)['reason'], 'consent_required');
        final other = await _runWith(
          _Provider(
            error: const ProviderException(
              'blocked',
              'sensitive upstream text',
            ),
          ),
        );
        expect(_probe(other)['reason'], 'blocked');
        expect(other.toString(), isNot(contains('sensitive upstream text')));
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

    test('selected ID verifies search among same-name arrangements', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(
            searchResults: const [
              SongCandidate(
                providerId: 'fake',
                id: 'other',
                title: 'Known Song',
                artist: 'Known Artist',
              ),
              SongCandidate(
                providerId: 'fake',
                id: 'song-1',
                title: 'Known Song',
                artist: 'Known Artist',
              ),
            ],
          ),
        ],
      ).run(_catalog(searchAndCandidate: true));
      expect(_probe(report)['status'], 'healthy');
      expect(_probe(report)['verifiedCapabilities'], contains('catalog'));
    });

    test('same names cannot replace the selected search ID', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(
            searchResults: const [
              SongCandidate(
                providerId: 'fake',
                id: 'other',
                title: 'Known Song',
                artist: 'Known Artist',
              ),
            ],
          ),
        ],
      ).run(_catalog(searchAndCandidate: true));
      expect(_probe(report)['reason'], 'expected_candidate_not_found');
    });

    test('repeated selected search ID remains ambiguous', () async {
      const row = SongCandidate(
        providerId: 'fake',
        id: 'song-1',
        title: 'Known Song',
        artist: 'Known Artist',
      );
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(searchResults: const [row, row]),
        ],
      ).run(_catalog(searchAndCandidate: true));
      expect(_probe(report)['status'], 'coverage_gap');
      expect(_probe(report)['reason'], 'ambiguous_candidate');
    });

    test(
      'selected search ID still requires matching title and artist',
      () async {
        for (final row in const [
          SongCandidate(
            providerId: 'fake',
            id: 'song-1',
            title: 'Different Song',
            artist: 'Known Artist',
          ),
          SongCandidate(
            providerId: 'fake',
            id: 'song-1',
            title: 'Known Song',
            artist: 'Different Artist',
          ),
          SongCandidate(
            providerId: 'fake',
            id: 'song-1',
            title: 'Known Song',
            artist: '',
          ),
        ]) {
          final report = await SourceMaintenanceHarness(
            providers: [
              _Provider(searchResults: [row]),
            ],
          ).run(_catalog(searchAndCandidate: true));
          expect(_probe(report)['reason'], 'searched_candidate_changed');
        }
      },
    );

    test(
      'historical search can omit author but resolved author must match',
      () async {
        final report = await SourceMaintenanceHarness(
          providers: [
            _Provider(
              searchResults: const [
                SongCandidate(
                  providerId: 'fake',
                  id: 'song-1',
                  title: 'Known Song',
                  artist: '',
                ),
              ],
            ),
          ],
        ).run(_catalog(searchAndCandidate: true, historicalText: true));
        expect(_probe(report)['status'], 'healthy');
        expect(_probe(report)['verifiedCapabilities'], contains('catalog'));
      },
    );

    test(
      'historical search does not permit a changed resolved author',
      () async {
        final report = await SourceMaintenanceHarness(
          providers: [
            _Provider(
              resolvedArtist: 'Another Author',
              searchResults: const [
                SongCandidate(
                  providerId: 'fake',
                  id: 'song-1',
                  title: 'Known Song',
                  artist: '',
                ),
              ],
            ),
          ],
        ).run(_catalog(searchAndCandidate: true, historicalText: true));
        expect(_probe(report)['status'], 'identity_mismatch');
        expect(_probe(report)['reason'], 'resolved_candidate_changed');
      },
    );

    test('selected ID from another provider cannot verify search', () async {
      final report = await SourceMaintenanceHarness(
        providers: [
          _Provider(
            searchResults: const [
              SongCandidate(
                providerId: 'another',
                id: 'song-1',
                title: 'Known Song',
                artist: 'Known Artist',
              ),
            ],
          ),
        ],
      ).run(_catalog(searchAndCandidate: true));
      expect(_probe(report)['reason'], 'expected_candidate_not_found');
    });

    test(
      'selected search ID must retain expected album and duration',
      () async {
        for (final row in const [
          SongCandidate(
            providerId: 'fake',
            id: 'song-1',
            title: 'Known Song',
            artist: 'Known Artist',
            album: 'Different Album',
            durationSeconds: 200,
          ),
          SongCandidate(
            providerId: 'fake',
            id: 'song-1',
            title: 'Known Song',
            artist: 'Known Artist',
            album: 'Known Album',
            durationSeconds: 250,
          ),
        ]) {
          final report =
              await SourceMaintenanceHarness(
                providers: [
                  _Provider(searchResults: [row]),
                ],
              ).run(
                _catalog(
                  searchAndCandidate: true,
                  expectedAlbum: 'Known Album',
                  expectedDuration: 200,
                ),
              );
          expect(_probe(report)['reason'], 'searched_candidate_changed');
        }
      },
    );

    test(
      'successful historical search does not bypass resolved rights checks',
      () async {
        final report = await SourceMaintenanceHarness(
          providers: [
            _Provider(
              error: const ProviderException('rights_review_required'),
              searchResults: const [
                SongCandidate(
                  providerId: 'fake',
                  id: 'song-1',
                  title: 'Known Song',
                  artist: '',
                ),
              ],
            ),
          ],
        ).run(_catalog(searchAndCandidate: true, historicalText: true));
        expect(_probe(report)['status'], 'unavailable');
        expect(_probe(report)['reason'], 'rights_review_required');
        expect(_probe(report)['verifiedCapabilities'], isNull);
      },
    );
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
  bool searchProbe = false,
  bool searchAndCandidate = false,
  bool historicalText = false,
  String? expectedAlbum,
  double? expectedDuration,
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
            if (searchProbe || searchAndCandidate)
              'query': 'Known Song Known Artist',
            if (!searchProbe)
              'candidate': {
                'providerId': 'fake',
                'id': 'song-1',
                'title': 'Known Song',
                'artist': 'Known Artist',
                'album': ?expectedAlbum,
                'durationSeconds': ?expectedDuration,
                if (historicalText)
                  'metadata': {'identityScope': 'historicalText'},
              },
            'expectedTitle': 'Known Song',
            'expectedArtist': 'Known Artist',
            'expectedAlbum': ?expectedAlbum,
            'expectedDurationSeconds': ?expectedDuration,
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
    this.resolvedArtist = 'Known Artist',
    this.error,
    this.timingTracks = const [],
    this.searchResults,
  });
  final String body;
  final String? resolvedId;
  final String resolvedArtist;
  final Object? error;
  final List<TimingTrack> timingTracks;
  final List<SongCandidate>? searchResults;

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
  }) async =>
      searchResults ??
      [
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
      artist: resolvedArtist,
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
