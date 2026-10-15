import 'dart:convert';

import '../domain/models.dart';
import 'provider.dart';
import 'sanitize.dart' show isPublicHost, safeHttpsUrl;

const int _maxCatalogBytes = 512 * 1024;
const int _maxSources = 100;
const int _maxProbesPerSource = 20;
const int _maxJsonDepth = 32;
const Set<String> _adapters = {'builtin', 'json', 'html'};
const Set<String> _statuses = {'active', 'disabled', 'retired'};
const Set<String> _probeFields = {
  'body',
  'metadata',
  'timing',
  'chords',
  'lineTiming',
  'wordTiming',
};

Never _invalid([String message = 'Invalid source catalog']) =>
    throw FormatException(message);

Map<String, dynamic> _map(dynamic value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    _invalid('$label must be an object');
  }
  return Map<String, dynamic>.from(value);
}

String _text(dynamic value, String label, {int max = 300}) {
  if (value is! String || value.trim().isEmpty || value.length > max) {
    _invalid('$label must be a non-empty string of at most $max characters');
  }
  return value.trim();
}

int _positiveInt(dynamic value, String label) {
  if (value is! int || value <= 0) {
    _invalid('$label must be a positive integer');
  }
  return value;
}

void _checkKeys(Map<String, dynamic> value, Set<String> allowed, String label) {
  final unknown = value.keys.where((key) => !allowed.contains(key));
  if (unknown.isNotEmpty) _invalid('$label has unknown field ${unknown.first}');
}

void _checkJson(dynamic value, [int depth = 0]) {
  if (depth > _maxJsonDepth) _invalid('JSON value is too deeply nested');
  if (value == null || value is String || value is bool || value is int) return;
  if (value is double) {
    if (!value.isFinite) _invalid('JSON numbers must be finite');
    return;
  }
  if (value is List) {
    for (final item in value) {
      _checkJson(item, depth + 1);
    }
    return;
  }
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      _invalid('JSON object keys must be strings');
    }
    for (final item in value.values) {
      _checkJson(item, depth + 1);
    }
    return;
  }
  _invalid('Value is not JSON-compatible');
}

dynamic _freeze(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _freeze(entry.value),
    });
  }
  if (value is List) return List<dynamic>.unmodifiable(value.map(_freeze));
  return value;
}

dynamic _canonical(dynamic value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  return value;
}

String _validHost(dynamic value) {
  final host = _text(value, 'host', max: 253).toLowerCase();
  if (!isPublicHost(host) ||
      const {'.example', '.test', '.invalid'}.any(host.endsWith)) {
    _invalid('Hosts must be exact public DNS names');
  }
  return host;
}

String _httpsUrl(dynamic value, String label) {
  final normalized = safeHttpsUrl(value);
  if (normalized == null) {
    _invalid('$label must be a public HTTPS URL');
  }
  final host = Uri.parse(normalized).host.toLowerCase();
  if (const {'.example', '.test', '.invalid'}.any(host.endsWith)) {
    _invalid('$label must be a public HTTPS URL');
  }
  return normalized;
}

DateTime _publishedAt(dynamic value) {
  final text = _text(value, 'publishedAt', max: 40);
  final parsed = DateTime.tryParse(text);
  if (parsed == null || !text.endsWith('Z') || !parsed.isUtc) {
    _invalid('publishedAt must be a UTC ISO timestamp');
  }
  return parsed;
}

/// A bounded, validated snapshot of remotely published source configuration.
/// Omitted entries disappear from the active lookup when a snapshot is applied.
class SourceCatalog {
  SourceCatalog._({
    required this.schemaVersion,
    required this.extractionSchemaVersion,
    required this.revision,
    required this.publishedAt,
    required List<SourceCatalogEntry> sources,
  }) : sources = List.unmodifiable(sources);

  final int schemaVersion;
  final int extractionSchemaVersion;
  final int revision;
  final DateTime publishedAt;
  final List<SourceCatalogEntry> sources;

