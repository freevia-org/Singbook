import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_maintenance.dart';

const _selection = SongCandidate(
  providerId: 'fake',
  id: '1',
  title: 'Invented Song',
  artist: 'Invented Artist',
);
const _asset = {
  'url': 'https://covers.example/front.jpg',
  'sourceUrl': 'https://catalog.example/release/1',
  'credit': 'Invented catalog',
  'role': 'frontCoverPreview',
  'rights': {'status': 'unknown'},
};

class _ArtworkProvider implements LyricsProvider {
  _ArtworkProvider(this.metadata, {this.extra = const {}});
  final Map<String, dynamic> metadata, extra;
  @override
  final definition = const ProviderDefinition(
    id: 'fake',
    name: 'Fake artwork',
    capabilities: {'metadata', 'artwork'},
  );
  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) async => [_selection];
  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) async => SourceResult(
    candidate: _selection,
    body: '',
    metadata: metadata,
    extra: extra,
  );
}

Future<Map<String, dynamic>> _run(
  _ArtworkProvider provider, {
  List<String> requiredMetadata = const ['artworkUrl', 'artworkAssets'],
}) => SourceMaintenanceHarness(providers: [provider]).run(
  SourceCatalog.fromJson({
    'schemaVersion': 1,
    'extractionSchemaVersion': 1,
    'revision': 1,
    'publishedAt': '2026-10-27T00:00:00Z',
    'sources': [
      {
        'id': 'fake',
        'name': 'Fake artwork',
        'adapter': 'builtin',
        'status': 'active',
        'revision': 1,
        'capabilities': ['metadata', 'artwork'],
        'enabledByDefault': true,
        'accessMode': 'publicApi',
        'website': 'https://catalog.example.org/',
        'hosts': <String>[],
        'probes': [
          {
            'id': 'artwork-shape',
            'candidate': _selection.toJson(),
            'requiredFields': ['metadata'],
            'requiredMetadataFields': requiredMetadata,
          },
        ],
      },
    ],
  }),
);
Map _probe(Map report) => report['sources'][0]['probes'][0] as Map;
void main() {
  test(
    'artwork-dependent release ID follows the optional artwork timeout',
    () async {
      final report = await _run(
        _ArtworkProvider(
          {'durationSeconds': 201},
          extra: {
            'capabilityChecks': {
              'artwork': {'status': 'unavailable', 'code': 'timeout'},
            },
          },
        ),
        requiredMetadata: [
          'musicbrainzReleaseId',
          'artworkUrl',
          'artworkAssets',
        ],
      );
      expect(_probe(report)['status'], 'transient_error');
      expect(_probe(report)['reason'], 'timeout');
      expect(
        _probe(report)['missingMetadataFields'],
        contains('musicbrainzReleaseId'),
      );
    },
  );
  test(
    'optional artwork timeout cannot hide loss of required recording identity',
    () async {
      final report = await _run(
        _ArtworkProvider(
          {'durationSeconds': 201},
          extra: {
            'capabilityChecks': {
              'artwork': {'status': 'unavailable', 'code': 'timeout'},
            },
          },
        ),
        requiredMetadata: [
          'musicbrainzRecordingId',
          'musicbrainzReleaseId',
          'artworkUrl',
          'artworkAssets',
        ],
      );
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['reason'], 'required_metadata_fields_missing');
      expect(
        _probe(report)['missingMetadataFields'],
        contains('musicbrainzRecordingId'),
      );
      expect(_probe(report)['capabilityFailures']['artwork'], {
        'status': 'transient_error',
        'reason': 'timeout',
      });
    },
  );
  test(
    'source-declared artwork location preserves unknown rights without claiming image decoding',
    () async {
      final report = await _run(
        _ArtworkProvider({
          'artworkUrl': _asset['url'],
          'artworkAssets': [_asset],
        }),
      );
      expect(report['sources'][0]['status'], 'healthy');
      expect(_probe(report)['verifiedCapabilities'], contains('artwork'));
      expect(_probe(report)['artworkImageBytesValidated'], isFalse);
      expect(
        _probe(report)['artworkEvidence'],
        'source_declared_location_and_provenance',
      );
    },
  );
  test(
    'a bare artwork URL or malformed provenance is not verified as an artwork asset',
    () async {
      for (final asset in [
        {'url': _asset['url']},
        {..._asset, 'url': 'http://covers.example/front.jpg'},
        {..._asset, 'url': 'https://127.0.0.1/front.jpg'},
        {..._asset, 'url': 'https://covers.example:8443/front.jpg'},
        {..._asset, 'rights': {}},
        {
          ..._asset,
          'sourceUrl': 'https://name:password@catalog.example/release/1',
        },
      ]) {
        final report = await _run(
          _ArtworkProvider({
            'artworkUrl': _asset['url'],
            'artworkAssets': [asset],
          }),
        );
        expect(report['sources'][0]['status'], 'partial_coverage');
        expect(
          _probe(report)['verifiedCapabilities'],
          isNot(contains('artwork')),
        );
      }
    },
  );
  test(
    'optional artwork rate limit is transient while valid recording metadata remains available',
    () async {
      final report = await _run(
        _ArtworkProvider(
          {'durationSeconds': 201},
          extra: {
            'capabilityChecks': {
              'artwork': {'status': 'unavailable', 'code': 'rate_limited'},
            },
          },
        ),
      );
      expect(_probe(report)['status'], 'transient_error');
      expect(_probe(report)['reason'], 'rate_limited');
      expect(_probe(report)['capability'], 'artwork');
      expect(_probe(report)['recordingMetadataAvailable'], isTrue);
    },
  );
  test('optional artwork access block is not a schema regression', () async {
    final report = await _run(
      _ArtworkProvider(
        {'durationSeconds': 201},
        extra: {
          'capabilityChecks': {
            'artwork': {'status': 'unavailable', 'code': 'blocked'},
          },
        },
      ),
    );
    expect(_probe(report)['status'], 'blocked');
    expect(_probe(report)['reason'], 'blocked');
  });
  test(
    'an unexplained missing required artwork field remains a schema regression',
    () async {
      final report = await _run(_ArtworkProvider({'durationSeconds': 201}));
      expect(_probe(report)['status'], 'changed_schema');
      expect(_probe(report)['reason'], 'required_metadata_fields_missing');
    },
  );
  test('unknown nested capability codes never leak upstream strings', () async {
    const upstream = 'not-public-upstream-content';
    final report = await _run(
      _ArtworkProvider(
        {'durationSeconds': 201},
        extra: {
          'capabilityChecks': {
            'artwork': {'status': 'unavailable', 'code': upstream},
          },
        },
      ),
    );
    expect(_probe(report)['status'], 'unavailable');
    expect(jsonEncode(report), isNot(contains(upstream)));
  });
}
