/// A deliberately small, non-executing reader for Mutopia LilyPond files.
///
/// This is not a LilyPond interpreter. It accepts literal metadata and a
/// bounded subset of lyric-mode syntax, and rejects constructs whose lyric
/// output cannot be established without evaluation.
library;

class MutopiaFormatException implements Exception {
  const MutopiaFormatException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => offset == null
      ? 'MutopiaFormatException: $message'
      : 'MutopiaFormatException at $offset: $message';
}

class MutopiaSourceSpan {
  const MutopiaSourceSpan(this.start, this.end);

  final int start;
  final int end;
}

class MutopiaLyricSyllable {
  const MutopiaLyricSyllable({
    required this.text,
    required this.span,
    this.joinBefore = MutopiaLyricJoin.space,
  });

  final String text;
  final MutopiaSourceSpan span;
  final MutopiaLyricJoin joinBefore;
}

enum MutopiaLyricJoin { space, continuation, tie }

class MutopiaLyricStream {
  const MutopiaLyricStream({
    required this.publisherVariable,
    required this.literalVoiceReference,
    required this.attachmentVerified,
    required this.text,
    required this.syllables,
    required this.sourceSpan,
    required this.bodySpan,
  });

  /// Literal LilyPond variable name. This is not a verified language label.
  final String? publisherVariable;

  /// Literal voice name found in a `\\lyricsto` reference.
  ///
  /// This lexical reference does not establish that the containing expression
  /// is reachable, printed, or active in a score.
  final String? literalVoiceReference;

  /// Always false for this inert parser; it does not expand LilyPond contexts.
  final bool attachmentVerified;

  /// Reconstructed words. Source line breaks are intentionally not retained
  /// as poetic or timing boundaries.
  final String text;
  final List<MutopiaLyricSyllable> syllables;
  final MutopiaSourceSpan sourceSpan;
  final MutopiaSourceSpan bodySpan;
}

class MutopiaLilypondDocument {
  const MutopiaLilypondDocument({
    required this.version,
    required this.header,
    required this.lyricStreams,
    required this.footer,
  });

  final String? version;
  final Map<String, String> header;
  final List<MutopiaLyricStream> lyricStreams;
  final String? footer;

  String? get title => header['title'];
  String? get mutopiatitle => header['mutopiatitle'];
  String? get composer => header['composer'];
  String? get poet => header['poet'];
  String? get arranger => header['arranger'];
  String? get source => header['source'];
  String? get license => header['license'];
  String? get date => header['date'];
}

const int _maxSourceChars = 512 * 1024;
const int _maxTokens = 100000;
const int _maxDepth = 128;
const int _maxStreams = 32;
const int _maxDecodedChars = 128 * 1024;

