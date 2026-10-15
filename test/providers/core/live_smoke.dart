// Opt-in: dart run test/providers/core/live_smoke.dart
// Prints only identity/status/counts, never full lyrics or credentials.
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/provider.dart';

Future<void> main(List<String> args) async {
  // Prefer the environment (or --dart-define); the token is never put on a
  // command line.
  var token =
      Platform.environment['GENIUS_ACCESS_TOKEN'] ??
      const String.fromEnvironment('GENIUS_ACCESS_TOKEN');
  final local = File('config/local.defines.json');
  if (token.isEmpty && local.existsSync()) {
    token =
        jsonDecode(local.readAsStringSync())['GENIUS_ACCESS_TOKEN']
            as String? ??
        '';
  }
  // curl is only a desktop smoke-test transport. The mobile app uses native
  // Cronet/NSURLSession, never a subprocess or backend.
  final transport = ProviderTransport(
    client: Platform.isWindows ? DesktopSmokeClient() : null,
  );
  final providers = createCoreProviders(
    transport: transport,
    geniusToken: token,
  );
  final service = SourceDiscoveryService(providers);
  final query = args.isEmpty ? 'Lonely Stranger Eric Clapton' : args.join(' ');
  try {
    final candidates = await service.search(query);
    stdout.writeln(
      jsonEncode({
        'search': 'genius',
        'count': candidates.length,
        'titles': candidates.take(3).map((s) => s.title).toList(),
      }),
    );
    if (candidates.isEmpty) return;
    final selection = candidates.first;
    final results = await service.discover(
      selection,
      onProgress: (c) {
        if (c.state != 'pending') {
          stdout.writeln(
            jsonEncode({
              'provider': c.providerId,
              'state': c.state,
              'code': c.code,
              if (c.result != null) 'match': c.result!.matchKind.name,
              if (c.result != null) 'chords': c.result!.hasChords,
              if (c.result != null) 'characters': c.result!.body.length,
              if (c.result != null)
                'timing': c.result!.timingTracks
                    .map(
                      (t) => {
                        'format': t.format,
                        'cues': t.cues.length,
                        'rawBytes': t.raw?.length,
                      },
                    )
                    .toList(),
            }),
          );
        }
      },
    );
    stdout.writeln(
      jsonEncode({
        'accepted': results
            .where((r) => r.matchKind != MatchKind.rejected)
            .length,
      }),
    );
  } catch (e) {
    stdout.writeln(jsonEncode({'error': e.toString()}));
    exitCode = 1;
  } finally {
    await transport.close();
  }
}

class DesktopSmokeClient extends http.BaseClient {
  static const _secret = {'authorization', 'cookie', 'proxy-authorization'};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    // Credentials must not appear in the process command line (visible to other
    // local processes). They go to a private temp file read by `--header @file`.
    final secretHeaders = [
      for (final h in request.headers.entries)
        if (_secret.contains(h.key.toLowerCase())) '${h.key}: ${h.value}',
    ];
    Directory? secretDir;
    String? secretFile;
    if (secretHeaders.isNotEmpty) {
      secretDir = Directory.systemTemp.createTempSync('singbook-smoke-');
      secretFile = '${secretDir.path}${Platform.pathSeparator}headers.txt';
      File(secretFile).writeAsStringSync('${secretHeaders.join('\n')}\n');
    }
    try {
      return await _send(request, bytes, secretFile);
    } finally {
      secretDir?.deleteSync(recursive: true);
    }
  }

  Future<http.StreamedResponse> _send(
    http.BaseRequest request,
    List<int> bytes,
    String? secretFile,
  ) async {
    final process = await Process.start('curl.exe', [
      '--silent',
      '--show-error',
      '--max-time',
      '12',
      '--request',
      request.method,
      '--write-out',
      '\n%{http_code}',
      request.url.toString(),
      for (final h in request.headers.entries)
        if (!_secret.contains(h.key.toLowerCase())) ...[
          '--header',
          '${h.key}: ${h.value}',
        ],
      if (secretFile != null) ...['--header', '@$secretFile'],
      if (bytes.isNotEmpty) ...['--data-binary', '@-'],
    ]);
    if (request is http.Abortable && request.abortTrigger != null) {
      request.abortTrigger!.then((_) => process.kill());
    }
    if (bytes.isNotEmpty) process.stdin.add(bytes);
    await process.stdin.close();
    final errors = process.stderr.transform(utf8.decoder).join();
    final output = await process.stdout.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    if (await process.exitCode != 0) {
      throw http.ClientException(
        'Desktop smoke HTTP failed: ${await errors}',
        request.url,
      );
    }
    await errors;
    final split = output.lastIndexOf(10),
        status = int.parse(utf8.decode(output.sublist(split + 1)));
    return http.StreamedResponse(
      Stream.value(output.sublist(0, split)),
      status,
      request: request,
    );
  }
}