  factory SourceCatalog.parse(String text) {
    if (utf8.encode(text).length > _maxCatalogBytes) {
      _invalid('Catalog exceeds $_maxCatalogBytes bytes');
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      _invalid('Catalog is not valid JSON');
    }
    return SourceCatalog.fromJson(_map(decoded, 'Catalog'));
  }

  factory SourceCatalog.fromJson(Map<String, dynamic> json) {
    _checkKeys(json, {
      'schemaVersion',
      'extractionSchemaVersion',
      'revision',
      'publishedAt',
      'sources',
    }, 'Catalog');
    if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
      _invalid('Unsupported catalog schema version');
    }
    if (json['extractionSchemaVersion'] is! int ||
        json['extractionSchemaVersion'] != 1) {
      _invalid('Unsupported extraction schema version');
    }
    final rawSources = json['sources'];
    if (rawSources is! List || rawSources.length > _maxSources) {
      _invalid('sources must contain at most $_maxSources entries');
    }
    final sources = rawSources
        .map((value) => SourceCatalogEntry.fromJson(_map(value, 'Source')))
        .toList();
    final ids = <String>{};
    for (final source in sources) {
      if (!ids.add(source.id)) _invalid('Duplicate source id ${source.id}');
    }
    final catalog = SourceCatalog._(
      schemaVersion: 1,
      extractionSchemaVersion: 1,
      revision: _positiveInt(json['revision'], 'revision'),
      publishedAt: _publishedAt(json['publishedAt']),
      sources: sources,
    );
    if (utf8.encode(jsonEncode(catalog.toJson())).length > _maxCatalogBytes) {
      _invalid('Catalog exceeds $_maxCatalogBytes bytes');
    }
    return catalog;
  }

  JsonMap toJson() => {
    'schemaVersion': schemaVersion,
    'extractionSchemaVersion': extractionSchemaVersion,
    'revision': revision,
    'publishedAt': publishedAt.toUtc().toIso8601String(),
    'sources': sources.map((source) => source.toJson()).toList(),
  };

  bool sameContent(SourceCatalog other) =>
      jsonEncode(_canonical(toJson())) ==
      jsonEncode(_canonical(other.toJson()));
}

class SourceCatalogEntry {
  SourceCatalogEntry._({
    required this.id,
    required this.name,
    required this.adapter,
    required this.status,
    required this.revision,
    required Set<String> capabilities,
    required this.enabledByDefault,
    required this.accessMode,
    required this.website,
    required this.attribution,
    required this.description,
    required List<String> hosts,
    required JsonMap? extraction,
    required List<JsonMap> probes,
    required this.changeReason,
  }) : capabilities = Set.unmodifiable(capabilities),
       hosts = List.unmodifiable(hosts),
       extraction = extraction == null ? null : _freeze(extraction),
       probes = List<JsonMap>.unmodifiable(
         probes.map((probe) => _freeze(probe) as JsonMap),
       );

  final String id;
  final String name;
  final String adapter;
  final String status;
  final int revision;
  final Set<String> capabilities;
  final bool enabledByDefault;
  final String accessMode;
  final String website;
  final String? attribution;
  final String? description;
  final List<String> hosts;
  final JsonMap? extraction;
  final List<JsonMap> probes;
  final String? changeReason;

  bool get isActive => status == 'active';

  ProviderDefinition get definition => ProviderDefinition(
    id: id,
    name: name,
    capabilities: capabilities,
    accessMode: accessMode,
    enabledByDefault: enabledByDefault,
    description: description,
    website: website,
  );

