import 'dart:async';

import 'package:http/http.dart' as http;

import '../providers/transport.dart';

/// Resolve Google's regional chooser without borrowing any browser cookies.
/// The provided client, when supplied for testing, is also owned and closed.
Future<Uri> resolveYoutubeMusicConsentEntry({
  http.Client? client,
  Duration timeout = const Duration(seconds: 8),
}) async {
  // A fresh standard Dart IO client has no shared native cookie store or
  // credential cache. In particular, do not use URLSession's shared store.
  final probe = client ?? http.Client();
  final abort = Completer<void>();
  try {
    final request =
        http.AbortableRequest(
            'GET',
            Uri.parse('https://music.youtube.com/'),
            abortTrigger: abort.future,
          )
          ..followRedirects = false
          ..headers['User-Agent'] = providerUserAgent;
    final response = await probe.send(request).timeout(timeout);
    // Only the redirect metadata is needed. Do not download or inspect HTML
    // or copy response cookies into the browser or the adapter session.
    await response.stream.listen((_) {}).cancel();
    if (!{301, 302, 303, 307, 308}.contains(response.statusCode)) {
      throw const ProviderException('blocked', 'consent_entry_unavailable');
    }
    return _chooser(response.headers['location']);
  } on TimeoutException {
    throw const ProviderException('timeout');
  } finally {
    if (!abort.isCompleted) abort.complete();
    probe.close();
  }
}

Uri _chooser(String? location) {
  Never invalid() => throw const ProviderException('invalid_response');
  if (location == null || location.length > 4096) invalid();
  final url = Uri.tryParse(location);
  if (url == null ||
      url.scheme != 'https' ||
      url.host != 'consent.youtube.com' ||
      url.userInfo.isNotEmpty ||
      url.hasPort ||
      url.path != '/m' ||
      url.hasFragment) {
    invalid();
  }
  final query = url.queryParametersAll;
  const allowed = {'continue', 'gl', 'hl', 'm', 'pc', 'cm', 'src'};
  if (query.keys.any((key) => !allowed.contains(key)) ||
      query.values.any((values) => values.length != 1)) {
    invalid();
  }
  final region = url.queryParameters['gl'] ?? '';
  final language = url.queryParameters['hl'] ?? '';
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(region) ||
      language.length > 32 ||
      !RegExp(r'^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$').hasMatch(language) ||
      url.queryParameters['m'] != '0' ||
      url.queryParameters['pc'] != 'ytm' ||
      url.queryParameters['cm'] != '2' ||
      url.queryParameters['src'] != '1') {
    invalid();
  }
  final target = Uri.tryParse(url.queryParameters['continue'] ?? '');
  if (target == null ||
      target.scheme != 'https' ||
      target.host != 'music.youtube.com' ||
      target.userInfo.isNotEmpty ||
      target.hasPort ||
      !{'', '/'}.contains(target.path) ||
      target.hasFragment ||
      target.queryParametersAll.entries.any(
        (entry) =>
            entry.key != 'cbrd' ||
            entry.value.length != 1 ||
            entry.value.single != '1',
      )) {
    invalid();
  }
  return Uri.https('consent.youtube.com', '/m', {
    'continue': 'https://music.youtube.com/?cbrd=1',
    'gl': region,
    'm': '0',
    'pc': 'ytm',
    'cm': '2',
    'hl': language,
    'src': '1',
  });
}
