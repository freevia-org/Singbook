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

import 'src/maintenance_credentials.dart';
import 'src/maintenance_http_diagnostics.dart';

Future<void> main(List<String> args) async {
  String catalogPath = 'config/source-catalog.json';
  String? reportPath;
  var offline = false;
  String? onlySource;
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
        default:
          throw FormatException('Unknown argument ${args[i]}');
      }
    }
    final text = await File(catalogPath).readAsString();
    final catalog = SourceCatalog.parse(text);
    final token = maintenanceGeniusToken();
    final diagnostics = MaintenanceHttpDiagnosticsClient(
      Platform.isWindows ? DesktopMaintenanceClient() : http.Client(),
    );
    final transport = ProviderTransport(client: diagnostics);
    try {
      final providers = [
        ...createCoreProviders(transport: transport, geniusToken: token),
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
      report['httpDiagnostics'] = diagnostics.report;
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
  DesktopMaintenanceClient({
    this.curlExecutable = 'curl.exe',
    Future<Process> Function(String executable, List<String> arguments)?
    processStarter,
    this.maxResponseBytes = _maxResponseBytes,
  }) : _processStarter = processStarter ?? Process.start {
    if (maxResponseBytes < 0 || maxResponseBytes > _maxResponseBytes) {
      throw ArgumentError.value(maxResponseBytes, 'maxResponseBytes');
    }
  }

  final String curlExecutable;
  final Future<Process> Function(String executable, List<String> arguments)
  _processStarter;
  final int maxResponseBytes;
  static const _maxResponseBytes = 16 * 1024 * 1024;
  static const _maxHeaderBytes = 1024 * 1024;
  static const _statusSuffixBytes = 4; // newline plus three status digits
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
    final process = await _processStarter(curlExecutable, [
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
    var aborted = false;
    var retired = false;
    var exited = false;
    var killRequested = false;
    void stopOwnedProcess() {
      if (retired || exited || killRequested) return;
      killRequested = true;
      process.kill();
    }

    final abortTrigger = request is http.Abortable
        ? request.abortTrigger
        : null;
    abortTrigger?.then((_) {
      if (retired) return;
      aborted = true;
      stopOwnedProcess();
    }, onError: (Object _) {});
    final exitCodeFuture = process.exitCode;
    final exitObserved = exitCodeFuture.then<void>(
      (_) {
        exited = true;
      },
      onError: (Object _) {
        exited = true;
      },
    );
    final stderrDrained = process.stderr.drain<void>();
    final stderrObserved = stderrDrained.then<void>(
      (_) {},
      onError: (Object _) {
        stopOwnedProcess();
      },
    );
    final output = <int>[];
    var oversized = false;
    final stdoutDrained = () async {
      await for (final chunk in process.stdout) {
        if (oversized) continue;
        final limit = maxResponseBytes + _statusSuffixBytes;
        if (chunk.length > limit - output.length) {
          oversized = true;
          output.clear();
          stopOwnedProcess();
          continue;
        }
        output.addAll(chunk);
      }
    }();
    final stdoutObserved = stdoutDrained.then<void>(
      (_) {},
      onError: (Object _) {
        stopOwnedProcess();
      },
    );
    try {
      if (bytes.isNotEmpty) process.stdin.add(bytes);
      await process.stdin.close();
      await stdoutDrained;
      final exitCode = await exitCodeFuture;
      await stderrDrained;
      retired = true;
      if (oversized) {
        throw const ProviderException('invalid_response', 'Response too large');
      }
      if (aborted || exitCode != 0) {
        throw http.ClientException(
          'Desktop maintenance HTTP failed',
          request.url,
        );
      }
    } catch (error) {
      // Finish draining the owned child before the caller removes its private
      // temporary directory. Never include curl stderr or header content in
      // an exception.
      stopOwnedProcess();
      await Future.wait<void>([exitObserved, stdoutObserved, stderrObserved]);
      if (error is ProviderException || error is http.ClientException) {
        rethrow;
      }
      throw http.ClientException(
        'Desktop maintenance HTTP failed',
        request.url,
      );
    }
    final split = output.lastIndexOf(10);
    if (split < 0 || output.length - split - 1 != 3) {
      throw const ProviderException('invalid_response', 'Invalid HTTP status');
    }
    final status = int.parse(utf8.decode(output.sublist(split + 1)));
    final headerFile = File(responseHeaders);
    if (!headerFile.existsSync() || headerFile.lengthSync() > _maxHeaderBytes) {
      throw const ProviderException(
        'invalid_response',
        'Response headers too large',
      );
    }
    final headers = parseDesktopResponseHeaders(
      headerFile.readAsStringSync(encoding: latin1),
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
