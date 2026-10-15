import 'package:html/dom.dart' show Document, Node;
import 'package:html/parser.dart' as html;
import 'transport.dart';

/// True when [root] nests deeper than any real markup. Recursive DOM helpers
/// (`clone`, `.text`) overflow the stack on such trees, so callers reject them
/// first. The walk itself is iterative.
bool htmlTooDeep(Node root, [int limit = 500]) {
  final stack = <(Node, int)>[(root, 0)];
  while (stack.isNotEmpty) {
    final (node, depth) = stack.removeLast();
    if (depth > limit) return true;
    for (final child in node.nodes) {
      stack.add((child, depth + 1));
    }
  }
  return false;
}

/// Shared hardening for everything a remote provider can hand us.

/// Parses HTML and rejects documents nested deeper than any real page: the
/// parser is iterative, but selector evaluation, `clone` and `.text` are
/// recursive and overflow the stack on such input.
Document parseHtml(String source) {
  final document = html.parse(source);
  if (htmlTooDeep(document)) throw const ProviderException('extraction_failed');
  return document;
}

/// Validates a user/provider search phrase before it is sent anywhere.
String queryText(String query) {
  final q = query.trim();
  if (q.isEmpty || q.length > 200) {
    throw const ProviderException('invalid_query');
  }
  return q;
}

final _hostLabel = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');
const _privateSuffixes = [
  '.local',
  '.localhost',
  '.internal',
  '.localdomain',
  '.lan',
  '.home',
  '.corp',
  '.intranet',
];

/// A host that could plausibly be a public web server: DNS labels only (no IP
/// literals, no single-label or local-network names).
bool isPublicHost(String host) {
  final h = host.toLowerCase();
  if (h.isEmpty || h.length > 253 || h == 'localhost') return false;
  if (_privateSuffixes.any(h.endsWith)) return false;
  final labels = h.split('.');
  if (labels.length < 2 || !labels.every(_hostLabel.hasMatch)) return false;
  // An all-numeric final label means an IPv4 literal (or a bogus name).
  return !RegExp(r'^\d+$').hasMatch(labels.last);
}

bool _hostMatches(String host, Set<String> suffixes) => suffixes.any(
  (s) => host == s || host.endsWith('.$s'),
);

/// Returns a normalized https URL, or null when [value] is unsafe to store or
/// show: not https, userinfo, non-443 port, control characters, an IP/local
/// host, or (when [hostSuffixes] is given) a host outside the allowlist.
/// Callers drop invalid values instead of storing them.
String? safeHttpsUrl(Object? value, {Set<String>? hostSuffixes}) {
  if (value is! String || value.isEmpty || value.length > 2048) return null;
  if (RegExp(r'[\x00-\x20\x7f]').hasMatch(value)) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443) ||
      !isPublicHost(uri.host)) {
    return null;
  }
  if (hostSuffixes != null && !_hostMatches(uri.host, hostSuffixes)) {
    return null;
  }
  return uri.toString();
}

/// Artwork is fetched automatically by the UI, so it is restricted to hosts
/// known to serve that provider's images.
const geniusImageHosts = {'genius.com', 'rapgenius.com'};
const deezerImageHosts = {'dzcdn.net', 'deezer.com'};
const youtubeImageHosts = {
  'ytimg.com',
  'googleusercontent.com',
  'ggpht.com',
  'youtube.com',
};

final _verseDirective = RegExp(r'^\s*\{\s*x_verse', caseSensitive: false);

/// Removes every Singbook extension directive (`{x_verse...}` /
/// `{x_verse_data...}`) from text that came from a remote provider, so a source
/// cannot inject provenance, rights or timing payloads. User-selected local
/// imports are not passed through this function.
String stripVerseDirectives(String text) {
  if (!text.contains(RegExp(r'x_verse', caseSensitive: false))) return text;
  return text
      .split(RegExp(r'\r\n|\n|\r'))
      .where((line) => !_verseDirective.hasMatch(line))
      .join('\n');
}

/// Cloudflare / consent / bot-wall pages are often served as HTTP 200. Returns a
/// short reason, or null when the page does not look like an interstitial.
String? blockedPageReason(String source) {
  final head = source.length > 200000 ? source.substring(0, 200000) : source;
  final lower = head.toLowerCase();
  if (lower.contains('consent.youtube.com') ||
      lower.contains('consent.google.com') ||
      lower.contains('before you continue to')) {
    return 'consent_required';
  }
  if (lower.contains('cf-browser-verification') ||
      lower.contains('challenge-platform') ||
      lower.contains('cf-challenge') ||
      lower.contains('attention required! | cloudflare') ||
      RegExp(r'<title>\s*just a moment').hasMatch(lower)) {
    return 'cloudflare';
  }
  if (lower.contains('g-recaptcha') ||
      lower.contains('h-captcha') ||
      lower.contains('px-captcha') ||
      (lower.contains('/cdn-cgi/') && lower.contains('captcha')) ||
      RegExp(r'<title>[^<]*(captcha|are you a (robot|human)|access denied)')
          .hasMatch(lower)) {
    return 'bot_wall';
  }
  return null;
}

/// Call before reporting `extraction_failed`: a blocked page is a different
/// failure from a changed page layout.
void throwIfBlocked(String source) {
  final reason = blockedPageReason(source);
  if (reason != null) throw ProviderException('blocked', reason);
}
