/// Short-lived, anonymous consent state supplied by the native browser flow.
///
/// This object deliberately accepts only the two consent cookies and keeps
/// them in memory. It does not represent a Google account session.
class YoutubeMusicSession {
  static const int _maxValueLength = 4096;
  static const int _maxHeaderLength = 8192;
  static const Set<String> _allowed = {'SOCS', 'CONSENT'};

  Map<String, String> _cookies = const {};
  int _revision = 0;

  String? get cookieHeader {
    if (_cookies.isEmpty) return null;
    return _allowed
        .where(_cookies.containsKey)
        .map((name) => '$name=${_cookies[name]}')
        .join('; ');
  }

  int get revision => _revision;
  bool get hasConsent => _cookies.isNotEmpty;

  void setConsentCookies(Map<String, String> cookies) {
    final filtered = <String, String>{};
    for (final name in _allowed) {
      final value = cookies[name];
      if (value == null ||
          value.isEmpty ||
          value.length > _maxValueLength ||
          !RegExp(
            r'^[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]+$',
          ).hasMatch(value)) {
        continue;
      }
      filtered[name] = value;
    }
    final header = filtered.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    if (header.length > _maxHeaderLength) filtered.clear();
    if (_same(_cookies, filtered)) return;
    _cookies = Map.unmodifiable(filtered);
    _revision++;
  }

  void clear() {
    if (_cookies.isEmpty) return;
    _cookies = const {};
    _revision++;
  }

  bool _same(Map<String, String> a, Map<String, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
}
