import 'dart:async';
import 'dart:convert';
import 'source_catalog.dart';
import 'sanitize.dart';
import 'transport.dart';

typedef PreviousSourceCatalogCache = ({String bundled, String cached});

/// Downloads declarative configuration from the publisher, retaining the last
/// compatible snapshot when offline or when a download cannot be validated.
class SourceCatalogClient {
  SourceCatalogClient({
    required SourceCatalogRuntime runtime,
    required this.transport,
    required this.loadBundled,
    required this.readCache,
    required this.writeCache,
    this.readPreviousCaches,
    Uri? endpoint,
    // Keep the existing public named parameter while its backing field can
    // transition from the offline fallback to the authoritative channel.
    // ignore: prefer_initializing_formals
  }) : _runtime = runtime,
       endpoint = endpoint ?? Uri.parse(defaultEndpoint);

  static const defaultEndpoint = String.fromEnvironment(
    'SINGBOOK_SOURCE_CATALOG_URL',
    defaultValue:
        'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v3.json',
  );
  // Distribution channel 3 adds AMLL. Envelope/extraction grammar remains v1.
  static const bundledAsset = 'config/source-catalog-v3.json';
  static const cacheKey = 'sourceCatalog:v3';
  static const channel2CacheKey = 'sourceCatalog:v2';
  static const legacyCacheKey = 'sourceCatalog';
  static const maxBytes = 512 * 1024;
  SourceCatalogRuntime _runtime;
  SourceCatalogRuntime get runtime => _runtime;
  SourceCatalogRuntime? _publisherRuntime;
  final ProviderTransport transport;
  final Future<String> Function() loadBundled;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;

  /// Closest older channel first. Used only without a valid current cache.
  /// Bundled baselines distinguish a publisher removal from a new native ID.
  final Future<List<PreviousSourceCatalogCache>> Function()? readPreviousCaches;
  final Uri endpoint;
  String? lastErrorCode;
  DateTime? lastCheckedAt;
  Future<void>? _initializing;
  Future<bool>? _refreshing;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (readPreviousCaches != null) {
      await _initializeWithUpgradeFallback();
      return;
    }
    // A damaged cache never prevents startup or displaces bundled providers.
    for (final read in [loadBundled, readCache]) {
      try {
        final text = await read();
        if (text != null) runtime.apply(SourceCatalog.parse(text));
      } catch (_) {
        lastErrorCode = 'invalid_response';
      }
    }
  }

  Future<void> _initializeWithUpgradeFallback() async {
    SourceCatalog? bundled;
    SourceCatalog? selected;
    var currentCacheValid = false;
    try {
      final candidate = SourceCatalog.parse(await loadBundled());
      runtime.fresh().apply(candidate);
      bundled = candidate;
      selected = candidate;
    } catch (_) {
      lastErrorCode = 'invalid_response';
    }
    try {
      final text = await readCache();
      if (text != null) {
        final cached = SourceCatalog.parse(text);
        final validator = runtime.fresh();
        if (bundled != null) validator.apply(bundled);
        validator.apply(cached);
        selected = cached;
        currentCacheValid = true;
      }
    } catch (_) {
      lastErrorCode = 'invalid_response';
    }
    if (!currentCacheValid && bundled != null) {
      try {
        // The controller supplies only known local channel keys/assets. Bound
        // this optional callback too; invalid older state cannot block startup.
        for (final previous in (await readPreviousCaches!()).take(8)) {
          try {
            final baseline = SourceCatalog.parse(previous.bundled);
            final cached = SourceCatalog.parse(previous.cached);
            final validator = runtime.fresh()..apply(baseline);
            validator.apply(cached);
            final merged = _upgradeFallback(bundled, baseline, cached);
            runtime.fresh().apply(merged);
            selected = merged;
            if (!merged.sameContent(bundled)) {
              _publisherRuntime = runtime.fresh()..apply(bundled);
            }
            break;
          } catch (_) {
            lastErrorCode = 'invalid_response';
          }
        }
      } catch (_) {
        lastErrorCode = 'invalid_response';
      }
    }
    if (selected != null) runtime.apply(selected);
  }

  SourceCatalog _upgradeFallback(
    SourceCatalog bundled,
    SourceCatalog previousBundle,
    SourceCatalog previousCache,
  ) {
    final sources = {for (final entry in bundled.sources) entry.id: entry};
    final oldBaseline = {
      for (final entry in previousBundle.sources) entry.id: entry,
    };
    final oldSources = {
      for (final entry in previousCache.sources) entry.id: entry,
    };
    for (final old in previousBundle.sources) {
      final current = sources[old.id];
      if (!oldSources.containsKey(old.id) &&
          current != null &&
          current.revision <= old.revision) {
        sources.remove(old.id);
      }
    }
    for (final entry in previousCache.sources) {
      final current = sources[entry.id];
      if (current != null) {
        // Never resurrect a source retired by the new compiled bundle.
        if (current.status != 'retired' && entry.revision > current.revision) {
          sources[entry.id] = entry;
        }
      } else if (!oldBaseline.containsKey(entry.id)) {
        sources[entry.id] = entry;
      }
    }
    return SourceCatalog.parse(
      jsonEncode({
        ...bundled.toJson(),
        'sources': sources.values.map((entry) => entry.toJson()).toList(),
      }),
    );
  }

  Future<bool> refresh({CancellationToken? cancel}) =>
      _refreshing ??= _refresh(cancel).whenComplete(() => _refreshing = null);

  Future<bool> _refresh(CancellationToken? cancel) async {
    await initialize();
    try {
      if (safeHttpsUrl(endpoint.toString()) == null) {
        throw const ProviderException('invalid_url');
      }
      final text = await transport.getText(
        endpoint,
        cancel: cancel,
        maxBytes: maxBytes,
      );
      cancel?.throwIfCancelled();
      final next = SourceCatalog.parse(text);
      // Construct every adapter before touching durable or live configuration.
      final destination = _publisherRuntime ?? runtime;
      destination.prepare(next);
      await writeCache(text);
      destination.apply(next);
      _runtime = destination;
      _publisherRuntime = null;
      lastCheckedAt = DateTime.now().toUtc();
      lastErrorCode = null;
      return true;
    } on ProviderException catch (error) {
      lastErrorCode = error.code;
    } catch (_) {
      // Parser details, downloaded content and credentials never reach UI/logs.
      lastErrorCode = 'invalid_response';
    }
    return false;
  }
}
