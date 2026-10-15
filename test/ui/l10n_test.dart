import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/l10n/generated/app_localizations.dart';
import 'package:singbook/l10n/generated/app_localizations_ar.dart';
import 'package:singbook/l10n/generated/app_localizations_bg.dart';
import 'package:singbook/l10n/generated/app_localizations_cs.dart';
import 'package:singbook/l10n/generated/app_localizations_en.dart';
import 'package:singbook/l10n/generated/app_localizations_hr.dart';
import 'package:singbook/l10n/generated/app_localizations_lt.dart';
import 'package:singbook/l10n/generated/app_localizations_pl.dart';
import 'package:singbook/l10n/generated/app_localizations_ro.dart';
import 'package:singbook/l10n/generated/app_localizations_ru.dart';
import 'package:singbook/l10n/generated/app_localizations_sk.dart';
import 'package:singbook/l10n/generated/app_localizations_sl.dart';
import 'package:singbook/l10n/generated/app_localizations_lv.dart';
import 'package:singbook/l10n/generated/app_localizations_uk.dart';
import 'package:singbook/ui/app_version.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

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

    test('no locale hardcodes 1 in its generic "one" plural branch', () {
      final hardcoded = <String>[];
      for (final locale in ['hr', 'lv', 'ru', 'sl']) {
        for (final entry in _arb(locale).entries) {
          final value = entry.value;
          if (entry.key.startsWith('@') || value is! String) continue;
          for (final branch in RegExp(
            r'one\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}',
          ).allMatches(value)) {
            if (RegExp(r'(?<![\w{])1(?![\w}])').hasMatch(branch.group(1)!)) {
              hardcoded.add('$locale:${entry.key}');
            }
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

  test('added locales use their count-specific plural forms', () {
    expect(AppLocalizationsAr().setlistSongsCount(2), 'أغنيتان');
    expect(AppLocalizationsCs().setlistSongsCount(2), '2 písně');
    expect(AppLocalizationsHr().setlistSongsCount(2), '2 pjesme');
    expect(AppLocalizationsLt().setlistSongsCount(2), '2 dainos');
    expect(AppLocalizationsLt().setlistSongsCount(10), '10 dainų');
    expect(AppLocalizationsPl().searchResultCount(2), '2 wyniki');
    expect(AppLocalizationsPl().searchResultCount(5), '5 wyników');
    expect(AppLocalizationsRo().setlistSongsCount(2), '2 melodii');
    expect(AppLocalizationsSk().setlistSongsCount(2), '2 piesne');
    expect(AppLocalizationsSl().searchResultCount(2), '2 rezultata');
    expect(AppLocalizationsHr().songsUsageCount(21), 'Otvoreno 21 put');
    expect(AppLocalizationsLv().setlistSongsCount(21), '21 dziesma');
    expect(
      AppLocalizationsLv().readerTransposeSemitones(10),
      'Transponēt par 10 pustoņiem',
    );
    expect(AppLocalizationsRu().setlistSongsCount(21), '21 песня');
    expect(
      AppLocalizationsSl().accountSyncedMinutesAgo(101),
      'Sinhronizirano pred 101 minuto',
    );
  });

  test('every locale matches the template and is selectable', () {
    final template = _arb('en');
    final directory = Directory('lib/l10n');
    final localeFiles = directory
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => RegExp(r'^app_[a-z]{2}\.arb$').hasMatch(name))
        .map((name) => name.substring(4, 6))
        .toSet();
    final supportedLocales = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    expect(supportedLocales, localeFiles);
    for (final locale in localeFiles) {
      final arb = _arb(locale);
      expect(arb.keys.toSet(), template.keys.toSet(), reason: '$locale keys');
      expect(arb['@@locale'], locale, reason: '$locale root locale');
      for (final key in template.keys.where((key) => key.startsWith('@'))) {
        if (key == '@@locale') continue;
        expect(arb[key], template[key], reason: '$locale metadata $key');
      }
      for (final key in template.keys.where((key) => !key.startsWith('@'))) {
        final placeholders = template['@$key']?['placeholders'];
        if (placeholders != null) {
          expect(
            arb['@$key']?['placeholders'],
            placeholders,
            reason: '$locale placeholders $key',
          );
        }
      }
    }
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

  test(
    'screens do not hardcode user-facing English strings or the version',
    () {
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
    },
  );

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