  factory SourceCatalogEntry.fromJson(Map<String, dynamic> json) {
    _checkKeys(json, {
      'id',
      'name',
      'adapter',
      'status',
      'revision',
      'capabilities',
      'enabledByDefault',
      'accessMode',
      'website',
      'description',
      'hosts',
      'extraction',
      'probes',
      'changeReason',
      'attribution',
    }, 'Source');
    final id = _text(json['id'], 'id', max: 80);
    if (!RegExp(r'^[a-z][a-z0-9_-]{0,79}$').hasMatch(id)) {
      _invalid('Invalid source id');
    }
    final adapter = _text(json['adapter'], 'adapter', max: 20);
    if (!_adapters.contains(adapter)) _invalid('Unsupported adapter $adapter');
    final status = _text(json['status'], 'status', max: 20);
    if (!_statuses.contains(status)) {
      _invalid('Unsupported source status $status');
    }
    final rawCapabilities = json['capabilities'];
    if (rawCapabilities is! List || rawCapabilities.length > 30) {
      _invalid('capabilities must be a list of at most 30 strings');
    }
    final capabilities = <String>{};
    for (final raw in rawCapabilities) {
      final capability = _text(raw, 'capability', max: 60);
      if (!capabilities.add(capability)) {
        _invalid('Duplicate capability $capability');
      }
    }
    if (json['enabledByDefault'] is! bool) {
      _invalid('enabledByDefault must be boolean');
    }
    final rawHosts = json['hosts'];
    if (rawHosts is! List || rawHosts.length > 50) {
      _invalid('hosts must be a list of at most 50 names');
    }
    final hosts = <String>[];
    final hostSet = <String>{};
    for (final raw in rawHosts) {
      final host = _validHost(raw);
      if (!hostSet.add(host)) _invalid('Duplicate host $host');
      hosts.add(host);
    }
    final extractionValue = json['extraction'];
    final extraction = extractionValue == null
        ? null
        : _map(extractionValue, 'extraction');
    if (extraction != null) _checkJson(extraction);
    if (adapter == 'builtin') {
      if (extraction != null && extraction.isNotEmpty) {
        _invalid('Builtin entries cannot define extraction');
      }
    } else if (hosts.isEmpty || extraction == null) {
      _invalid('$adapter entries require hosts and extraction');
    }
    final rawProbes = json['probes'] ?? const [];
    if (rawProbes is! List || rawProbes.length > _maxProbesPerSource) {
      _invalid('probes must contain at most $_maxProbesPerSource entries');
    }
    final probes = <JsonMap>[];
    final probeIds = <String>{};
    for (final raw in rawProbes) {
      final probe = _map(raw, 'probe');
      _checkKeys(probe, {
        'id',
        'query',
        'candidate',
        'requiredFields',
        'requiredMetadataFields',
        'expectedTitle',
        'expectedArtist',
        'expectedAlbum',
        'expectedDurationSeconds',
      }, 'Probe');
      final probeId = _text(probe['id'], 'probe id', max: 80);
      if (!probeIds.add(probeId)) _invalid('Duplicate probe id $probeId');
      if (probe.containsKey('query')) {
        _text(probe['query'], 'probe query', max: 200);
      }
      if (probe.containsKey('expectedTitle')) {
        _text(probe['expectedTitle'], 'expectedTitle', max: 300);
      }
      if (probe.containsKey('expectedArtist')) {
        _text(probe['expectedArtist'], 'expectedArtist', max: 300);
      }
      if (probe.containsKey('expectedAlbum')) {
        _text(probe['expectedAlbum'], 'expectedAlbum', max: 300);
      }
      if (probe.containsKey('expectedDurationSeconds')) {
        final duration = probe['expectedDurationSeconds'];
        if (duration is! num ||
            !duration.isFinite ||
            duration <= 0 ||
            duration > 86400) {
          _invalid('expectedDurationSeconds must be a positive duration');
        }
      }
      if (probe.containsKey('candidate')) {
        final candidate = _map(probe['candidate'], 'probe candidate');
        try {
          final parsedCandidate = SongCandidate.fromJson(candidate);
          if (parsedCandidate.providerId != id ||
              parsedCandidate.id.trim().isEmpty ||
              parsedCandidate.id.length > 300 ||
              parsedCandidate.title.trim().isEmpty ||
              parsedCandidate.title.length > 300 ||
              parsedCandidate.artist.length > 300 ||
              parsedCandidate.artist.trim().isEmpty &&
                  (capabilities.contains('lyrics') ||
                      capabilities.contains('chords'))) {
            _invalid('probe candidate identity must be non-empty and bounded');
          }
        } catch (_) {
          _invalid('probe candidate must be a SongCandidate JSON object');
        }
      }
      final importOnly =
          capabilities.contains('fileImport') &&
          !capabilities.contains('catalog');
      if (!importOnly &&
          !probe.containsKey('query') &&
          !probe.containsKey('candidate')) {
        _invalid('A probe requires a query or candidate');
      }
      final required = probe['requiredFields'] ?? const [];
      if (required is! List || required.length > _probeFields.length) {
        _invalid('requiredFields must be a list of supported fields');
      }
      final requiredFields = <String>{};
      for (final field in required) {
        final text = _text(field, 'required field', max: 30);
        if (!_probeFields.contains(text) || !requiredFields.add(text)) {
          _invalid('Unsupported or duplicate required field $text');
        }
      }
      if (probe.containsKey('requiredFields')) {
        probe['requiredFields'] = requiredFields.toList();
      }
      final rawMetadataFields = probe['requiredMetadataFields'] ?? const [];
      if (rawMetadataFields is! List || rawMetadataFields.length > 20) {
        _invalid('requiredMetadataFields must contain at most 20 paths');
      }
      final metadataFields = <String>{};
      for (final field in rawMetadataFields) {
        final path = _text(field, 'metadata field path', max: 200);
        final parts = path.split('.');
        if (parts.length > 8 ||
            !RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,63}$').hasMatch(parts.first) ||
            parts
                .skip(1)
                .any(
                  (part) => !RegExp(
                    r'^(?:[A-Za-z][A-Za-z0-9_-]{0,63}|0|[1-9][0-9]{0,3})$',
                  ).hasMatch(part),
                ) ||
            !metadataFields.add(path)) {
          _invalid('Invalid or duplicate required metadata path');
        }
      }
      if (probe.containsKey('requiredMetadataFields')) {
        probe['requiredMetadataFields'] = metadataFields.toList();
      }
      _checkJson(probe);
      probes.add(probe);
    }
    final website = _httpsUrl(json['website'], 'website');
    final attribution = json.containsKey('attribution')
        ? _text(json['attribution'], 'attribution', max: 1000)
        : null;
    final description = json.containsKey('description')
        ? _text(json['description'], 'description', max: 1000)
        : null;
    final changeReason = json.containsKey('changeReason')
        ? _text(json['changeReason'], 'changeReason', max: 500)
        : null;
    return SourceCatalogEntry._(
      id: id,
      name: _text(json['name'], 'name', max: 120),
      adapter: adapter,
      status: status,
      revision: _positiveInt(json['revision'], 'source revision'),
      capabilities: capabilities,
      enabledByDefault: json['enabledByDefault'] as bool,
      accessMode: _text(json['accessMode'], 'accessMode', max: 80),
      website: website,
      attribution: attribution,
      description: description,
      hosts: hosts,
      extraction: extraction,
      probes: probes,
      changeReason: changeReason,
    );
  }

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'adapter': adapter,
    'status': status,
    'revision': revision,
    'capabilities': capabilities.toList()..sort(),
    'enabledByDefault': enabledByDefault,
    'accessMode': accessMode,
    'website': website,
    if (attribution != null) 'attribution': attribution,
    if (description != null) 'description': description,
    'hosts': hosts,
    if (extraction != null) 'extraction': extraction,
    if (probes.isNotEmpty) 'probes': probes,
    if (changeReason != null) 'changeReason': changeReason,
  };
}

