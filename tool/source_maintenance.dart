import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:singbook/domain/models.dart';
import 'package:singbook/providers/configurable_provider.dart';
import 'package:singbook/providers/core/core_providers.dart';
import 'package:singbook/providers/extra/extra_providers.dart';
import 'package:singbook/providers/provider.dart';
import 'package:singbook/providers/source_catalog.dart';
import 'package:singbook/providers/source_maintenance.dart';
import 'package:singbook/providers/youtube_music_session.dart';

import 'src/local_youtube_session.dart';
import 'src/maintenance_credentials.dart';

Future<void> main(List<String> args) async {
  String catalogPath = 'config/source-catalog.json';
  String? reportPath;
  var offline = false;
  String? onlySource;
  var youtubeConsent = false, youtubeClear = false, youtubeStatus = false;
  String? youtubeBrowser;
  try {
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--catalog':
          catalogPath = _value(args, ++i, '--catalog');
          break;
        case '--report':
          reportPath = _value(args, ++i, '--report');
          break;
        case '--source':
          onlySource = _value(args, ++i, '--source');
          break;
        case '--offline':
          offline = true;
          break;
        case '--youtube-consent':
          youtubeConsent = true;
          break;
        case '--youtube-clear-consent':
          youtubeClear = true;
          break;
        case '--youtube-session-status':
          youtubeStatus = true;
          break;
        case '--youtube-browser':
          youtubeBrowser = _value(args, ++i, '--youtube-browser');
          break;
        default:
          throw FormatException('Unknown argument ${args[i]}');
      }
    }
    final actions = [
      youtubeConsent,
      youtubeClear,
      youtubeStatus,
    ].where((v) => v).length;
    if (actions > 1 ||
        (offline && actions > 0) ||
        (actions > 0 &&
            onlySource != null &&
            onlySource != 'youtubemusic')) {
      throw const FormatException(
        'Use one YouTube session action, without --offline or another source.',
      );
    }
    final localSession = LocalYoutubeSession(browserExecutable: youtubeBrowser);
    if (youtubeClear) {
      await localSession.clear();
      stdout.writeln(
        'YouTube Music consent cleared for the local maintenance checker.',
      );
      return;
    }
    var youtubeSession = YoutubeMusicSession();
    String? youtubeSessionError;
    if (youtubeConsent) {
      youtubeSession = await localSession.consent(
        entryClient: DesktopMaintenanceClient(
          curlExecutable: Platform.isWindows ? 'curl.exe' : 'curl',
        ),
        onStatus: stderr.writeln,
      );
    } else if (!offline &&
        (onlySource == null || onlySource == 'youtubemusic' || youtubeStatus)) {
      try {
        youtubeSession = await localSession.restore();
      } on LocalYoutubeSessionException catch (error) {
        youtubeSessionError = error.code;
        stderr.writeln(
          'Local YouTube Music session unavailable: ${error.code}. Other probes continue.',
        );
      }
    }
    if (youtubeStatus) {
      stdout.writeln(
        jsonEncode({
          'hasConsent': youtubeSession.hasConsent,
          'error': ?youtubeSessionError,
        }),
      );
      if (youtubeSessionError != null) exitCode = 2;
      return;
    }
    final text = await File(catalogPath).readAsString();
    final catalog = SourceCatalog.parse(text);
    final token = maintenanceGeniusToken();
    final transport = ProviderTransport(
      client: Platform.isWindows ? DesktopMaintenanceClient() : null,
    );
    try {
      final providers = [
        ...createCoreProviders(
          transport: transport,
          geniusToken: token,
          youtubeMusicSession: youtubeSession,
        ),
        ...createExtraProviders(transport: transport),
      ];
      for (final entry in catalog.sources) {
        if (entry.adapter != 'builtin') {
          ConfigurableProvider.validateExtraction(entry);
        }
      }
      final runtime = SourceCatalogRuntime(
        builtins: providers,
        createProvider: (entry) => ConfigurableProvider(entry, transport),
      )..apply(catalog);
      if (onlySource != null &&
          !catalog.sources.any((entry) => entry.id == onlySource)) {
        throw FormatException('Unknown source id');
      }
      final report =
          await SourceMaintenanceHarness(
            providers: [...providers, ...runtime.providers],
          ).run(
            catalog,
            offline: offline,
            sourceIds: onlySource == null ? null : {onlySource},
          );
      if (!offline && (onlySource == null || onlySource == 'youtubemusic')) {
        report['localYoutubeSession'] = {
          'hasConsent': youtubeSession.hasConsent,
          'error': ?youtubeSessionError,
        };
        if (!youtubeSession.hasConsent) {
          stderr.writeln(
            'For YouTube Music consent, run with --source youtubemusic --youtube-consent.',
          );
        }
      }
      final json = const JsonEncoder.withIndent('  ').convert(report);
      if (reportPath == null) {
        stdout.writeln(json);
      } else {
        final reportFile = File(reportPath);
        await reportFile.parent.create(recursive: true);
        await reportFile.writeAsString('$json\n');
      }
      final statuses = (report['sources'] as List).cast<JsonMap>().map(
        (source) => source['status'] as String,
      );
      if (statuses.any((status) {
        if (offline) return status == 'coverage_gap';
        return status != 'healthy' &&
            status != 'disabled' &&
            status != 'retired' &&
            status != 'import_only';
      })) {
        exitCode = 1;
      }
    } finally {
      await transport.close();
    }
  } on LocalYoutubeSessionException catch (error) {
    stderr.writeln('Local YouTube Music session failed: ${error.code}.');
    exitCode = 2;
  } on FormatException catch (error) {
    stderr.writeln(
      'Invalid source maintenance configuration: ${error.message}',
    );
    exitCode = 2;
  } on FileSystemException catch (error) {
    stderr.writeln(
      'Cannot read or write maintenance file: ${error.osError?.errorCode ?? 'file_error'}',
    );
    exitCode = 2;
  } catch (_) {
    stderr.writeln('Source maintenance failed before producing a report.');
    exitCode = 2;
  }
}

