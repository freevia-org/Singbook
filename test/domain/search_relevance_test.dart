import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/domain/models.dart';
import 'package:singbook/domain/search_grouping.dart';

SongCandidate _row(String title, String artist) => SongCandidate(
  providerId: 'genius',
  id: '$title/$artist',
  title: title,
  artist: artist,
);

List<String> _ranked(String query, List<SongCandidate> rows) {
  final indexed = rows.indexed.toList()
    ..sort((a, b) {
      final relevance = searchRelevance(
        b.$2,
        query,
      ).compareTo(searchRelevance(a.$2, query));
      return relevance != 0 ? relevance : a.$1.compareTo(b.$1);
    });
  return [for (final (_, row) in indexed) '${row.title} / ${row.artist}'];
}

void main() {
  test('the original outranks an instrumental naming the artist', () {
    expect(
      _ranked('harbor lights mariners', [
        _row('Harbor Lights (Mariners Instrumental Version)', 'Cleaning Tunes'),
        _row('Harbor Lights', 'The Mariners'),
        _row('Harbor Lights', 'The Mariners Orchestra'),
      ]),
      [
        'Harbor Lights / The Mariners',
        'Harbor Lights / The Mariners Orchestra',
        'Harbor Lights (Mariners Instrumental Version) / Cleaning Tunes',
      ],
    );
  });

  test('karaoke, tribute and translation pages rank below the song', () {
    expect(
      _ranked('harbor lights', [
        _row('Harbor Lights (English Translation)', 'Genius Translations'),
        _row('Harbor Lights', 'Karaoke Kings'),
        _row('Harbor Lights - Piano Version', 'Quiet Keys'),
        _row('Harbor Lights', 'The Mariners'),
      ]).first,
      'Harbor Lights / The Mariners',
    );
  });

  test('a query asking for another performance keeps it in place', () {
    expect(
      _ranked('harbor lights karaoke', [
        _row('Harbor Lights', 'The Mariners'),
        _row('Harbor Lights (Karaoke Version)', 'Sing Along Band'),
      ]).first,
      'Harbor Lights (Karaoke Version) / Sing Along Band',
    );
  });

  test('without an artist in the query, artist names do not decide', () {
    expect(
      _ranked('harbor lights', [
        _row('Harbor Lights', 'The Mariners of the Northern Coast'),
        _row('Harbor Lights', 'Ann'),
      ]),
      [
        'Harbor Lights / The Mariners of the Northern Coast',
        'Harbor Lights / Ann',
      ],
    );
  });

  test('a title word in the query counts once even if the artist has it', () {
    expect(
      searchRelevance(_row('Mariners', 'The Mariners'), 'mariners'),
      searchRelevance(_row('Mariners', 'Other Band'), 'mariners'),
    );
  });

  test('a cover crediting the original artist in its title ranks below', () {
    expect(
      _ranked('harbor lights mariners', [
        _row('Harbor Lights (The Mariners)', 'Quiet Singer'),
        _row('Harbor Lights - The Mariners (Traduzione)', 'Genius Traduzioni'),
        _row('Harbor Lights', 'The Mariners'),
      ]).first,
      'Harbor Lights / The Mariners',
    );
  });

  test('a subtitle in brackets matches when the artist matches too', () {
    expect(
      _ranked('lanterns over quiet water mariners', [
        _row('Lanterns Over Quiet Water', 'Other Band'),
        _row('Lanterns (Over Quiet Water)', 'The Mariners'),
      ]).first,
      'Lanterns (Over Quiet Water) / The Mariners',
    );
  });

  test('only Genius translation accounts are treated as translations', () {
    expect(
      _ranked('lanterns', [
        _row('Lanterns (Live)', 'Other Band'),
        _row('Lanterns', 'Perfume Genius'),
      ]).first,
      'Lanterns / Perfume Genius',
    );
    expect(
      _ranked('lanterns', [
        _row('Lanterns (Traduzione Italiana)', 'Genius Traduzioni Italiane'),
        _row('Lanterns', 'Other Band'),
      ]).first,
      'Lanterns / Other Band',
    );
  });
}
