import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';

Map<String, dynamic> source({
  String id = 'builtin-one',
  String? name,
  String? attribution,
  String accessMode = 'public',
  String adapter = 'builtin',
  String status = 'active',
  int revision = 1,
  List<String> capabilities = const ['lyrics', 'metadata'],
  bool enabled = true,
  List<String> hosts = const [],
  Map<String, dynamic>? extraction,
  List<Map<String, dynamic>> probes = const [],
}) => {
  'id': id,
  'name': name ?? 'Source $id',
  'adapter': adapter,
  'status': status,
  'revision': revision,
  'capabilities': capabilities,
  'enabledByDefault': enabled,
  'accessMode': accessMode,
  'website': 'https://music.example.org/',
  'attribution': ?attribution,
  'hosts': hosts,
  'extraction': ?extraction,
  if (probes.isNotEmpty) 'probes': probes,
};

Map<String, dynamic> catalog(
  int revision,
  List<Map<String, dynamic>> sources,
) => {
  'schemaVersion': 1,
  'extractionSchemaVersion': 1,
  'revision': revision,
  'publishedAt': '2026-10-15T12:00:00.000Z',
  'sources': sources,
};

SourceCatalog parseCatalog(int revision, List<Map<String, dynamic>> sources) =>
    SourceCatalog.fromJson(catalog(revision, sources));

class FakeProvider implements LyricsProvider {
  FakeProvider(this.definition);

  @override
  final ProviderDefinition definition;

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [];

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => throw const ProviderException('unavailable');
}

