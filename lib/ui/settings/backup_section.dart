import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../application/file_actions.dart';
import '../../l10n/generated/app_localizations.dart';

class BackupSection extends StatefulWidget {
  const BackupSection({
    super.key,
    required this.controller,
    required this.files,
    this.syncConnected = false,
  });
  final AppController controller;
  final VerseFileActions files;
  final bool syncConnected;

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;
  bool _includePreferences = true;

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final bytes = await widget.controller.exportBackup(
        includePreferences: _includePreferences,
      );
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await widget.files.shareBackupBytes(
        bytes,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      _message(l10n.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final file = await widget.files.pickDocument();
      if (file == null || !mounted) return;
      final preview = await widget.controller.inspectBackup(file);
      if (!mounted) return;
      var mode = BackupRestoreMode.merge;
      var preferences = false;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text(l10n.backupRestore),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.backupSummary(
                    preview.songCount,
                    preview.setlistCount,
                    preview.conflictingSongCount +
                        preview.conflictingSetlistCount,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.syncConnected) ...[
                  Text('${l10n.accountAutoSync}: ${l10n.accountAutoSyncHint}'),
                  const SizedBox(height: 12),
                ],
                RadioGroup<BackupRestoreMode>(
                  groupValue: mode,
                  onChanged: (value) => update(() => mode = value!),
                  child: Column(
                    children: [
                      RadioListTile<BackupRestoreMode>(
                        contentPadding: EdgeInsets.zero,
                        value: BackupRestoreMode.merge,
                        title: Text(l10n.backupMerge),
                        subtitle: Text(l10n.backupMergeHint),
                      ),
                      RadioListTile<BackupRestoreMode>(
                        contentPadding: EdgeInsets.zero,
                        value: BackupRestoreMode.replace,
                        title: Text(l10n.backupReplace),
                        subtitle: Text(l10n.backupReplaceHint),
                      ),
                    ],
                  ),
                ),
                if (preview.includedPreferenceKeys.isNotEmpty)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: preferences,
                    onChanged: (value) => update(() => preferences = value!),
                    title: Text(l10n.backupRestorePreferences),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.backupRestore),
              ),
            ],
          ),
        ),
      );
      if (proceed != true || !mounted) return;
      if (mode == BackupRestoreMode.replace) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.backupReplace),
            content: Text(l10n.backupReplaceConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.backupReplace),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      await widget.controller.restoreBackup(
        file,
        mode: mode,
        expectedPreviewToken: preview.token,
        restorePreferences: preferences,
      );
      _message(l10n.backupRestored);
    } catch (_) {
      _message(l10n.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(l10n.backupTitle),
            subtitle: Text(l10n.backupLocalHint),
            trailing: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  )
                : null,
          ),
          CheckboxListTile(
            value: _includePreferences,
            onChanged: _busy
                ? null
                : (value) => setState(() => _includePreferences = value!),
            title: Text(l10n.backupIncludePreferences),
          ),
          ListTile(
            key: const ValueKey('backup-export'),
            leading: const Icon(Icons.save_alt),
            title: Text(l10n.backupExport),
            enabled: !_busy,
            onTap: _busy ? null : _export,
          ),
          ListTile(
            key: const ValueKey('backup-restore'),
            leading: const Icon(Icons.restore),
            title: Text(l10n.backupRestore),
            enabled: !_busy,
            onTap: _busy ? null : _restore,
          ),
        ],
      ),
    );
  }
}
