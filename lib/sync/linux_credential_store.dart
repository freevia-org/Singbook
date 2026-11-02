import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'windows_google_auth.dart';

/// Linux has no always-present credential vault, so tokens are kept in
/// owner-only files (mode 0600, directory 0700) under the user's application
/// support directory, outside the portable library and its backups. Like other
/// desktop clients (gcloud, rclone), protection is the user account itself.
class LinuxCredentialStore implements DesktopCredentialStore {
  LinuxCredentialStore({Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, 'credentials'),
  );

  Future<File> _file(String key) async {
    final dir = await _directory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      await _chmod('700', dir.path);
    }
    return File(p.join(dir.path, sha256.convert(utf8.encode(key)).toString()));
  }

  static Future<void> _chmod(String mode, String path) async {
    final result = await Process.run('chmod', [mode, path]);
    if (result.exitCode != 0) {
      throw FileSystemException('Could not restrict permissions', path);
    }
  }

  @override
  Future<String?> read(String key) async {
    final file = await _file(key);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    final file = await _file(key);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString('');
    await _chmod('600', temp.path);
    await temp.writeAsString(value, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> delete(String key) async {
    final file = await _file(key);
    if (await file.exists()) await file.delete();
  }
}