/// Exposes the catalog definition while preserving an existing builtin's work.
class ConfiguredBuiltinProvider implements LyricsProvider {
  ConfiguredBuiltinProvider(this.entry, this.delegate) {
    if (entry.adapter != 'builtin' || entry.id != delegate.definition.id) {
      throw ArgumentError('Builtin entry and delegate ids must match');
    }
  }

  final SourceCatalogEntry entry;
  final LyricsProvider delegate;

  @override
  ProviderDefinition get definition {
    final configured = entry.definition;
    return ProviderDefinition(
      id: configured.id,
      name: configured.name,
      capabilities: configured.capabilities,
      accessMode: configured.accessMode,
      enabledByDefault:
          configured.enabledByDefault &&
          (entry.accessMode != 'app_token' ||
              delegate.definition.enabledByDefault),
      description: configured.description,
      website: configured.website,
    );
  }

  @override
  Future<List<SongCandidate>> search(
    String query, {
    CancellationToken? cancel,
  }) => delegate.search(query, cancel: cancel);

  @override
  Future<SourceResult> resolve(
    SongCandidate candidate, {
    CancellationToken? cancel,
  }) => delegate.resolve(candidate, cancel: cancel);
}

/// Applies whole catalog snapshots atomically; omitted and inactive entries are
/// absent from the provider list returned to callers.
class SourceCatalogRuntime {
  SourceCatalogRuntime({
    required List<LyricsProvider> builtins,
    required this.createProvider,
  }) : _builtins = List.unmodifiable(builtins) {
    final ids = <String>{};
    for (final provider in _builtins) {
      if (!ids.add(provider.definition.id)) {
        throw ArgumentError('Duplicate builtin id ${provider.definition.id}');
      }
    }
  }