void main() {
  group('SourceCatalog', () {
    test('parses and round-trips a bounded catalog and probe data', () {
      final raw = catalog(3, [
        source(
          id: 'json-source',
          adapter: 'json',
          hosts: ['api.music.example.org'],
          extraction: {'resultsPath': 'songs', 'bodyPath': 'lyrics'},
          probes: [
            {
              'id': 'smoke',
              'query': 'Song Artist',
              'requiredFields': [
                'body',
                'metadata',
                'lineTiming',
                'wordTiming',
              ],
              'requiredMetadataFields': [
                'recording.id',
                'licensedImages.0.license',
              ],
              'expectedTitle': 'Song',
              'expectedArtist': 'Artist',
              'expectedAlbum': 'Album',
              'expectedDurationSeconds': 244.5,
            },
          ],
          attribution: 'Source attribution text',
        ),
      ]);

      final parsed = SourceCatalog.parse(jsonEncode(raw));
      expect(parsed.revision, 3);
      expect(parsed.schemaVersion, 1);
      expect(parsed.extractionSchemaVersion, 1);
      expect(parsed.sources.single.isActive, isTrue);
      expect(parsed.sources.single.probes.single['requiredFields'], [
        'body',
        'metadata',
        'lineTiming',
        'wordTiming',
      ]);
      expect(parsed.sources.single.probes.single['requiredMetadataFields'], [
        'recording.id',
        'licensedImages.0.license',
      ]);
      expect(parsed.sources.single.probes.single['expectedAlbum'], 'Album');
      expect(
        parsed.sources.single.probes.single['expectedDurationSeconds'],
        244.5,
      );
      expect(parsed.sources.single.attribution, 'Source attribution text');
      expect(
        SourceCatalog.fromJson(parsed.toJson()).sameContent(parsed),
        isTrue,
      );
      expect(parsed.sources.single.definition.id, 'json-source');
    });

    test('accepts file-import probes and artistless metadata candidates', () {
      final parsed = parseCatalog(1, [
        source(
          id: 'import-only',
          capabilities: ['fileImport'],
          probes: [
            {'id': 'manual-import'},
          ],
        ),
        source(
          id: 'artwork',
          capabilities: ['artwork', 'metadata'],
          probes: [
            {
              'id': 'exact-file',
              'candidate': {
                'providerId': 'artwork',
                'id': 'file-1',
                'title': 'Portrait',
                'artist': '',
              },
              'requiredFields': ['metadata'],
            },
          ],
        ),
      ]);
      expect(parsed.sources, hasLength(2));
      expect(parsed.sources.first.probes.single['id'], 'manual-import');

      expect(
        () => parseCatalog(1, [
          source(
            id: 'lyrics',
            capabilities: ['lyrics'],
            probes: [
              {
                'id': 'missing-artist',
                'candidate': {
                  'providerId': 'lyrics',
                  'id': 'song-1',
                  'title': 'Song',
                  'artist': '',
                },
              },
            ],
          ),
        ]),
        throwsFormatException,
      );
    });

    test('rejects unsupported schemas, duplicate ids, and unsafe hosts', () {
      expect(
        () => SourceCatalog.fromJson({...catalog(1, []), 'schemaVersion': 2}),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [source(), source()]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            id: 'json-source',
            adapter: 'json',
            hosts: ['127.0.0.1'],
            extraction: {'lyrics': 'body'},
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            id: 'json-source',
            adapter: 'json',
            hosts: ['api.private.internal'],
            extraction: {'lyrics': 'body'},
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            id: 'json-source',
            adapter: 'json',
            hosts: ['api.example.org'],
          ),
        ]),
        throwsFormatException,
      );
    });

    test('rejects bad probe fields, timestamps, and oversized catalogs', () {
      expect(
        () => parseCatalog(1, [
          source(
            probes: [
              {
                'id': 'bad',
                'requiredFields': ['cookies'],
              },
            ],
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            probes: [
              {
                'id': 'bad-duration',
                'query': 'Song Artist',
                'expectedDurationSeconds': 0,
              },
            ],
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            probes: [
              {
                'id': 'missing-input',
                'requiredFields': ['body'],
              },
            ],
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            probes: [
              {'id': 'too-long-query', 'query': 'x' * 201},
            ],
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => parseCatalog(1, [
          source(
            probes: [
              {
                'id': 'unsafe-path',
                'query': 'Song Artist',
                'requiredMetadataFields': ['licensedImages[*].license'],
              },
            ],
          ),
        ]),
        throwsFormatException,
      );
      expect(
        () => SourceCatalog.fromJson({
          ...catalog(1, []),
          'publishedAt': '2026-10-15T12:00:00+02:00',
        }),
        throwsFormatException,
      );
      expect(
        () => SourceCatalog.parse(' ' * (512 * 1024 + 1)),
        throwsFormatException,
      );
    });
  });

  group('SourceCatalogRuntime', () {
    final builtinDefinition = const ProviderDefinition(
      id: 'builtin-one',
      name: 'Original builtin',
      capabilities: {'lyrics', 'chords'},
    );

    test(
      'uses full snapshot semantics and honors builtin capability changes',
      () {
        var factories = 0;
        final runtime = SourceCatalogRuntime(
          builtins: [FakeProvider(builtinDefinition)],
          createProvider: (entry) {
            factories++;
            return FakeProvider(entry.definition);
          },
        );
        expect(runtime.providers.single.definition.name, 'Original builtin');

        runtime.apply(
          parseCatalog(1, [
            source(capabilities: ['lyrics'], enabled: false),
            source(
              id: 'remote',
              adapter: 'json',
              hosts: ['api.music.example.org'],
              extraction: {'path': 'lyrics'},
            ),
          ]),
        );
        expect(runtime.providers.map((provider) => provider.definition.id), [
          'builtin-one',
          'remote',
        ]);
        expect(runtime.providers.first.definition.capabilities, {'lyrics'});
        expect(runtime.providers.first.definition.enabledByDefault, isFalse);
        expect(factories, 1);

        runtime.apply(
          parseCatalog(2, [
            source(status: 'disabled', revision: 2),
            source(
              id: 'remote',
              adapter: 'json',
              status: 'retired',
              revision: 2,
              hosts: ['api.music.example.org'],
              extraction: {'path': 'lyrics'},
            ),
          ]),
        );
        expect(runtime.providers, isEmpty);

        runtime.apply(parseCatalog(3, []));
        expect(runtime.providers, isEmpty);
      },
    );

    test(
      'does not construct inactive adapters and applies failures atomically',
      () {
        var shouldThrow = false;
        final runtime = SourceCatalogRuntime(
          builtins: [FakeProvider(builtinDefinition)],
          createProvider: (entry) {
            if (shouldThrow) throw StateError('factory failed');
            return FakeProvider(entry.definition);
          },
        );
        runtime.apply(
          parseCatalog(1, [
            source(),
            source(
              id: 'disabled-json',
              adapter: 'json',
              status: 'disabled',
              hosts: ['api.music.example.org'],
              extraction: {'path': 'lyrics'},
            ),
            source(
              id: 'remote',
              adapter: 'json',
              hosts: ['api.music.example.org'],
              extraction: {'path': 'lyrics'},
            ),
          ]),
        );
        expect(runtime.providers.map((provider) => provider.definition.id), [
          'builtin-one',
          'remote',
        ]);
        final previous = runtime.catalog;
        shouldThrow = true;
        expect(
          () => runtime.apply(
            parseCatalog(2, [
              source(),
              source(
                id: 'next-remote',
                adapter: 'html',
                hosts: ['www.music.example.org'],
                extraction: {'selector': '.lyrics'},
              ),
            ]),
          ),
          throwsStateError,
        );
        expect(identical(runtime.catalog, previous), isTrue);
        expect(runtime.providers.map((provider) => provider.definition.id), [
          'builtin-one',
          'remote',
        ]);
      },
    );

    test('prepare validates a next snapshot without publishing it', () {
      final runtime = SourceCatalogRuntime(
        builtins: [FakeProvider(builtinDefinition)],
        createProvider: (entry) => FakeProvider(entry.definition),
      );
      final first = parseCatalog(1, [source()]);
      runtime.apply(first);
      final next = parseCatalog(2, [
        source(),
        source(
          id: 'remote',
          adapter: 'json',
          hosts: ['api.music.example.org'],
          extraction: {'path': 'lyrics'},
        ),
      ]);

      final prepared = runtime.prepare(next);
      expect(prepared.map((provider) => provider.definition.id), [
        'builtin-one',
        'remote',
      ]);
      expect(identical(runtime.catalog, first), isTrue);
      expect(runtime.providers.map((provider) => provider.definition.id), [
        'builtin-one',
      ]);
    });

    test(
      'rejects rollback, same-revision mutation, and unknown builtin ids',
      () {
        final runtime = SourceCatalogRuntime(
          builtins: [FakeProvider(builtinDefinition)],
          createProvider: (entry) => FakeProvider(entry.definition),
        );
        final first = parseCatalog(5, [source()]);
        runtime.apply(first);
        runtime.apply(
          parseCatalog(5, [source()]),
        ); // identical revision is a no-op
        expect(identical(runtime.catalog, first), isTrue);
        expect(
          () => runtime.apply(parseCatalog(4, [source()])),
          throwsStateError,
        );
        expect(
          () => runtime.apply(parseCatalog(5, [source(name: 'Changed')])),
          throwsStateError,
        );
        expect(
          () => runtime.apply(parseCatalog(6, [source(id: 'unknown-builtin')])),
          throwsStateError,
        );
        expect(identical(runtime.catalog, first), isTrue);
      },
    );

    test(
      'requires source revision increases for changes and prevents re-add rollback',
      () {
        final runtime = SourceCatalogRuntime(
          builtins: [FakeProvider(builtinDefinition)],
          createProvider: (entry) => FakeProvider(entry.definition),
        );
        runtime.apply(parseCatalog(1, [source(revision: 5)]));
        expect(
          () => runtime.apply(
            parseCatalog(2, [source(revision: 5, name: 'Changed')]),
          ),
          throwsStateError,
        );
        runtime.apply(parseCatalog(2, []));
        expect(
          () => runtime.apply(parseCatalog(3, [source(revision: 4)])),
          throwsStateError,
        );
        expect(runtime.catalog?.revision, 2);
      },
    );

    test(
      'configured app-token builtin follows runtime credential availability',
      () {
        final entry = SourceCatalogEntry.fromJson(
          source(id: 'genius', accessMode: 'app_token', enabled: true),
        );
        final available = ConfiguredBuiltinProvider(
          entry,
          FakeProvider(
            const ProviderDefinition(
              id: 'genius',
              name: 'Genius',
              enabledByDefault: true,
              accessMode: 'app_token',
            ),
          ),
        );
        final unavailable = ConfiguredBuiltinProvider(
          entry,
          FakeProvider(
            const ProviderDefinition(
              id: 'genius',
              name: 'Genius',
              enabledByDefault: false,
              accessMode: 'app_token',
            ),
          ),
        );
        expect(available.definition.enabledByDefault, isTrue);
        expect(unavailable.definition.enabledByDefault, isFalse);

        final publicOverride = ConfiguredBuiltinProvider(
          SourceCatalogEntry.fromJson(
            source(id: 'genius', accessMode: 'public', enabled: true),
          ),
          FakeProvider(
            const ProviderDefinition(
              id: 'genius',
              name: 'Genius',
              enabledByDefault: false,
              accessMode: 'app_token',
            ),
          ),
        );
        expect(publicOverride.definition.accessMode, 'public');
        expect(publicOverride.definition.enabledByDefault, isFalse);
      },
    );
  });
}
