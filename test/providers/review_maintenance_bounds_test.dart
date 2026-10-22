import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:singbook/providers/provider.dart';
import '../../tool/source_maintenance.dart';

void main() {
  group('DesktopMaintenanceClient response bounds', () {
    test('accepts a body exactly at the configured limit', () async {
      final process = _FakeProcess([utf8.encode('hello\n200')]);
      final fixture = _Fixture(process);
      final response = await fixture
          .client(maxResponseBytes: 5)
          .send(http.Request('GET', Uri.https('example.test', '/')));

      expect(await response.stream.bytesToString(), 'hello');
      expect(response.statusCode, 200);
      expect(process.killCount, 0);
      expect(fixture.tempDirectory.existsSync(), isFalse);
    });

    test('ignores an abort that arrives after process retirement', () async {
      final abort = Completer<void>();
      final process = _FakeProcess([utf8.encode('ok\n200')]);
      final fixture = _Fixture(process);
      final request = http.AbortableRequest(
        'GET',
        Uri.https('example.test', '/'),
        abortTrigger: abort.future,
      );
      final response = await fixture.client(maxResponseBytes: 16).send(request);
      abort.complete();
      await Future<void>.delayed(Duration.zero);

      expect(await response.stream.bytesToString(), 'ok');
      expect(process.killCount, 0);
      expect(fixture.tempDirectory.existsSync(), isFalse);
    });

    test(
      'does not kill an exited process while its pipe EOF is pending',
      () async {
        final abort = Completer<void>();
        final process = _FakeProcess.openPipes();
        final fixture = _Fixture(process);
        final request = http.AbortableRequest(
          'GET',
          Uri.https('example.test', '/'),
          abortTrigger: abort.future,
        );
        final sending = fixture.client(maxResponseBytes: 16).send(request);
        await process.started.future;
        process.finishExit(0);
        await Future<void>.delayed(Duration.zero);
        abort.complete();
        await Future<void>.delayed(Duration.zero);
        expect(process.killCount, 0);
        await process.finishPipes();

        await expectLater(sending, throwsA(isA<http.ClientException>()));
        expect(process.killCount, 0);
        expect(process.exitSettled, isTrue);
        expect(process.stdoutSettled, isTrue);
        expect(process.stderrSettled, isTrue);
        expect(fixture.tempDirectory.existsSync(), isFalse);
      },
    );

    test(
      'kills curl when split output exceeds body limit plus suffix',
      () async {
        final process = _FakeProcess([
          utf8.encode('hello\n2'),
          utf8.encode('00'),
        ]);
        final fixture = _Fixture(process);

        await expectLater(
          fixture
              .client(maxResponseBytes: 4)
              .send(http.Request('GET', Uri.https('example.test', '/'))),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.code,
              'code',
              'invalid_response',
            ),
          ),
        );

        expect(process.killCount, 1);
        expect(process.stdoutSettled, isTrue);
        expect(process.stderrSettled, isTrue);
        expect(fixture.tempDirectory.existsSync(), isFalse);
      },
    );

    test('drains large stderr without retaining or exposing it', () async {
      final secretDiagnostic = 'private-curl-output-' * 65536;
      final process = _FakeProcess(
        [utf8.encode('failure')],
        stderrChunks: [utf8.encode(secretDiagnostic)],
        exitCode: 1,
      );
      final fixture = _Fixture(process);
      Object? thrown;
      try {
        await fixture
            .client(maxResponseBytes: 16)
            .send(http.Request('GET', Uri.https('example.test', '/')));
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isA<http.ClientException>());
      expect(thrown.toString(), isNot(contains('private-curl-output')));
      expect(process.stderrSettled, isTrue);
      expect(fixture.tempDirectory.existsSync(), isFalse);
    });

    test('does not kill an exited process for a stderr stream error', () async {
      final process = _FakeProcess.openPipes();
      final fixture = _Fixture(process);
      final sending = fixture
          .client(maxResponseBytes: 16)
          .send(http.Request('GET', Uri.https('example.test', '/')));
      await process.started.future;
      process.finishExit(0);
      await Future<void>.delayed(Duration.zero);
      process.failStderr(StateError('private stream detail'));
      await Future<void>.delayed(Duration.zero);
      await process.finishPipes();

      await expectLater(
        sending,
        throwsA(
          isA<Object>().having(
            (error) => error.toString(),
            'message',
            isNot(contains('private stream detail')),
          ),
        ),
      );

      expect(process.killCount, 0);
      expect(process.stdoutSettled, isTrue);
      expect(process.stderrSettled, isTrue);
      expect(process.exitSettled, isTrue);
      expect(fixture.tempDirectory.existsSync(), isFalse);
    });

    test('kills an active process promptly when stderr fails', () async {
      final process = _FakeProcess.openPipes();
      final fixture = _Fixture(process);
      final sending = fixture
          .client(maxResponseBytes: 16)
          .send(http.Request('GET', Uri.https('example.test', '/')));
      await process.started.future;
      process.failStderr(StateError('private stream detail'));

      await expectLater(sending, throwsA(isA<http.ClientException>()));
      expect(process.killCount, 1);
      expect(process.stdoutSettled, isTrue);
      expect(process.stderrSettled, isTrue);
      expect(process.exitSettled, isTrue);
      expect(fixture.tempDirectory.existsSync(), isFalse);
    });

    test(
      'abort kills the owned process and waits before temp cleanup',
      () async {
        final abort = Completer<void>();
        final process = _FakeProcess.blocking();
        final fixture = _Fixture(process);
        final request = http.AbortableRequest(
          'GET',
          Uri.https('example.test', '/'),
          abortTrigger: abort.future,
        );
        final sending = fixture.client(maxResponseBytes: 16).send(request);
        await process.started.future;
        abort.complete();

        await expectLater(sending, throwsA(isA<http.ClientException>()));
        expect(process.killCount, 1);
        expect(process.exitSettled, isTrue);
        expect(process.stdoutSettled, isTrue);
        expect(process.stderrSettled, isTrue);
        expect(fixture.tempDirectory.existsSync(), isFalse);
      },
    );

    test(
      'rejects an oversized response-header file before reading it',
      () async {
        final process = _FakeProcess([
          utf8.encode('ok\n200'),
        ], headerText: 'H' * (1024 * 1024 + 1));
        final fixture = _Fixture(process);

        await expectLater(
          fixture
              .client(maxResponseBytes: 16)
              .send(http.Request('GET', Uri.https('example.test', '/'))),
          throwsA(isA<ProviderException>()),
        );

        expect(fixture.tempDirectory.existsSync(), isFalse);
      },
    );
  });
}