  final List<LyricsProvider> _builtins;
  final LyricsProvider Function(SourceCatalogEntry entry) createProvider;
  SourceCatalog? _catalog;
  SourceCatalog? get catalog => _catalog;
  final Map<String, SourceCatalogEntry> _entryHistory = {};

  List<LyricsProvider> _providers = const [];
  List<LyricsProvider> get providers =>
      _catalog == null ? _builtins : _providers;

  /// Validates and constructs the next provider set without changing runtime
  /// state. A client can persist a validated snapshot before calling [apply].
  List<LyricsProvider> prepare(SourceCatalog next) {
    final previous = _catalog;
    if (previous != null) {
      if (next.revision < previous.revision) {
        throw StateError('Catalog revision rollback is not allowed');
      }
      if (next.revision == previous.revision) {
        if (!next.sameContent(previous)) {
          throw StateError('Catalog content changed at the same revision');
        }
        return providers;
      }
    }
    for (final entry in next.sources) {
      final last = _entryHistory[entry.id];
      if (last == null) continue;
      if (entry.revision < last.revision) {
        throw StateError('Source revision rollback for ${entry.id}');
      }
      if (entry.revision == last.revision && !_sameEntryRevision(entry, last)) {
        throw StateError(
          'Source ${entry.id} changed without a revision increase',
        );
      }
    }
    final builtinIds = _builtins
        .map((provider) => provider.definition.id)
        .toSet();
    final nextProviders = <LyricsProvider>[];
    for (final entry in next.sources) {
      if (entry.adapter == 'builtin') {
        if (!builtinIds.contains(entry.id)) {
          throw StateError('Unknown builtin source ${entry.id}');
        }
        if (entry.isActive) {
          final delegate = _builtins.singleWhere(
            (provider) => provider.definition.id == entry.id,
          );
          nextProviders.add(ConfiguredBuiltinProvider(entry, delegate));
        }
        continue;
      }
      if (!entry.isActive) continue;
      final provider = createProvider(entry);
      if (provider.definition.id != entry.id) {
        throw StateError(
          'Adapter returned ${provider.definition.id} for ${entry.id}',
        );
      }
      nextProviders.add(provider);
    }
    return List.unmodifiable(nextProviders);
  }

  void apply(SourceCatalog next) {
    final prepared = prepare(next);
    if (_catalog != null &&
        next.revision == _catalog!.revision &&
        next.sameContent(_catalog!)) {
      return;
    }
    // All lookups and constructors succeeded; publish the snapshot together.
    _providers = prepared;
    _catalog = next;
    for (final entry in next.sources) {
      _entryHistory[entry.id] = entry;
    }
  }
}

bool _sameEntryRevision(SourceCatalogEntry a, SourceCatalogEntry b) =>
    jsonEncode(_canonical(a.toJson())) == jsonEncode(_canonical(b.toJson()));
