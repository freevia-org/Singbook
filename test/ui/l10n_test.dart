import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verse_mobile/l10n/generated/app_localizations_bg.dart';
import 'package:verse_mobile/l10n/generated/app_localizations_en.dart';
import 'package:verse_mobile/l10n/generated/app_localizations_uk.dart';
import 'package:verse_mobile/ui/app_version.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  group('Ukrainian plurals use the count in every form', () {
    final uk = AppLocalizationsUk();

    test('songs', () {
      expect(uk.setlistSongsCount(0), 'Немає пісень');
      expect(uk.setlistSongsCount(1), '1 пісня');
      expect(uk.setlistSongsCount(2), '2 пісні');
      expect(uk.setlistSongsCount(5), '5 пісень');
      expect(uk.setlistSongsCount(11), '11 пісень');
      expect(uk.setlistSongsCount(21), '21 пісня');
      expect(uk.setlistSongsCount(22), '22 пісні');
      expect(uk.setlistSongsCount(25), '25 пісень');
      expect(uk.setlistSongsCount(101), '101 пісня');
      expect(uk.daySongCount(21), '21 пісня');
      expect(uk.daySongCount(22), '22 пісні');
      expect(uk.daySongCount(25), '25 пісень');
    });

    test('opens', () {
      expect(uk.songsUsageCount(0), 'Відкрито жодного разу');
      expect(uk.songsUsageCount(1), 'Відкрито 1 раз');
      expect(uk.songsUsageCount(21), 'Відкрито 21 раз');
      expect(uk.songsUsageCount(22), 'Відкрито 22 рази');
      expect(uk.songsUsageCount(25), 'Відкрито 25 разів');
    });

    test('semitones', () {
      expect(uk.readerTransposeSemitones(1), 'Транспонувати на 1 півтон');
      expect(uk.readerTransposeSemitones(21), 'Транспонувати на 21 півтон');
      expect(uk.readerTransposeSemitones(22), 'Транспонувати на 22 півтони');
      expect(uk.readerTransposeSemitones(25), 'Транспонувати на 25 півтонів');
    });

    test('unavailable sources', () {
      expect(uk.searchSourcesUnavailableCount(1), 'Недоступне джерело: 1');
      expect(uk.searchSourcesUnavailableCount(21), 'Недоступне джерело: 21');
      expect(uk.searchSourcesUnavailableCount(22), 'Недоступні джерела: 22');
      expect(uk.searchSourcesUnavailableCount(25), 'Недоступних джерел: 25');
    });

    test('no plural hardcodes the digit 1 in its "one" branch', () {
      final arb = _arb('uk');
      final hardcoded = <String>[];
      for (final entry in arb.entries) {
        final value = entry.value;
        if (entry.key.startsWith('@') || value is! String) continue;
        for (final branch in RegExp(
          r'one\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}',
        ).allMatches(value)) {
          if (RegExp(r'(?<![\w{])1(?![\w}])').hasMatch(branch.group(1)!)) {
            hardcoded.add(entry.key);
          }
        }
      }
      expect(hardcoded, isEmpty);
    });
  });

  test('English and Bulgarian keep exact-one plurals', () {
    expect(AppLocalizationsEn().setlistSongsCount(1), '1 song');
    expect(AppLocalizationsEn().setlistSongsCount(21), '21 songs');
    expect(AppLocalizationsBg().setlistSongsCount(1), '1 песен');
    expect(AppLocalizationsBg().setlistSongsCount(21), '21 песни');
  });

  test('all locales define the same messages', () {
    final en = _keys(_arb('en'));
    expect(_keys(_arb('bg')).difference(en), isEmpty, reason: 'bg extras');
    expect(_keys(_arb('uk')).difference(en), isEmpty, reason: 'uk extras');
    expect(en.difference(_keys(_arb('bg'))), isEmpty, reason: 'bg missing');
    expect(en.difference(_keys(_arb('uk'))), isEmpty, reason: 'uk missing');
  });

  test('Bulgarian uses one word for setlists and names key and capo', () {
    final bg = _arb('bg');
    for (final entry in bg.entries) {
      if (entry.value is String) {
        expect(
          (entry.value as String).toLowerCase(),
          isNot(contains('сетлист')),
          reason: '${entry.key} mixes "сетлист" with "списък"',
        );
      }
    }
    expect(bg['setlistEntryOverride'], contains('Тоналност'));
    expect(bg['setlistEntryOverride'], isNot(contains('Акорд')));
  });

  test('screens do not hardcode user-facing English strings or the version', () {
    final forbidden = [
      "'Missing song'",
      "'New setlist'",
      "' copy'",
      "'Try again'",
      "'Your library could not be opened.'",
      "'0.2.0'",
    ];
    final offenders = <String>[];
    for (final file in Directory('lib/ui').listSync(recursive: true)) {
      if (file is! File ||
          !file.path.endsWith('.dart') ||
          file.path.endsWith('app_version.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final text in forbidden) {
        if (source.contains(text)) offenders.add('${file.path}: $text');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the displayed version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^\s+]+)',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    expect(singbookVersion, match!.group(1));
  });
}
