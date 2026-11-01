import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';

/// The generic edition comparator folds case and punctuation. A digest keeps
/// case-sensitive publisher variable names distinct under that comparator.
String sourceTextVariantVersion(String id) =>
    'mutopia-text-${sha256.convert(utf8.encode(id))}';

/// Publisher text identity, distinct from a recording or a verified language.
/// Keep this binding shared by source selection, saving and UI projections.
({String editionId, String label})? sourceTextVariant(SongCandidate? value) {
  if (value == null ||
      value.providerId != 'mutopia' ||
      value.metadata['identityScope'] != 'arrangement' ||
      value.metadata['artistCreditRole'] != 'composer' ||
      value.metadata['composer'] != value.artist ||
      value.metadata['pendingMatchCheck'] == true ||
      value.extra['pendingMatchCheck'] == true) {
    return null;
  }
  final identity = RegExp(
    r'^([1-9]\d{0,8}):([A-Za-z][A-Za-z0-9_]{0,63})$',
  ).firstMatch(value.id);
  if (identity == null ||
      value.metadata['mutopiaEditionId']?.toString() != identity[1] ||
      value.metadata['sourceVariantLabel'] != identity[2] ||
      value.metadata['version'] != sourceTextVariantVersion(value.id)) {
    return null;
  }
  return (editionId: identity[1]!, label: identity[2]!);
}
