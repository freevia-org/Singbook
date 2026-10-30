import 'dart:convert';

import '../configurable_provider.dart';
import '../core/service.dart';
import '../provider.dart';
import '../source_catalog.dart';
import 'wikibooks_liederbuch.dart';

/// Local integration groundwork, independent of the production registry/channel.
///
/// Pass the initialized production client's effective catalog, including its
/// compatible cached repairs and removals, and the complete compiled registry.
/// This adds a disabled native entry only to a new preview runtime. It neither
/// changes the supplied catalog/providers nor exposes a catalog refresh client.
class WikibooksLiederbuchPreview {
  WikibooksLiederbuchPreview._({
    required this.runtime,
    required this.compiledProviders,
    required this.usedCache,
    required this.cacheErrorCode,
  });

  static const sourceId = 'wikibooksliederbuch';
  static const cacheKey = 'sourceCatalog:preview:wikibooks-liederbuch:v1';

  final SourceCatalogRuntime runtime;
  final List<LyricsProvider> compiledProviders;
  final bool usedCache;
  final String? cacheErrorCode;

  SourceCatalog get catalog => runtime.catalog!;

  /// An explicitly injected, offline catalog view. No production refresh path.
  SourceDiscoveryService createDiscovery() =>
      SourceDiscoveryService(runtime.providers);

  static Future<WikibooksLiederbuchPreview> create({
    required SourceCatalog productionCatalog,
    required List<LyricsProvider> compiledProviders,
    required ProviderTransport transport,
    required Future<Object?> Function(String key) readSetting,
    required Future<void> Function(String key, Object? value) writeSetting,
    DateTime Function()? clock,
  }) async {
    if (productionCatalog.sources.any((entry) => entry.id == sourceId) ||
        compiledProviders.any(
          (provider) => provider.definition.id == sourceId,
        )) {
      // An existing native or declarative ID must never be replaced by preview.
      throw StateError('Wikibooks preview source ID is already present');
    }
    final book = WikibooksLiederbuchProvider(transport);
    final builtins = List<LyricsProvider>.unmodifiable([
      ...compiledProviders,
      book,
    ]);
    final runtime = SourceCatalogRuntime(
      builtins: builtins,
      createProvider: (entry) {
        ConfigurableProvider.validateExtraction(entry);
        return ConfigurableProvider(entry, transport);
      },
    );
    var candidate = SourceCatalog.fromJson({
      ...productionCatalog.toJson(),
      'revision': productionCatalog.revision + 1,
      // Local derivation time, not evidence of publisher/main publication.
      'publishedAt': (clock ?? DateTime.now)().toUtc().toIso8601String(),
      'sources': [
        for (final entry in productionCatalog.sources) entry.toJson(),
        {
          'id': sourceId,
          'name': book.definition.name,
          'adapter': 'builtin',
          'status': 'disabled',
          'revision': 1,
          'capabilities': book.definition.capabilities.toList()..sort(),
          'enabledByDefault': false,
          'accessMode': book.definition.accessMode,
          'website': book.definition.website,
          'hosts': <String>[],
          'changeReason':
              'Offline preview; source and app qualification pending.',
        },
      ],
    });
    // Validate every adapter before reading or writing the preview's own cache.
    runtime.prepare(candidate);
    var usedCache = false;
    String? cacheErrorCode;
    try {
      final cached = await readSetting(cacheKey);
      if (cached != null) {
        if (cached is! String) throw const FormatException();
        final parsed = SourceCatalog.parse(cached);
        final comparable = SourceCatalog.fromJson({
          ...parsed.toJson(),
          'publishedAt': candidate.publishedAt.toIso8601String(),
        });
        // A stale or edited preview cannot undo current production repairs or
        // removals, replace an ID, or activate Wikibooks through cached settings.
        if (!comparable.sameContent(candidate)) throw const FormatException();
        runtime.prepare(parsed);
        candidate = parsed;
        usedCache = true;
      }
    } catch (_) {
      cacheErrorCode = 'invalid_response';
    }
    runtime.apply(candidate);
    if (!usedCache) {
      try {
        await writeSetting(cacheKey, jsonEncode(candidate.toJson()));
      } catch (_) {
        // Optional preview persistence never changes the validated runtime.
        cacheErrorCode = 'cache_write_failed';
      }
    }
    return WikibooksLiederbuchPreview._(
      runtime: runtime,
      compiledProviders: builtins,
      usedCache: usedCache,
      cacheErrorCode: cacheErrorCode,
    );
  }
}