String _value(List<String> args, int index, String flag) {
  if (index >= args.length || args[index].startsWith('--')) {
    throw FormatException('$flag requires a value');
  }
  return args[index];
}

/// Desktop-only smoke transport. Secret headers travel in a private temp file,
/// never in curl's process arguments. TLS verification remains enabled.
class DesktopMaintenanceClient extends http.BaseClient {
  DesktopMaintenanceClient({this.curlExecutable = 'curl.exe'});

  final String curlExecutable;
  static const _secretHeaders = {
    'authorization',
    'cookie',
    'proxy-authorization',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final secret = [
      for (final header in request.headers.entries)
        if (_secretHeaders.contains(header.key.toLowerCase()))
          '${header.key}: ${header.value}',
    ];
    final directory = Directory.systemTemp.createTempSync('singbook-maint-');
    final responseHeaders =
        '${directory.path}${Platform.pathSeparator}response.txt';
    String? secretFile;
    try {
      if (secret.isNotEmpty) {
        secretFile = '${directory.path}${Platform.pathSeparator}headers.txt';
        File(secretFile).writeAsStringSync('${secret.join('\n')}\n');
      }
      return await _send(request, bytes, secretFile, responseHeaders);
    } finally {
      directory.deleteSync(recursive: true);
    }
  }

  Future<http.StreamedResponse> _send(
    http.BaseRequest request,
    List<int> bytes,
    String? secretFile,
    String responseHeaders,
  ) async {
    final process = await Process.start(curlExecutable, [
      '--silent',
      '--show-error',
      '--max-time',
      '15',
      '--request',
      request.method,
      '--dump-header',
      responseHeaders,
      '--write-out',
      '\n%{http_code}',
      request.url.toString(),
      for (final header in request.headers.entries)
        if (!_secretHeaders.contains(header.key.toLowerCase())) ...[
          '--header',
          '${header.key}: ${header.value}',
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
      await errors;
      throw http.ClientException(
        'Desktop maintenance HTTP failed',
        request.url,
      );
    }
    await errors;
    final split = output.lastIndexOf(10);
    final status = int.parse(utf8.decode(output.sublist(split + 1)));
    final headers = parseDesktopResponseHeaders(
      File(responseHeaders).readAsStringSync(encoding: latin1),
      status,
    );
    return http.StreamedResponse(
      Stream.value(output.sublist(0, split)),
      status,
      request: request,
      headers: headers,
    );
  }
}

/// Curl may write proxy CONNECT and interim 1xx blocks before the real reply.
/// Retain only the final matching response; never expose stale interim headers.
Map<String, String> parseDesktopResponseHeaders(String text, int status) {
  Map<String, String> headers = {};
  for (final block in text.split(RegExp(r'\r?\n\r?\n'))) {
    final lines = block.split(RegExp(r'\r?\n'));
    final match = RegExp(
      r'^HTTP/\S+\s+(\d{3})(?:\s|$)',
    ).firstMatch(lines.first);
    if (match == null) continue;
    headers = {};
    if (int.parse(match[1]!) != status) continue;
    for (final line in lines.skip(1)) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      final name = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      headers.update(
        name,
        (previous) => '$previous, $value',
        ifAbsent: () => value,
      );
    }
  }
  return headers;
}
