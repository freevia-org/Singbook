/// Cross-file consistency only. Passing does not independently establish the
/// musical truth of a reference; the cited evidence still needs human review.
List<String> reviewedReferenceErrors(
  Map<String, dynamic> song,
  String field,
  Map<String, dynamic> review,
) {
  final errors = <String>[];
  final expected = song['expected'];
  final fields = expected is Map ? expected['fields'] : null;
  final claim = fields is Map ? fields[field] : null;
  if (claim is! Map || claim['status'] != 'verified') return errors;
  void require(bool condition, String message) {
    if (!condition) errors.add(message);
  }

  bool text(Object? value) => value is String && value.trim().isNotEmpty;
  require(
    text(song['id']) && review['songId'] == song['id'],
    'review song differs',
  );
  require(review['field'] == field, 'review field differs');
  require(review['status'] == 'verified', 'review is not verified');
  require(
    text(claim['value']) && review['value'] == claim['value'],
    'review value differs',
  );
  final edition = song['recordingEdition'];
  require(
    text(edition) && song['recordingEditionStatus'] == 'verified',
    'target edition is not verified',
  );
  require(review['scope'] == edition, 'review scope differs');
  final binding = review['recordingBinding'];
  final reference = expected is Map ? expected['recordingReference'] : null;
  if (binding is! Map || reference is! Map) {
    errors.add('recording binding missing');
  } else {
    for (final evidence in [binding['evidence'], reference['evidence']]) {
      require(
        evidence is List && evidence.isNotEmpty && evidence.every(text),
        'recording evidence missing',
      );
    }
    require(
      binding['status'] == 'verified' && reference['status'] == 'verified',
      'recording binding is not verified',
    );
    require(
      binding['recordingEdition'] == edition &&
          reference['recordingEdition'] == edition,
      'binding edition differs',
    );
    require(
      (text(reference['providerId']) && text(reference['candidateId'])) ||
          text(reference['isrc']),
      'recording identity missing',
    );
    for (final key in ['providerId', 'candidateId', 'isrc']) {
      require(binding[key] == reference[key], 'binding $key differs');
    }
  }
  final sources = review['independentSources'];
  final trustedReferences = review['trustedReferences'];
  final hasIndependentSources = sources is List && sources.isNotEmpty;
  final hasTrustedReferences =
      trustedReferences is List && trustedReferences.isNotEmpty;
  require(
    hasIndependentSources || hasTrustedReferences,
    'reviewed field references missing',
  );
  final supportedUrls = <String>{};
  final independentUrls = <String>{};
  if (sources is List) {
    for (final source in sources) {
      require(
        source is Map &&
            text(source['url']) &&
            text(source['role']) &&
            text(source['finding']),
        'source evidence incomplete',
      );
      if (source is Map && source['url'] is String) {
        supportedUrls.add(source['url'] as String);
        independentUrls.add(source['url'] as String);
      }
    }
  }
  final trustedUrls = <String>{};
  if (trustedReferences is List) {
    for (final reference in trustedReferences) {
      final validLyricsReference =
          field == 'lyrics' &&
          reference is Map &&
          reference['sourceClass'] == 'licensed_lyrics_provider' &&
          text(reference['provider']) &&
          reference['exactNormalizedTextMatch'] == true &&
          reference['referenceTextSha256'] == claim['value'] &&
          reference['selectedTextSha256'] == claim['value'] &&
          reference['scopeCompatibility'] == 'compatible' &&
          text(reference['lineageStatus']);
      require(
        reference is Map &&
            text(reference['url']) &&
            text(reference['role']) &&
            text(reference['finding']) &&
            validLyricsReference,
        'trusted reference is incomplete or incompatible',
      );
      if (reference is Map && reference['url'] is String) {
        trustedUrls.add(reference['url'] as String);
      }
    }
  }
  if (binding is Map && binding['evidence'] is List) {
    supportedUrls.addAll((binding['evidence'] as List).whereType<String>());
  }
  supportedUrls.addAll(trustedUrls);
  final evidence = claim['evidence'];
  require(evidence is List && evidence.isNotEmpty, 'field evidence missing');
  if (evidence is List) {
    require(
      field == 'lyrics'
          ? evidence.any(trustedUrls.contains) ||
                evidence.any(independentUrls.contains)
          : evidence.any(independentUrls.contains),
      field == 'lyrics'
          ? 'field has no cited trusted lyric comparison'
          : 'field has no cited independent musical evidence',
    );
    require(
      evidence.every((url) => url is String && supportedUrls.contains(url)),
      'field evidence is absent from review',
    );
  }
  if (field == 'key') {
    require(
      review['notDerivedFromActualBenchmarkKey'] == true,
      'independent key review declaration missing',
    );
  }
  return errors;
}