/// Parses the documented literal subset of Mutopia LilyPond lyric sources.
/// No LilyPond, Scheme, include, or external resource is evaluated or loaded.
MutopiaLilypondDocument parseMutopiaLilypond(String source) {
  if (source.length > _maxSourceChars) {
    throw const MutopiaFormatException('source exceeds size limit');
  }
  final tokens = _Lexer(source).scan();
  final header = <String, String>{};
  String? version;
  String? footer;
  final assignments = <_Assignment>[];
  var versionCount = 0;

  // Bracket-aware top-level assignment discovery. Strings/comments are tokens
  // and therefore cannot masquerade as syntax here.
  var depth = 0;
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (depth == 0 && t.kind == _Kind.command && t.value == r'\version') {
      final value = _next(tokens, i + 1);
      if (value?.kind != _Kind.string) {
        throw MutopiaFormatException(
          'version must be a literal string',
          offset: t.start,
        );
      }
      if (++versionCount > 1) {
        throw MutopiaFormatException(
          'multiple version declarations',
          offset: t.start,
        );
      }
      version = value!.value;
    }
    if (t.kind == _Kind.symbol && t.value == '{') {
      depth++;
      if (depth > _maxDepth) {
        throw MutopiaFormatException('nesting exceeds limit', offset: t.start);
      }
      continue;
    }
    if (t.kind == _Kind.symbol && t.value == '}') {
      depth--;
      if (depth < 0) {
        throw MutopiaFormatException('unbalanced brace', offset: t.start);
      }
      continue;
    }
    if (depth == 0 &&
        t.kind == _Kind.word &&
        i + 1 < tokens.length &&
        tokens[i + 1].value == '=') {
      assignments.add(_Assignment(t.value, i, i + 2));
    }
  }
  if (depth != 0) throw const MutopiaFormatException('unclosed brace');

  // Read only literal values in a literal \header block. Dynamic Scheme and
  // arbitrary expressions are never interpreted as metadata.
  var headerCount = 0;
  var headerScanDepth = 0;
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (token.kind == _Kind.symbol && token.value == '}') headerScanDepth--;
    if (token.kind == _Kind.command && token.value == r'\header') {
      if (headerScanDepth != 0) {
        throw MutopiaFormatException(
          'nested header blocks are unsupported',
          offset: token.start,
        );
      }
      if (i + 1 >= tokens.length || tokens[i + 1].value != '{') {
        throw MutopiaFormatException(
          'header requires a literal block',
          offset: token.start,
        );
      }
      if (++headerCount > 1) {
        throw MutopiaFormatException(
          'multiple header blocks',
          offset: token.start,
        );
      }
      final close = _matchingBrace(tokens, i + 1);
      var headerDepth = 1;
      for (var j = i + 2; j < close; j++) {
        if (tokens[j].kind == _Kind.symbol && tokens[j].value == '{') {
          headerDepth++;
          continue;
        }
        if (tokens[j].kind == _Kind.symbol && tokens[j].value == '}') {
          headerDepth--;
          continue;
        }
        if (headerDepth == 1 &&
            j + 1 < close &&
            tokens[j].kind == _Kind.word &&
            tokens[j + 1].value == '=') {
          final name = tokens[j].value;
          if (j + 2 >= close || tokens[j + 2].kind != _Kind.string) {
            if (const {
              'title',
              'mutopiatitle',
              'composer',
              'poet',
              'arranger',
              'source',
              'license',
              'date',
              'footer',
            }.contains(name)) {
              throw MutopiaFormatException(
                'metadata field $name must be a literal string',
                offset: tokens[j].start,
              );
            }
            continue;
          }
          final value = tokens[j + 2].value;
          final previous = header[name];
          if (previous != null && previous != value) {
            throw MutopiaFormatException(
              'conflicting header value for $name',
              offset: tokens[j].start,
            );
          }
          header[name] = value;
        }
      }
    }
    if (token.kind == _Kind.symbol && token.value == '{') headerScanDepth++;
  }
  footer = header['footer'];

  // Resolve literal variable definitions and their lyricsto references.
  final definitions = <String, _LyricDefinition>{};
  for (var a = 0; a < assignments.length; a++) {
    final assignment = assignments[a];
    final end = a + 1 < assignments.length
        ? assignments[a + 1].startIndex
        : tokens.length;
    final lyricIndex = _findCommand(
      tokens,
      assignment.valueIndex,
      end,
      r'\lyricmode',
    );
    if (lyricIndex == null) continue;
    if (lyricIndex != assignment.valueIndex) {
      throw MutopiaFormatException(
        'dynamic lyric variable construction is unsupported',
        offset: tokens[assignment.valueIndex].start,
      );
    }
    final bodyOpen = _findSymbol(tokens, lyricIndex + 1, end, '{');
    if (bodyOpen == null) {
      throw MutopiaFormatException(
        'lyricmode requires a literal body',
        offset: tokens[lyricIndex].start,
      );
    }
    final bodyClose = _matchingBrace(tokens, bodyOpen);
    if (bodyClose >= end) {
      throw MutopiaFormatException(
        'lyric body crosses its definition',
        offset: tokens[bodyOpen].start,
      );
    }
    if (definitions.containsKey(assignment.name)) {
      throw MutopiaFormatException(
        'duplicate lyric variable ${assignment.name}',
        offset: tokens[assignment.nameIndex].start,
      );
    }
    definitions[assignment.name] = _LyricDefinition(
      assignment.name,
      tokens[assignment.nameIndex].start,
      tokens[assignment.valueIndex].start,
      tokens[bodyOpen].end,
      tokens[bodyClose].start,
      tokens[bodyClose].end,
      bodyOpen,
      bodyClose,
    );
  }

  final assignmentCounts = <String, int>{};
  for (final assignment in assignments) {
    assignmentCounts.update(
      assignment.name,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  for (final definition in definitions.values) {
    if (assignmentCounts[definition.name]! > 1) {
      throw MutopiaFormatException(
        'duplicate root binding for ${definition.name}',
        offset: definition.start,
      );
    }
  }

  final voiceReferences = <String, String>{};
  for (var i = 0; i < tokens.length; i++) {
    if (tokens[i].kind == _Kind.command && tokens[i].value == r'\include' ||
        tokens[i].kind == _Kind.command &&
            tokens[i].value == r'\sourcefilename') {
      throw MutopiaFormatException(
        'external source dependencies are unsupported',
        offset: tokens[i].start,
      );
    }
    if (tokens[i].kind == _Kind.command &&
        (tokens[i].value == r'\addlyrics' || tokens[i].value == r'\lyrics')) {
      throw MutopiaFormatException(
        'unsupported lyric entry route ${tokens[i].value}',
        offset: tokens[i].start,
      );
    }
    if (tokens[i].kind == _Kind.command &&
        (tokens[i].value == r'\new' || tokens[i].value == r'\context') &&
        i + 1 < tokens.length &&
        tokens[i + 1].kind == _Kind.word &&
        tokens[i + 1].value.toLowerCase() == 'lyrics') {
      var hasExplicitBinding = false;
      for (var j = i + 2; j < tokens.length; j++) {
        if (tokens[j].kind == _Kind.symbol && tokens[j].value == '{') break;
        if (tokens[j].kind == _Kind.command &&
            tokens[j].value == r'\lyricsto') {
          hasExplicitBinding = true;
          break;
        }
        if (tokens[j].kind == _Kind.command &&
            (tokens[j].value == r'\new' || tokens[j].value == r'\context')) {
          break;
        }
      }
      if (!hasExplicitBinding) {
        throw MutopiaFormatException(
          'unsupported Lyrics context entry route',
          offset: tokens[i].start,
        );
      }
    }
    if (tokens[i].kind == _Kind.command && tokens[i].value == r'\lyricsto') {
      final voice = _next(tokens, i + 1);
      final variable = _next(tokens, i + 2);
      if (voice?.kind != _Kind.string ||
          variable?.kind != _Kind.command ||
          !variable!.value.startsWith(r'\')) {
        throw MutopiaFormatException(
          'unsupported lyricsto binding',
          offset: tokens[i].start,
        );
      }
      final name = variable.value.substring(1);
      if (!definitions.containsKey(name)) {
        throw MutopiaFormatException(
          'unresolved lyric variable $name',
          offset: variable.start,
        );
      }
      if (voiceReferences.containsKey(name)) {
        throw MutopiaFormatException(
          'ambiguous duplicate binding for $name',
          offset: tokens[i].start,
        );
      }
      voiceReferences[name] = voice!.value;
    }
  }

  final streams = <MutopiaLyricStream>[];
  var aggregateDecodedChars = 0;
  for (final definition in definitions.values) {
    if (streams.length >= _maxStreams) {
      throw const MutopiaFormatException('too many lyric streams');
    }
    final parsed = _parseLyricBody(
      tokens,
      definition.bodyOpenIndex + 1,
      definition.bodyCloseIndex,
      _maxDecodedChars - aggregateDecodedChars,
    );
    aggregateDecodedChars += parsed.text.length;
    streams.add(
      MutopiaLyricStream(
        publisherVariable: definition.name,
        literalVoiceReference: voiceReferences[definition.name],
        attachmentVerified: false,
        text: parsed.text,
        syllables: List.unmodifiable(parsed.syllables),
        sourceSpan: MutopiaSourceSpan(definition.start, definition.end),
        bodySpan: MutopiaSourceSpan(definition.bodyStart, definition.bodyEnd),
      ),
    );
  }
  // A direct `text = \lyricmode { ... }` form is already handled as a
  // variable. Reject other lyricmode sites rather than silently dropping them.
  final known = definitions.values.map((d) => d.lyricStart).toSet();
  for (final token in tokens) {
    if (token.kind == _Kind.command &&
        token.value == r'\lyricmode' &&
        !known.contains(token.start)) {
      throw MutopiaFormatException(
        'lyricmode outside a literal variable is unsupported',
        offset: token.start,
      );
    }
  }
  return MutopiaLilypondDocument(
    version: version,
    header: Map.unmodifiable(header),
    lyricStreams: List.unmodifiable(streams),
    footer: footer,
  );
}

class _Assignment {
  const _Assignment(this.name, this.nameIndex, this.valueIndex);
  final String name;
  final int nameIndex;
  final int valueIndex;
  int get startIndex => nameIndex;
}

class _LyricDefinition {
  const _LyricDefinition(
    this.name,
    this.start,
    this.lyricStart,
    this.bodyStart,
    this.bodyEnd,
    this.end,
    this.bodyOpenIndex,
    this.bodyCloseIndex,
  );
  final String name;
  final int start;
  final int lyricStart;
  final int bodyStart;
  final int bodyEnd;
  final int end;
  final int bodyOpenIndex;
  final int bodyCloseIndex;
}

class _ParsedLyrics {
  const _ParsedLyrics(this.text, this.syllables);
  final String text;
  final List<MutopiaLyricSyllable> syllables;
}

_ParsedLyrics _parseLyricBody(
  List<_Token> tokens,
  int start,
  int end,
  int maxDecodedChars,
) {
  final syllables = <MutopiaLyricSyllable>[];
  var pending = MutopiaLyricJoin.space;
  var outputLength = 0;
  for (var i = start; i < end; i++) {
    final token = tokens[i];
    if (token.kind == _Kind.command) {
      if (token.value == r'\barNumberCheck' &&
          i + 1 < end &&
          tokens[i + 1].kind == _Kind.word) {
        final argument = tokens[i + 1].value;
        final match = RegExp(r'^#?([0-9]+)$').firstMatch(argument);
        final digits = match?.group(1);
        if (digits != null &&
            digits.length <= 6 &&
            int.parse(digits) <= 999999) {
          i++;
          continue;
        }
      }
      throw MutopiaFormatException(
        'commands in lyric bodies are unsupported',
        offset: token.start,
      );
    }
    if (token.kind == _Kind.scheme) {
      throw MutopiaFormatException(
        'dynamic Scheme lyric construction is unsupported',
        offset: token.start,
      );
    }
    if (token.kind == _Kind.string) {
      if (token.value.isEmpty) {
        throw MutopiaFormatException(
          'empty quoted lyric token',
          offset: token.start,
        );
      }
      _appendSyllable(syllables, token.value, token, pending);
      outputLength += token.value.length + 1;
      if (outputLength > maxDecodedChars) {
        throw const MutopiaFormatException('decoded lyrics exceed size limit');
      }
      pending = MutopiaLyricJoin.space;
      continue;
    }
    if (token.kind == _Kind.word) {
      // Numeric duration/timing syntax and substitutions are outside the
      // supported plain-text grammar.
      if (token.value.startsWith('#')) {
        throw MutopiaFormatException(
          'Scheme or dynamic lyric token is unsupported',
          offset: token.start,
        );
      }
      if (RegExp(r'^[0-9]+$').hasMatch(token.value)) {
        throw MutopiaFormatException(
          'duration or numeric lyric syntax is unsupported',
          offset: token.start,
        );
      }
      final pieces = token.value.split(RegExp(r'[_~]'));
      if (pieces.any((p) => p.isEmpty)) {
        throw MutopiaFormatException(
          'unsupported embedded lyric separator',
          offset: token.start,
        );
      }
      final separators = RegExp(
        r'[_~]',
      ).allMatches(token.value).map((m) => m.group(0)!).toList();
      for (var p = 0; p < pieces.length; p++) {
        _appendSyllable(
          syllables,
          pieces[p],
          token,
          p == 0
              ? pending
              : (separators[p - 1] == '~'
                    ? MutopiaLyricJoin.tie
                    : MutopiaLyricJoin.space),
        );
        outputLength += pieces[p].length + 1;
        if (outputLength > maxDecodedChars) {
          throw const MutopiaFormatException(
            'decoded lyrics exceed size limit',
          );
        }
      }
      pending = MutopiaLyricJoin.space;
      continue;
    }
    if (token.kind == _Kind.symbol) {
      if (token.value == '--') {
        if (syllables.isEmpty || pending != MutopiaLyricJoin.space) {
          throw MutopiaFormatException(
            'misplaced lyric hyphen',
            offset: token.start,
          );
        }
        pending = MutopiaLyricJoin.continuation;
      } else if (token.value == '_' || token.value == '__') {
        // Extenders and skips affect musical alignment, but not recovered
        // word text. Keep parsing and do not treat them as timing evidence.
      } else if (token.value == '~') {
        if (syllables.isEmpty || pending != MutopiaLyricJoin.space) {
          throw MutopiaFormatException(
            'misplaced lyric tie',
            offset: token.start,
          );
        }
        pending = MutopiaLyricJoin.tie;
      } else {
        throw MutopiaFormatException(
          'unsupported lyric syntax ${token.value}',
          offset: token.start,
        );
      }
      continue;
    }
    throw MutopiaFormatException(
      'unsupported lyric token',
      offset: token.start,
    );
  }
  if (pending == MutopiaLyricJoin.continuation ||
      pending == MutopiaLyricJoin.tie) {
    throw const MutopiaFormatException('trailing lyric join marker');
  }
  final text = StringBuffer();
  for (var i = 0; i < syllables.length; i++) {
    if (i > 0) {
      switch (syllables[i].joinBefore) {
        case MutopiaLyricJoin.space:
          text.write(' ');
          break;
        case MutopiaLyricJoin.continuation:
          break;
        case MutopiaLyricJoin.tie:
          text.write(' ');
          break;
      }
    }
    text.write(syllables[i].text);
  }
  return _ParsedLyrics(text.toString(), syllables);
}

void _appendSyllable(
  List<MutopiaLyricSyllable> out,
  String value,
  _Token token,
  MutopiaLyricJoin join,
) {
  out.add(
    MutopiaLyricSyllable(
      text: value,
      span: MutopiaSourceSpan(token.start, token.end),
      joinBefore: out.isEmpty ? MutopiaLyricJoin.space : join,
    ),
  );
}

int? _findCommand(List<_Token> tokens, int start, int end, String command) {
  for (var i = start; i < end; i++) {
    if (tokens[i].kind == _Kind.command && tokens[i].value == command) return i;
  }
  return null;
}

int? _findSymbol(List<_Token> tokens, int start, int end, String symbol) {
  for (var i = start; i < end; i++) {
    if (tokens[i].kind == _Kind.symbol && tokens[i].value == symbol) return i;
  }
  return null;
}

int _matchingBrace(List<_Token> tokens, int open) {
  var depth = 0;
  for (var i = open; i < tokens.length; i++) {
    if (tokens[i].kind != _Kind.symbol) continue;
    if (tokens[i].value == '{' && ++depth > _maxDepth) {
      throw MutopiaFormatException(
        'nesting exceeds limit',
        offset: tokens[i].start,
      );
    }
    if (tokens[i].value == '}' && --depth == 0) return i;
  }
  throw MutopiaFormatException(
    'unclosed lyric or metadata brace',
    offset: tokens[open].start,
  );
}

_Token? _next(List<_Token> tokens, int index) =>
    index < tokens.length ? tokens[index] : null;

enum _Kind { word, command, string, symbol, scheme }

class _Token {
  const _Token(this.kind, this.value, this.start, this.end);
  final _Kind kind;
  final String value;
  final int start;
  final int end;
}

class _Lexer {
  _Lexer(this.source);
  final String source;
  final _tokens = <_Token>[];
  var _i = 0;

  List<_Token> scan() {
    while (_i < source.length) {
      final c = source[_i];
      if (_space(c)) {
        _i++;
        continue;
      }
      if (source.startsWith('%{', _i)) {
        _skipBlockComment();
        continue;
      }
      if (c == '%') {
        while (_i < source.length && source[_i] != '\n') {
          _i++;
        }
        continue;
      }
      final start = _i;
      if (source.startsWith("#'(", _i)) {
        _skipQuotedScheme(start, _i + 2);
        continue;
      }
      if (source.startsWith("#'", _i)) {
        _skipSchemeAtom(start, _i + 2);
        continue;
      }
      if (source.startsWith("'(", _i)) {
        _skipQuotedScheme(start, _i + 1);
        continue;
      }
      if (c == '"') {
        _i++;
        final value = StringBuffer();
        var closed = false;
        while (_i < source.length) {
          final ch = source[_i++];
          if (ch == '"') {
            closed = true;
            break;
          }
          if (ch == '\\') {
            if (_i >= source.length) {
              throw MutopiaFormatException(
                'truncated string escape',
                offset: start,
              );
            }
            final escaped = source[_i++];
            if (escaped != 'n' &&
                escaped != 't' &&
                escaped != 'r' &&
                escaped != '"' &&
                escaped != '\\') {
              throw MutopiaFormatException(
                'unsupported quoted escape',
                offset: _i - 2,
              );
            }
            value.write(switch (escaped) {
              'n' => '\n',
              't' => '\t',
              'r' => '\r',
              _ => escaped,
            });
          } else {
            value.write(ch);
          }
          if (value.length > _maxDecodedChars) {
            throw MutopiaFormatException(
              'string exceeds size limit',
              offset: start,
            );
          }
        }
        if (!closed) {
          throw MutopiaFormatException('unterminated string', offset: start);
        }
        _add(_Kind.string, value.toString(), start);
        continue;
      }
      if (c == '\\') {
        _i++;
        while (_i < source.length && _commandChar(source[_i])) {
          _i++;
        }
        if (_i == start + 1) {
          if (_i >= source.length || _space(source[_i])) {
            throw MutopiaFormatException('truncated command', offset: start);
          }
          _i++;
        }
        _add(_Kind.command, source.substring(start, _i), start);
        continue;
      }
      if (source.startsWith('#(', _i)) {
        _skipScheme();
        continue;
      }
      if (source.startsWith('--', _i)) {
        _i += 2;
        _add(_Kind.symbol, '--', start);
        continue;
      }
      if (c == '_') {
        while (_i < source.length && source[_i] == '_') {
          _i++;
        }
        _add(_Kind.symbol, source.substring(start, _i), start);
        continue;
      }
      if ('{}=()<>~_'.contains(c)) {
        _i++;
        _add(_Kind.symbol, c, start);
        continue;
      }
      // Punctuation is part of a plain syllable unless it is a syntax token.
      _i++;
      while (_i < source.length &&
          !_space(source[_i]) &&
          !'{}=()<>~"%\\'.contains(source[_i]) &&
          !source.startsWith('--', _i)) {
        _i++;
      }
      _add(_Kind.word, source.substring(start, _i), start);
    }
    return List.unmodifiable(_tokens);
  }

  void _add(_Kind kind, String value, int start) {
    _tokens.add(_Token(kind, value, start, _i));
    if (_tokens.length > _maxTokens) {
      throw const MutopiaFormatException('token count exceeds limit');
    }
  }

  bool _space(String c) => c.trim().isEmpty;
  bool _commandChar(String c) => RegExp(r'[A-Za-z0-9_-]').hasMatch(c);

  void _skipSchemeAtom(int start, int afterPrefix) {
    _i = afterPrefix;
    while (_i < source.length &&
        !_space(source[_i]) &&
        !'{}()"%'.contains(source[_i])) {
      _i++;
    }
    _add(_Kind.scheme, 'Scheme quoted atom', start);
  }

  void _skipBlockComment() {
    final start = _i;
    var depth = 0;
    while (_i < source.length) {
      if (source.startsWith('%{', _i)) {
        if (++depth > _maxDepth) {
          throw MutopiaFormatException(
            'comment nesting exceeds limit',
            offset: start,
          );
        }
        _i += 2;
      } else if (source.startsWith('%}', _i)) {
        _i += 2;
        if (--depth == 0) return;
      } else {
        _i++;
      }
    }
    throw MutopiaFormatException('unterminated block comment', offset: start);
  }

  void _skipQuotedScheme(int start, int openingParen) {
    _i = openingParen;
    var depth = 0;
    while (_i < source.length) {
      final c = source[_i++];
      if (c == '"') {
        var closed = false;
        while (_i < source.length) {
          final quoted = source[_i++];
          if (quoted == '\\' && _i < source.length) {
            _i++;
            continue;
          }
          if (quoted == '"') {
            closed = true;
            break;
          }
        }
        if (!closed) {
          throw MutopiaFormatException(
            'unterminated Scheme string',
            offset: start,
          );
        }
      } else if (c == ';') {
        while (_i < source.length && source[_i] != '\n') {
          _i++;
        }
      } else if (c == '(') {
        if (++depth > _maxDepth) {
          throw MutopiaFormatException(
            'Scheme nesting exceeds limit',
            offset: start,
          );
        }
      } else if (c == ')' && --depth == 0) {
        _add(_Kind.scheme, 'Scheme quoted expression', start);
        return;
      }
    }
    throw MutopiaFormatException(
      'unterminated Scheme quoted expression',
      offset: start,
    );
  }

  void _skipScheme() {
    final start = _i;
    _i += 2; // #(
    var depth = 1;
    while (_i < source.length && depth > 0) {
      final c = source[_i++];
      if (c == '"') {
        var closed = false;
        while (_i < source.length) {
          final quoted = source[_i++];
          if (quoted == '\\' && _i < source.length) {
            _i++;
            continue;
          }
          if (quoted == '"') {
            closed = true;
            break;
          }
        }
        if (!closed) {
          throw MutopiaFormatException(
            'unterminated Scheme string',
            offset: start,
          );
        }
      } else if (c == ';') {
        while (_i < source.length && source[_i] != '\n') {
          _i++;
        }
      } else if (c == '(') {
        if (++depth > _maxDepth) {
          throw MutopiaFormatException(
            'Scheme nesting exceeds limit',
            offset: start,
          );
        }
      } else if (c == ')') {
        depth--;
      }
    }
    if (depth != 0) {
      throw MutopiaFormatException(
        'unterminated Scheme expression',
        offset: start,
      );
    }
    _add(_Kind.scheme, 'Scheme expression', start);
  }
}
