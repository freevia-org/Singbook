import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/providers/core/catalogs.dart';
import 'package:singbook/providers/core/service.dart' as discovery;

String _title(String trackName, {String artist = 'Mira North'}) =>
    LrclibProvider.parseSong({
      'id': 7,
      'trackName': trackName,
      'artistName': artist,
      'albumName': 'First Record',
      'duration': 200,
    }).title;

void main() {
  test('a track name carrying its own artist keeps the title only', () {
    expect(_title('Paper Windows - Mira North'), 'Paper Windows');
    expect(_title('Mira North – Paper Windows'), 'Paper Windows');
    expect(_title('Paper Windows - mira north'), 'Paper Windows');
  });

  test('other dashed titles are kept', () {
    expect(_title('Paper Windows - Live'), 'Paper Windows - Live');
    expect(_title('Mira North'), 'Mira North');
    expect(_title('One - Two - Mira North'), 'One - Two - Mira North');
  });

  test('the cleaned row matches a chart titled by the song alone', () {
    final row = LrclibProvider.parseSong({
      'id': 7,
      'trackName': 'Paper Windows - Mira North',
      'artistName': 'Mira North',
      'albumName': 'First Record',
      'duration': 200,
    });
    final chart = LrclibProvider.parseSong({
      'id': 8,
      'trackName': 'Paper Windows',
      'artistName': 'Mira North',
    });
    expect(discovery.sameSong(row, chart), isTrue);
  });
}
