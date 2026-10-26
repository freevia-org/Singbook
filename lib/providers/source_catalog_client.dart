import 'dart:async';
import 'source_catalog.dart';
import 'sanitize.dart';
import 'transport.dart';

/// Downloads declarative configuration from the publisher, retaining the last
/// compatible snapshot when offline or when a download cannot be validated.
class SourceCatalogClient {
  SourceCatalogClient({
    required this.runtime,
    required this.transport,
    required this.loadBundled,
    required this.readCache,
    required this.writeCache,
    Uri? endpoint,
  }) : endpoint = endpoint ?? Uri.parse(defaultEndpoint);

  static const defaultEndpoint = String.fromEnvironment(
    'SINGBOOK_SOURCE_CATALOG_URL',
    defaultValue:
        'https://raw.githubusercontent.com/freevia-org/Singbook/main/config/source-catalog-v2.json',
  );
  // Distribution channel 2 adds native providers. Envelope/extraction grammar
  // remains v1; released clients keep their original compatible URL and bundle.
  static const bundledAsset = 'config/source-catalog-v2.json';
  static const cacheKey = 'sourceCatalog:v2';
  static const legacyCacheKey = 'sourceCatalog';
  static const maxBytes = 512 * 1024;
  final SourceCatalogRuntime runtime;
  final ProviderTransport transport;
  final Future<String> Function() loadBundled;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;
  final Uri endpoint;
  String? lastErrorCode;
  DateTime? lastCheckedAt;
  Future<void>? _initializing;
  Future<bool>? _refreshing;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
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
      runtime.prepare(next);
      await writeCache(text);
      runtime.apply(next);
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
