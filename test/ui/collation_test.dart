import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/ui/library/collation.dart';
import 'package:singbook/ui/library/songs_screen.dart';

List<String> _sorted(List<String> titles) =>
    sortedByTitle(titles, (title) => title);

void main() {
  group('collation', () {
    test('Ukrainian letters sort in alphabet order, not by code unit', () {
      // Code-unit order would put є, і, ї and ґ after я.
      expect(
        _sorted([
          'Яблуко',
          'Їжак',
          'Іній',
          'Єнот',
          'Ґанок',
          'Гора',
          'Ехо',
          'Диня',
        ]),
        ['Гора', 'Ґанок', 'Диня', 'Ехо', 'Єнот', 'Іній', 'Їжак', 'Яблуко'],
      );
      // и < і < ї < й.
      expect(_sorted(['Йод', 'Їжак', 'Іній', 'Ива']), [
        'Ива',
        'Іній',
        'Їжак',
        'Йод',
      ]);
    });

    test('Russian yo and Bulgarian letters keep their place', () {
      expect(_sorted(['Ящик', 'Ёлка', 'Ель', 'Еда']), [
        'Еда',
        'Ель',
        'Ёлка',
        'Ящик',
      ]);
      expect(_sorted(['Юг', 'Щит', 'Ъгъл', 'Шум']), [
        'Шум',
        'Щит',
        'Ъгъл',
        'Юг',
      ]);
    });

    test('accented Latin letters sort with their base letter', () {
      expect(
        _sorted(['Zebra', 'Éclair', 'Apple', 'Über', 'Łódź', 'Çay', 'Ärger']),
        ['Apple', 'Ärger', 'Çay', 'Éclair', 'Łódź', 'Über', 'Zebra'],
      );
      // The plain spelling comes first, then the accented one.
      expect(_sorted(['Café', 'Cafe', 'Cafd']), ['Cafd', 'Cafe', 'Café']);
      // Case, leading space and combining marks do not matter.
      expect(_sorted(['  beta', 'Alpha', 'alpha2', 'éclair']), [
        'Alpha',
        'alpha2',
        '  beta',
        'éclair',
      ]);
    });

    test('equal titles keep their order and digits come before letters', () {
      final songs = [
        ('b', 'Same'),
        ('a', 'Same'),
        ('c', '1999'),
        ('d', 'Abba'),
      ];
      expect(sortedByTitle(songs, (song) => song.$2).map((song) => song.$1), [
        'c',
        'd',
        'b',
        'a',
      ]);
    });

    test('index letters fold accents and agree with the sort order', () {
      expect(songIndexLetter('Éclair'), 'E');
      expect(songIndexLetter('Über'), 'U');
      expect(songIndexLetter('Łódź'), 'L');
      expect(songIndexLetter('Şarkı'), 'S');
      expect(songIndexLetter('ßtraße'), 'S');
      expect(songIndexLetter('ıslak'), 'I');
      expect(songIndexLetter('Їжак'), 'Ї');
      expect(songIndexLetter('  zebra'), 'Z');
      expect(songIndexLetter(''), '#');
      expect(songIndexLetter('😀 Smile'), '😀');

      // One contiguous run of songs per letter, whatever the spelling.
      final titles = [
        'Éclair',
        'Eagle',
        '  Echo',
        'Ärger',
        'Apple',
        'Яблуко',
        'Їжак',
        'ıslak',
        'Ice',
      ];
      final letters = _sorted(titles).map(songIndexLetter).toList();
      final seen = <String>{};
      String? previous;
      for (final letter in letters) {
        if (letter != previous) {
          expect(seen.add(letter), isTrue, reason: '$letter split in $letters');
        }
        previous = letter;
      }
    });

    test('search folds case, accents and surrounding spaces', () {
      expect(foldForSearch('  Éclair '), 'eclair');
      expect(foldForSearch('Łódź'), 'lodz');
      expect(foldForSearch('İstanbul'), 'istanbul');
      expect(foldForSearch('Straße'), 'strasse');
      expect(foldForSearch('Їжак'), 'їжак');
    });
  });
}
