import 'dart:collection';

import 'package:http/http.dart' as http;

/// Collects bounded, privacy-safe aggregate diagnostics for maintenance HTTP.
/// Only URI hostnames and numeric response facts are retained.
class MaintenanceHttpDiagnosticsClient extends http.BaseClient {
  MaintenanceHttpDiagnosticsClient(this._inner);

  final http.Client _inner;
  final Map<String, _HostCounts> _hosts = {};
  int _networkFailures = 0;

  Map<String, dynamic> get report => {
    'networkFailures': _networkFailures,
    'hosts': {
      for (final host in (_hosts.keys.toList()..sort()))
        host: _hosts[host]!.toJson(),
    },
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final host = request.url.host.toLowerCase();
    final counts = _hosts.putIfAbsent(host, _HostCounts.new);
    counts.requests++;
    try {
      final response = await _inner.send(request);
      counts.statuses.update(
        response.statusCode.toString(),
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      if (retryAfter != null && retryAfter >= 0 && retryAfter <= 86400) {
        counts.retryAfterSeconds[retryAfter] =
            (counts.retryAfterSeconds[retryAfter] ?? 0) + 1;
      }
      final databaseLag = int.tryParse(
        response.headers['x-database-lag'] ?? '',
      );
      if (databaseLag != null && databaseLag >= 0 && databaseLag <= 86400) {
        counts.databaseLag[databaseLag] =
            (counts.databaseLag[databaseLag] ?? 0) + 1;
      }
      return response;
    } catch (_) {
      _networkFailures++;
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

class _HostCounts {
  int requests = 0;
  final Map<String, int> statuses = {};
  final Map<int, int> retryAfterSeconds = {};
  final Map<int, int> databaseLag = {};

  Map<String, dynamic> toJson() => {
    'requests': requests,
    'statuses': SplayTreeMap<String, int>.from(statuses),
    'retryAfterSeconds': {
      for (final value in (retryAfterSeconds.keys.toList()..sort()))
        value.toString(): retryAfterSeconds[value],
    },
    'databaseLag': {
      for (final value in (databaseLag.keys.toList()..sort()))
        value.toString(): databaseLag[value],
    },
  };
}
