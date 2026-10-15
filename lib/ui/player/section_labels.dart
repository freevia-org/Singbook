import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

final _sectionPattern = RegExp(
  r'^\s*(pre[- ]?chorus|post[- ]?chorus|verse|chorus|bridge|intro|outro|instrumental|interlude|solo|refrain|hook|breakdown|coda|tag|ending)(?=$|[\s(])(.*)$',
  caseSensitive: false,
);

/// The recognised section kind of [name] (`verse`, `pre-chorus`, ...) and
/// whatever follows it ("2", "(x2)"), or null for custom headings.
({String kind, String rest})? parseSectionName(String name) {
  final match = _sectionPattern.firstMatch(name);
  if (match == null) return null;
  var kind = match.group(1)!.toLowerCase().replaceAll(' ', '-');
  if (kind == 'prechorus') kind = 'pre-chorus';
  if (kind == 'postchorus') kind = 'post-chorus';
  return (kind: kind, rest: match.group(2) ?? '');
}

String _kindName(AppLocalizations l10n, String kind) => switch (kind) {
  'verse' => l10n.sectionVerse,
  'chorus' => l10n.sectionChorus,
  'bridge' => l10n.sectionBridge,
  'intro' => l10n.sectionIntro,
  'outro' => l10n.sectionOutro,
  'pre-chorus' => l10n.sectionPreChorus,
  'post-chorus' => l10n.sectionPostChorus,
  'instrumental' => l10n.sectionInstrumental,
  'interlude' => l10n.sectionInterlude,
  'solo' => l10n.sectionSolo,
  'refrain' => l10n.sectionRefrain,
  'hook' => l10n.sectionHook,
  'breakdown' => l10n.sectionBreakdown,
  'coda' => l10n.sectionCoda,
  'tag' => l10n.sectionTag,
  'ending' => l10n.sectionEnding,
  _ => kind,
};

/// A section heading in the app language. The song format names sections in
/// English ("Pre-Chorus 2"); recognised kinds are shown with their translated
/// name and any number, custom headings are left exactly as written.
String localizedSectionName(AppLocalizations l10n, String name) {
  final parsed = parseSectionName(name);
  if (parsed == null) return name;
  return '${_kindName(l10n, parsed.kind)}${parsed.rest}';
}

/// A short seek-bar label for a section: letters taken from the translated
/// name, so "Припев 2" becomes "П2" and "Refrain 2" stays "R2".
String sectionAbbreviation(
  AppLocalizations l10n,
  String name, {
  required bool compact,
}) {
  final parsed = parseSectionName(name);
  if (parsed == null) return _initials(name, compact: compact);
  final number = RegExp(r'\d+').firstMatch(parsed.rest)?.group(0) ?? '';
  if (l10n.localeName == 'en') {
    final code = switch (parsed.kind) {
      'verse' => 'V',
      'chorus' => compact ? 'C' : 'CH',
      'bridge' => compact ? 'B' : 'BR',
      'intro' => compact ? 'I' : 'IN',
      'outro' => compact ? 'O' : 'OUT',
      'pre-chorus' => compact ? 'P' : 'PC',
      _ => parsed.kind.substring(0, 1).toUpperCase(),
    };
    return '$code$number';
  }
  final kindName = _kindName(l10n, parsed.kind);
  final words = kindName
      .split(RegExp(r'[\s-]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  final letters = words.length > 1
      ? words.map((word) => word.characters.first).join()
      : kindName.characters.take(compact ? 1 : 2).toString();
  final limit = compact ? 2 : 3;
  return '${letters.characters.take(limit).toString().toUpperCase()}$number';
}

String _initials(String name, {required bool compact}) {
  final words = name
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final initials = words.map((part) => part.characters.first).join();
  return initials.characters.take(compact ? 2 : 3).toString().toUpperCase();
}