class _Fixture {
  _Fixture(this.process);
  final _FakeProcess process;
  late Directory tempDirectory;

  DesktopMaintenanceClient client({required int maxResponseBytes}) =>
      DesktopMaintenanceClient(
        maxResponseBytes: maxResponseBytes,
        processStarter: (executable, arguments) async {
          final headerIndex = arguments.indexOf('--dump-header');
          final headerFile = File(arguments[headerIndex + 1]);
          tempDirectory = headerFile.parent;
          headerFile.writeAsStringSync(process.headerText);
          process.started.complete();
          return process;
        },
      );
}

class _FakeProcess implements Process {
  _FakeProcess(
    List<List<int>> stdoutChunks, {
    List<List<int>> stderrChunks = const [],
    this.headerText = 'HTTP/1.1 200 OK\r\nX-Test: yes\r\n\r\n',
    int exitCode = 0,
  }) : _stdout = StreamController<List<int>>(),
       _stderr = StreamController<List<int>>(),
       _exit = Completer<int>() {
    scheduleMicrotask(() async {
      for (final chunk in stdoutChunks) {
        _stdout.add(chunk);
      }
      await _stdout.close();
      for (final chunk in stderrChunks) {
        _stderr.add(chunk);
      }
      await _stderr.close();
      if (!_exit.isCompleted) _exit.complete(exitCode);
    });
  }

  _FakeProcess.blocking()
    : _stdout = StreamController<List<int>>(),
      _stderr = StreamController<List<int>>(),
      _exit = Completer<int>() {
    _onKill = () async {
      await _stdout.close();
      await _stderr.close();
      if (!_exit.isCompleted) _exit.complete(-1);
    };
  }

  _FakeProcess.openPipes()
    : _stdout = StreamController<List<int>>(),
      _stderr = StreamController<List<int>>(),
      _exit = Completer<int>() {
    _onKill = () async {
      await finishPipes();
      finishExit(-1);
    };
  }

  void finishExit(int code) {
    if (!_exit.isCompleted) _exit.complete(code);
  }

  void failStderr(Object error) => _stderr.addError(error);

  Future<void> finishPipes() async {
    if (!_stdout.isClosed) await _stdout.close();
    if (!_stderr.isClosed) await _stderr.close();
  }

  final StreamController<List<int>> _stdout;
  final StreamController<List<int>> _stderr;
  final Completer<int> _exit;
  final Completer<void> started = Completer<void>();
  String headerText = 'HTTP/1.1 200 OK\r\n\r\n';
  Future<void> Function()? _onKill;
  int killCount = 0;
  bool stdoutSettled = false;
  bool stderrSettled = false;
  bool exitSettled = false;

  @override
  Stream<List<int>> get stdout => _markSettled(_stdout.stream, true);
  @override
  Stream<List<int>> get stderr => _markSettled(_stderr.stream, false);
  Stream<List<int>> _markSettled(
    Stream<List<int>> stream,
    bool isStdout,
  ) async* {
    try {
      yield* stream;
    } finally {
      if (isStdout) {
        stdoutSettled = true;
      } else {
        stderrSettled = true;
      }
    }
  }

  @override
  Future<int> get exitCode async {
    final result = await _exit.future;
    exitSettled = true;
    return result;
  }

  @override
  IOSink get stdin => _FakeSink();
  @override
  int get pid => 123;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killCount++;
    _onKill?.call();
    if (!_exit.isCompleted && _onKill == null) _exit.complete(-1);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements IOSink {
  @override
  Future<void> close() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
