part of 'file_actions.dart';

/// The songs of [setlist] in order, each with its entry's key and capo
/// overrides applied (chords transposed to the override key), exactly as the
/// reader shows them. Entries whose song is missing are skipped.
List<SongDocument> _songsInSetlist(
  SetlistDocument setlist,
  List<SongDocument> songs,
) {
  final byId = {for (final song in songs) song.id: song};
  return [
    for (final entry in setlist.entries)
      if (byId[entry.songId] case final song?)
        _applyEntryOverrides(song, entry),
  ];
}

/// Same name as the song list the PDF/print/copy paths use, for tests.
@visibleForTesting
List<SongDocument> songsForSetlist(
  SetlistDocument setlist,
  List<SongDocument> songs,
) => _songsInSetlist(setlist, songs);

int? _keyPitch(String key) {
  final match = RegExp(r'^\s*([A-G])([#b♯♭]?)').firstMatch(key);
  if (match == null) return null;
  const pitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final accidental = match.group(2);
  final shift = accidental == '#' || accidental == '♯'
      ? 1
      : accidental == 'b' || accidental == '♭'
      ? -1
      : 0;
  return (pitches[match.group(1)]! + shift + 12) % 12;
}

SongDocument _applyEntryOverrides(SongDocument song, SetlistEntry entry) {
  final key = entry.overrides['key']?.toString().trim() ?? '';
  final capo = entry.overrides['capo'];
  final hasCapo = capo != null && capo.toString().trim().isNotEmpty;
  if (key.isEmpty && !hasCapo) return song;
  final metadata = Map<String, Object?>.from(song.metadata);
  var body = song.body;
  if (key.isNotEmpty) {
    final from = _keyPitch(song.metadata['key']?.toString() ?? '');
    final to = _keyPitch(key);
    if (from != null && to != null && from != to) {
      body = transposeBody(body, (to - from + 12) % 12);
    }
    metadata['key'] = key;
  }
  if (hasCapo) metadata['capo'] = capo;
  return song.copyWith(body: body, metadata: metadata);
}

List<String> _songMetadataLines(SongDocument song) {
  final values = <String>[];
  void add(String label, Object? raw) {
    final value = raw?.toString().trim();
    if (value != null && value.isNotEmpty) values.add('$label: $value');
  }

  add('Album', song.metadata['album']);
  add('Year', song.metadata['year']);
  add('Key', song.metadata['key']);
  add('Capo', song.metadata['capo']);
  add('Tuning', song.metadata['tuning']);
  final tempo = song.metadata['tempo'];
  if (tempo != null && tempo.toString().trim().isNotEmpty) {
    add('Tempo', '${tempo.toString().trim()} BPM');
  }
  add('Time', song.metadata['timeSignature']);
  final duration = song.metadata['durationSeconds'];
  if (duration is num && duration > 0) {
    final seconds = duration.round();
    add(
      'Duration',
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
    );
  }
  add('Composer', song.metadata['composer']);
  add('Lyricist', song.metadata['lyricist']);
  return values;
}

/// Plain text counterpart to the song PDF: title, metadata, chord rows, lyrics.
String songPlainText(SongDocument song) {
  final out = StringBuffer(song.title);
  if (song.artist.trim().isNotEmpty) {
    out.write('\nArtist: ${song.artist.trim()}');
  }
  for (final value in _songMetadataLines(song)) {
    out.write('\n$value');
  }
  out.write('\n\n${_songBodyPlainText(song)}');
  return out.toString().trimRight();
}

String setlistPlainText(SetlistDocument setlist, List<SongDocument> songs) {
  final out = StringBuffer(setlist.name);
  final ordered = _songsInSetlist(setlist, songs);
  for (var index = 0; index < ordered.length; index++) {
    final song = ordered[index];
    out.write('\n\n${index + 1}. ${song.title}');
    if (song.artist.trim().isNotEmpty) out.write(' — ${song.artist.trim()}');
  }
  for (final song in ordered) {
    out.write('\n\n${songPlainText(song)}');
  }
  return out.toString().trimRight();
}

String _songBodyPlainText(SongDocument song) {
  final out = StringBuffer();
  for (final line in parseArrangement(song.body)) {
    if (line.directive) {
      final heading = _pdfSectionHeading(line.text);
      if (heading != null) {
        if (out.isNotEmpty) out.write('\n');
        out.writeln(heading);
      }
      continue;
    }
    if (line.chords.isNotEmpty) out.writeln(_chordRow(line));
    out.writeln(line.text);
  }
  return out.toString().trimRight();
}

String _htmlEscape(String value) => const HtmlEscape().convert(value);

/// Receiving apps (Excel, Word, Outlook) collapse runs of spaces in HTML, which
/// destroys chord alignment. Non-breaking spaces survive in all of them; keep
/// the first space of a run breakable unless [all] is set.
String _htmlPreserveSpaces(String escaped, {bool all = false}) => all
    ? escaped.replaceAll(' ', '&nbsp;')
    : escaped.replaceAllMapped(
        RegExp(' {2,}'),
        (m) => ' ${'&nbsp;' * (m.group(0)!.length - 1)}',
      );

String _songBodyRichHtml(SongDocument song) {
  final out = StringBuffer();
  for (final line in parseArrangement(song.body)) {
    if (line.directive) {
      final heading = _pdfSectionHeading(line.text);
      if (heading != null) out.write('<h2>${_htmlEscape(heading)}</h2>');
      continue;
    }
    if (line.text.trim().isEmpty && line.chords.isEmpty) {
      out.write('<br>');
      continue;
    }
    if (line.chords.isNotEmpty) {
      out.write(
        '<div class="chords"><code style="white-space:pre">'
        '${_htmlPreserveSpaces(_htmlEscape(_chordRow(line)), all: true)}'
        '</code></div>',
      );
    }
    out.write(
      '<p>${_htmlPreserveSpaces(_htmlEscape(line.text.isEmpty ? ' ' : line.text))}</p>',
    );
  }
  return out.toString();
}

/// Title, artist, metadata and body of one song, shared by the song and
/// setlist documents.
String _songRichHtmlContent(SongDocument song) =>
    '<h1>${_htmlEscape(song.title)}</h1>'
    '${song.artist.trim().isEmpty ? '' : '<p><strong>Artist:</strong> ${_htmlEscape(song.artist.trim())}</p>'}'
    '${_songMetadataLines(song).map((line) => '<p class="metadata">${_htmlEscape(line)}</p>').join()}'
    '${_songBodyRichHtml(song)}';

String songRichHtml(SongDocument song) =>
    '<!doctype html><html><body><article>'
    '${_songRichHtmlContent(song)}'
    '</article></body></html>';

String setlistRichHtml(SetlistDocument setlist, List<SongDocument> songs) {
  final ordered = _songsInSetlist(setlist, songs);
  final out = StringBuffer(
    '<!doctype html><html><body><article><h1>${_htmlEscape(setlist.name)}</h1>',
  );
  for (var index = 0; index < ordered.length; index++) {
    final song = ordered[index];
    out.write(
      '<p class="setlist-entry">${index + 1}. ${_htmlEscape(song.title)}',
    );
    if (song.artist.trim().isNotEmpty) {
      out.write(' — ${_htmlEscape(song.artist.trim())}');
    }
    out.write('</p>');
  }
  for (final song in ordered) {
    out.write('<section>${_songRichHtmlContent(song)}</section>');
  }
  out.write('</article></body></html>');
  return out.toString();
}
