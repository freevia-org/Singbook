/// A public source address suitable for an operation trace or information sheet.
/// Unknown providers retain their origin only: their paths can contain private
/// keys. Original provenance remains in the source document, outside diagnostics.
String? safeDiagnosticUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.host.isEmpty) {
    return null;
  }
  final host = uri.host.toLowerCase();
  String? publicPath;
  Map<String, String>? publicQuery;
  if (!uri.hasPort) {
    if ({
      'youtube.com',
      'www.youtube.com',
      'music.youtube.com',
    }.contains(host)) {
      final video = uri.queryParameters['v'];
      if (uri.path == '/watch' &&
          video != null &&
          RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(video)) {
        publicPath = '/watch';
        publicQuery = {'v': video};
      }
    } else {
      final pattern = switch (host) {
        'genius.com' || 'www.genius.com' => r'^/[a-z0-9-]+-(lyrics|annotated)$',
        'tabs.ultimate-guitar.com' => r'^/tab/[a-z0-9-]+/[a-z0-9-]+-\d+$',
        'songsterr.com' ||
        'www.songsterr.com' => r'^/a/wsa/[a-z0-9-]+-s\d+(t\d+)?$',
        'musicbrainz.org' || 'www.musicbrainz.org' =>
          r'^/(recording|work|release|artist)/[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$',
        'youtu.be' => r'^/[A-Za-z0-9_-]{11}$',
        _ => null,
      };
      if (pattern != null &&
          RegExp(pattern, caseSensitive: false).hasMatch(uri.path)) {
        publicPath = uri.path;
      }
    }
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: publicPath,
    queryParameters: publicQuery,
  ).toString();
}
