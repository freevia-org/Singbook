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
    final token = _geniusToken();
    final transport = ProviderTransport(
      client: Platform.isWindows ? DesktopMaintenanceClient() : null,
    );
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

String _geniusToken() {
  var token =
      Platform.environment['GENIUS_ACCESS_TOKEN'] ??
      const String.fromEnvironment('GENIUS_ACCESS_TOKEN');
  final local = File('config/local.defines.json');
  if (token.isEmpty && local.existsSync()) {
    try {
      final decoded = jsonDecode(local.readAsStringSync());
      if (decoded is Map && decoded['GENIUS_ACCESS_TOKEN'] is String) {
        token = decoded['GENIUS_ACCESS_TOKEN'] as String;
      }
    } catch (_) {
      // A missing/invalid ignored local file is the same as absent credentials.
    }
  }
  return token;
}

/// Desktop-only smoke transport. Secret headers travel in a private temp file,
/// never in curl's process arguments. TLS verification remains enabled.
class DesktopMaintenanceClient extends http.BaseClient {
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
    Directory? directory;
    String? secretFile;
    if (secret.isNotEmpty) {
      directory = Directory.systemTemp.createTempSync('singbook-maint-');
      secretFile = '${directory.path}${Platform.pathSeparator}headers.txt';
      File(secretFile).writeAsStringSync('${secret.join('\n')}\n');
    }
    try {
      return await _send(request, bytes, secretFile);
    } finally {
      directory?.deleteSync(recursive: true);
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
      '15',
      '--request',
      request.method,
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
    return http.StreamedResponse(
      Stream.value(output.sublist(0, split)),
      status,
      request: request,
    );
  }
}
