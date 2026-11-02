@TestOn('linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:singbook/sync/linux_credential_store.dart';

void main() {
  test('stores tokens in owner-only files and deletes them', () async {
    final root = await Directory.systemTemp.createTemp('singbook-cred');
    addTearDown(() => root.delete(recursive: true));
    final store = LinuxCredentialStore(
      directory: () async => Directory('${root.path}/credentials'),
    );
    expect(await store.read('k'), isNull);
    await store.write('k', 'secret');
    await store.write('k', 'secret2');
    expect(await store.read('k'), 'secret2');
    final file = Directory('${root.path}/credentials').listSync().single;
    expect(file.statSync().mode & 0x1ff, 0x180); // 0600
    await store.delete('k');
    expect(await store.read('k'), isNull);
  });
}
