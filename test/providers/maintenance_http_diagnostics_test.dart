import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../../tool/src/maintenance_http_diagnostics.dart';

void main() {
  test(
    'aggregates safe response facts and forwards requests and streams',
    () async {
      final inner = _StreamingFakeClient();
      final client = MaintenanceHttpDiagnosticsClient(inner);
      final abort = Completer<void>();
      final get = http.AbortableRequest(
        'GET',
        Uri.https('lyrics.example', '/limited', {'token': 'secret'}),
        abortTrigger: abort.future,
      );
      get.headers['Authorization'] = 'secret-header';
      final limited = await client.send(get);
      expect(inner.requests.single, same(get));
      expect(limited, same(inner.responses.single));
      expect(inner.responses.single.request, same(get));
      expect(limited.statusCode, 429);
      expect(inner.abortTrigger, same(abort.future));
      expect(inner.bodyRead, isFalse);
      expect(await utf8.decoder.bind(limited.stream).join(), 'limited');
      expect(inner.bodyRead, isTrue);
      expect(limited.isRedirect, isFalse);

      final busy = await client.send(
        http.Request(
          'POST',
          Uri.https('lyrics.example', '/busy', {'private': 'yes'}),
        )..body = 'sensitive body',
      );
      await client.send(
        http.Request('GET', Uri.https('lyrics.example', '/ok')),
      );
      expect(busy.statusCode, 503);
      expect(client.report, {
        'networkFailures': 0,
        'hosts': {
          'lyrics.example': {
            'requests': 3,
            'statuses': {'200': 1, '429': 1, '503': 1},
            'retryAfterSeconds': {'12': 1},
            'databaseLag': {'47': 1},
          },
        },
      });
      final snapshot = client.report;
      (snapshot['hosts'] as Map<String, dynamic>).clear();
      expect(
        (client.report['hosts'] as Map<String, dynamic>).containsKey(
          'lyrics.example',
        ),
        isTrue,
      );
      final serialized = jsonEncode(client.report);
      expect(serialized, isNot(contains('secret')));
      expect(serialized, isNot(contains('private')));
      expect(serialized, isNot(contains('limited')));
      expect(serialized, isNot(contains('sensitive')));
      client.close();
      expect(inner.closed, isTrue);
    },
  );

  test(
    'counts thrown transport failures without recording exception data',
    () async {
      final client = MaintenanceHttpDiagnosticsClient(_ThrowingFakeClient());
      await expectLater(
        client.send(
          http.Request(
            'GET',
            Uri.https('failure.example', '/', {'q': 'secret'}),
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(client.report, {
        'networkFailures': 1,
        'hosts': {
          'failure.example': {
            'requests': 1,
            'statuses': <String, int>{},
            'retryAfterSeconds': <String, int>{},
            'databaseLag': <String, int>{},
          },
        },
      });
      expect(jsonEncode(client.report), isNot(contains('secret')));
      client.close();
    },
  );
}

class _StreamingFakeClient extends http.BaseClient {
  final requests = <http.BaseRequest>[];
  final responses = <http.StreamedResponse>[];
  Future<void>? abortTrigger;
  bool bodyRead = false;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (request is http.Abortable) abortTrigger = request.abortTrigger;
    final status = switch (request.url.path) {
      '/limited' => 429,
      '/busy' => 503,
      _ => 200,
    };
    final response = http.StreamedResponse(
      Stream<List<int>>.multi((controller) {
        bodyRead = true;
        controller.add(
          utf8.encode(switch (request.url.path) {
            '/limited' => 'limited',
            '/busy' => 'busy',
            _ => 'ok',
          }),
        );
        controller.close();
      }),
      status,
      request: request,
      headers: switch (request.url.path) {
        '/limited' => {'retry-after': '12'},
        '/busy' => {'x-database-lag': '47'},
        _ => const <String, String>{},
      },
    );
    responses.add(response);
    return response;
  }

  @override
  void close() => closed = true;
}

class _ThrowingFakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      throw StateError('secret query and header');

  @override
  void close() {}
}
