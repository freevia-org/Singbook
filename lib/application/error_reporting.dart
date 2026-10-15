import 'package:flutter/foundation.dart';

final _secretPatterns = <RegExp>[
  RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
  RegExp(r'ya29\.[A-Za-z0-9._-]+'),
  RegExp(r'AIza[0-9A-Za-z_-]{20,}'),
  RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]*'),
  RegExp(
    r'''\b(?:access_token|refresh_token|id_token|token|api[_-]?key|key|secret|password|client_secret|code)(["']?\s*[=:]\s*["']?)[^&\s"',}]+''',
    caseSensitive: false,
  ),
  RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+'),
];

/// Removes bearer tokens, OAuth/API credentials and e-mail addresses from text
/// destined for logs. Best effort: our own code never puts them in exceptions;
/// this is the safety net for third-party messages.
String redactSecrets(String text) {
  var result = text;
  for (final pattern in _secretPatterns) {
    result = result.replaceAllMapped(pattern, (match) {
      final separator = match.groupCount > 0 ? match.group(1) : null;
      final head = match.group(0)!;
      if (separator != null) {
        final name = head.substring(0, head.indexOf(separator));
        return '$name$separator[redacted]';
      }
      return '[redacted]';
    });
  }
  return result;
}

String describeUncaught(
  String source,
  Object error,
  StackTrace? stack, {
  int maxStackLines = 8,
}) {
  final message = redactSecrets(error.toString());
  final clipped = message.length > 500
      ? '${message.substring(0, 500)}...'
      : message;
  final lines = stack == null
      ? const <String>[]
      : stack.toString().split('\n').take(maxStackLines);
  return '[$source] ${error.runtimeType}: $clipped'
      '${lines.isEmpty ? '' : '\n${redactSecrets(lines.join('\n'))}'}';
}

/// Installs minimal global handlers so an uncaught error is logged once, with
/// secrets removed, instead of terminating silently or printing raw payloads.
void installErrorHandlers({void Function(String message)? sink}) {
  final write = sink ?? (message) => debugPrint(message);
  FlutterError.onError = (details) {
    write(describeUncaught('flutter', details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    write(describeUncaught('platform', error, stack));
    return true;
  };
}
