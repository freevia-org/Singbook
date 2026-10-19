import 'dart:io';

import 'package:flutter/services.dart';

import 'sync_protocol.dart';

/// Opens Google's native Drive Picker flow for one visible folder.
///
/// The returned ID is the only folder granted to Singbook by the picker; the
/// app never asks for broad Drive access. Android's AuthorizationClient owns
/// the consent and picker UI.
class GoogleDriveFolderPicker {
  static const _channel = MethodChannel('org.freevia.singbook/rich_clipboard');

  Future<String> pickFolder({String? accountEmail}) async {
    if (!Platform.isAndroid) {
      throw const SyncException('folder_picker_unavailable');
    }
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'pickVisibleDriveFolder',
        {'accountEmail': accountEmail},
      );
      final id = result?['folderId'];
      if (id is! String || id.isEmpty) {
        throw const SyncException('folder_not_selected');
      }
      return id;
    } on PlatformException catch (error) {
      if (error.code == 'cancelled' || error.code == 'nothing_selected') {
        throw const SyncException('cancelled');
      }
      if (error.code == 'folder_not_selected') {
        throw const SyncException('folder_not_selected');
      }
      if (error.code == 'account_mismatch') {
        throw const SyncException('drive_file_authorization_required');
      }
      throw SyncException(
        error.code == 'picker_busy'
            ? 'sync_in_progress'
            : 'folder_picker_failed',
      );
    }
  }

  /// Explicitly picks one or more ChordPro files. `drive.file` grants access
  /// only to these selected files, which are then adopted into the library.
  Future<List<String>> pickChordProFiles({String? accountEmail}) async {
    if (!Platform.isAndroid) {
      throw const SyncException('folder_picker_unavailable');
    }
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'pickChordProFiles',
        {'accountEmail': accountEmail},
      );
      final ids = result?['fileIds'];
      if (ids is! List) return const [];
      return ids.whereType<String>().where((id) => id.isNotEmpty).toList();
    } on PlatformException catch (error) {
      if (error.code == 'cancelled' || error.code == 'nothing_selected') {
        throw const SyncException('cancelled');
      }
      if (error.code == 'account_mismatch') {
        throw const SyncException('drive_file_authorization_required');
      }
      throw SyncException(
        error.code == 'picker_busy'
            ? 'sync_in_progress'
            : 'folder_picker_failed',
      );
    }
  }
}
