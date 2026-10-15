import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../localized_labels.dart';
import '../verse_ui_state.dart';

/// Error codes that are fixed by signing in (again).
const _signInAgainCodes = {
  'authorization_required',
  'access_denied',
  'not_signed_in',
  'sign_in_failed',
};

/// The sync refused to delete items the cloud no longer lists.
const _suspiciousCode = 'remote_listing_suspicious';

/// Codes where retrying cannot help or would only repeat the failure.
const _noRetryCodes = {'not_configured'};

/// The Settings "Account and sync" card: sign-in state, last sync, conflicts,
/// errors with a next step, auto-sync and sign-out.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key, required this.controller, this.now});
  final VerseUiController controller;

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!state.syncReady)
            _unavailable(l10n)
          else if (!state.syncSignedIn)
            ..._signedOut(context, l10n, state)
          else
            ..._signedIn(context, l10n, state),
        ],
      ),
    );
  }

  Widget _unavailable(AppLocalizations l10n) => ListTile(
    key: const ValueKey('account-unavailable'),
    leading: const Icon(Icons.cloud_off_outlined),
    title: Text(l10n.accountUnavailableTitle),
    subtitle: Text(l10n.accountUnavailable),
  );

  List<Widget> _signedOut(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
  ) {
    final code = state.syncErrorCode;
    return [
      ListTile(
        key: const ValueKey('account-signed-out'),
        leading: const Icon(Icons.cloud_outlined),
        title: Text(l10n.accountSignedOut),
        subtitle: Text(l10n.accountSignedOutBenefits),
      ),
      if (code != null) _ErrorCallout(code: code, action: null, onAction: null),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: FilledButton.icon(
          key: const ValueKey('account-sign-in'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: state.syncBusy ? null : controller.signInForSync,
          icon: state.syncBusy
              ? const _Spinner()
              : const Icon(Icons.login_rounded),
          label: Text(
            state.syncBusy ? l10n.accountWorking : l10n.accountSignInWithGoogle,
          ),
        ),
      ),
    ];
  }

  List<Widget> _signedIn(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
  ) {
    final code = state.syncBusy ? null : state.syncErrorCode;
    final hasConflictCopies = state.songs.any((song) => song.isConflictCopy);
    return [
      ListTile(
        key: const ValueKey('account-signed-in'),
        leading: const Icon(Icons.account_circle_outlined),
        title: Text(state.accountName ?? l10n.accountTitle),
        subtitle: _SyncStatus(
          busy: state.syncBusy,
          lastSyncAt: state.lastSyncAt,
          now: now,
        ),
      ),
      if (state.lastSyncConflicts > 0)
        _ConflictCallout(
          count: state.lastSyncConflicts,
          onReview: hasConflictCopies ? controller.reviewSyncConflicts : null,
        ),
      if (code != null)
        _ErrorCallout(
          code: code,
          suspiciousCount: state.syncSuspiciousDeletionCount,
          action: _errorActionLabel(l10n, code),
          onAction: _errorAction(context, code),
        ),
      if (code == null && state.syncWarningCode != null && !state.syncBusy)
        _WarningCallout(code: state.syncWarningCode!),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: FilledButton.tonalIcon(
          key: const ValueKey('account-sync-now'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: state.syncBusy ? null : controller.syncNow,
          icon: state.syncBusy
              ? const _Spinner()
              : const Icon(Icons.sync_rounded),
          label: Text(
            state.syncBusy ? l10n.accountSyncing : l10n.accountSyncNow,
          ),
        ),
      ),
      SwitchListTile(
        key: const ValueKey('account-auto-sync'),
        title: Text(l10n.accountAutoSync),
        subtitle: Text(l10n.accountAutoSyncHint),
        value: state.autoSyncEnabled,
        onChanged: controller.setAutoSync,
      ),
      ListTile(
        key: const ValueKey('account-use-different'),
        leading: const Icon(Icons.switch_account_outlined),
        title: Text(l10n.accountUseDifferent),
        enabled: !state.syncBusy,
        onTap: state.syncBusy ? null : () => _useDifferentAccount(),
      ),
      ListTile(
        key: const ValueKey('account-sign-out'),
        leading: const Icon(Icons.logout_rounded),
        title: Text(l10n.accountSignOut),
        enabled: !state.syncBusy,
        onTap: state.syncBusy ? null : () => _confirmSignOut(context),
      ),
    ];
  }

  String? _errorActionLabel(AppLocalizations l10n, String code) {
    if (_noRetryCodes.contains(code)) return null;
    if (code == 'account_changed' || code == _suspiciousCode) {
      return l10n.accountChooseAction;
    }
    if (_signInAgainCodes.contains(code)) return l10n.accountSignInAgain;
    return l10n.actionRetry;
  }

  VoidCallback? _errorAction(BuildContext context, String code) {
    if (_noRetryCodes.contains(code)) return null;
    if (code == 'account_changed') {
      return () => showAccountChangeDialog(context, controller);
    }
    if (code == _suspiciousCode) {
      return () => showRemoteDeletionsDialog(context, controller);
    }
    if (_signInAgainCodes.contains(code)) return controller.signInForSync;
    return controller.syncNow;
  }

  Future<void> _useDifferentAccount() async {
    await controller.signOutFromSync();
    await controller.signInForSync();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountSignOutTitle),
        content: Text(l10n.accountSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('account-sign-out-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.accountSignOut),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.signOutFromSync();
  }
}

/// How the person answered a `remote_listing_suspicious` stop.
enum RemoteDeletionsChoice { deleteHere, keepLocal }

/// Explains that items this device synced before are missing from Google Drive
/// and asks what to do, then applies the choice. Keeping the local library is
/// the default; deleting needs a second, explicit confirmation, and declining
/// that returns to the choices. Returns the choice, or null when cancelled.
Future<RemoteDeletionsChoice?> showRemoteDeletionsDialog(
  BuildContext context,
  VerseUiController controller,
) async {
  final count = controller.state.syncSuspiciousDeletionCount;
  RemoteDeletionsChoice? choice;
  while (true) {
    choice = await _askRemoteDeletions(context, count);
    if (choice != RemoteDeletionsChoice.deleteHere) break;
    if (!context.mounted) return null;
    if (await _confirmRemoteDeletions(context, count) == true) break;
    if (!context.mounted) return null;
  }
  switch (choice) {
    case RemoteDeletionsChoice.deleteHere:
      await controller.confirmRemoteDeletions();
    case RemoteDeletionsChoice.keepLocal:
      await controller.keepLocalAfterRemoteDeletions();
    case null:
      break;
  }
  return choice;
}

Future<RemoteDeletionsChoice?> _askRemoteDeletions(
  BuildContext context,
  int count,
) => showDialog<RemoteDeletionsChoice>(
  context: context,
  barrierDismissible: false,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    void pop([RemoteDeletionsChoice? value]) =>
        Navigator.of(context).pop(value);
    return AlertDialog(
      key: const ValueKey('remote-deletions-dialog'),
      scrollable: true,
      title: Text(l10n.accountSuspiciousTitle),
      content: Text(l10n.accountSuspiciousBody(count)),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        FilledButton(
          key: const ValueKey('remote-deletions-keep'),
          autofocus: true,
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => pop(RemoteDeletionsChoice.keepLocal),
          child: Text(l10n.accountSuspiciousKeep, textAlign: TextAlign.center),
        ),
        OutlinedButton(
          key: const ValueKey('remote-deletions-delete'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => pop(RemoteDeletionsChoice.deleteHere),
          child: Text(
            l10n.accountSuspiciousDelete,
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          key: const ValueKey('remote-deletions-cancel'),
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: pop,
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  },
);

Future<bool?> _confirmRemoteDeletions(BuildContext context, int count) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          key: const ValueKey('remote-deletions-confirm-dialog'),
          scrollable: true,
          icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
          title: Text(l10n.accountSuspiciousDeleteConfirmTitle(count)),
          content: Text(l10n.accountSuspiciousDeleteConfirmBody),
          actions: [
            TextButton(
              key: const ValueKey('remote-deletions-confirm-cancel'),
              autofocus: true,
              style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const ValueKey('remote-deletions-confirm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 48),
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.accountSuspiciousDeleteConfirmAction),
            ),
          ],
        );
      },
    );

/// Which way the person resolved an account change.
enum AccountChangeChoice { merge, replace, signOut }

/// Asks how to continue after a different Google account signed in, then
/// applies the choice. Returns the choice, or null when dismissed.
Future<AccountChangeChoice?> showAccountChangeDialog(
  BuildContext context,
  VerseUiController controller,
) async {
  AccountChangeChoice? choice;
  // "Replace" deletes local content, so it needs a second, explicit answer;
  // declining returns to the choices instead of closing the decision.
  while (true) {
    choice = await _askAccountChange(context);
    if (choice != AccountChangeChoice.replace) break;
    if (!context.mounted) return null;
    if (await _confirmReplace(context) == true) break;
    if (!context.mounted) return null;
  }
  switch (choice) {
    case AccountChangeChoice.merge:
      await controller.adoptAccount(mergeLocal: true);
    case AccountChangeChoice.replace:
      await controller.adoptAccount(mergeLocal: false);
    case AccountChangeChoice.signOut:
      await controller.signOutFromSync();
    case null:
      break;
  }
  return choice;
}

Future<bool?> _confirmReplace(BuildContext context) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const ValueKey('account-replace-confirm-dialog'),
      scrollable: true,
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l10n.accountReplaceConfirmTitle),
      content: Text(l10n.accountReplaceConfirmBody),
      actions: [
        TextButton(
          key: const ValueKey('account-replace-cancel'),
          autofocus: true,
          style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const ValueKey('account-replace-confirm'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 48),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.accountReplaceConfirmAction),
        ),
      ],
    );
  },
);

Future<AccountChangeChoice?> _askAccountChange(BuildContext context) {
  return showDialog<AccountChangeChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final hintStyle = Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
      void pop(AccountChangeChoice value) => Navigator.of(context).pop(value);
      return AlertDialog(
        key: const ValueKey('account-change-dialog'),
        scrollable: true,
        title: Text(l10n.accountChangedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.accountChangedBody),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('account-change-merge'),
              style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => pop(AccountChangeChoice.merge),
              child: Text(
                l10n.accountChangedMerge,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text(l10n.accountChangedMergeHint, style: hintStyle),
            ),
            OutlinedButton(
              key: const ValueKey('account-change-replace'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => pop(AccountChangeChoice.replace),
              child: Text(
                l10n.accountChangedReplace,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text(l10n.accountChangedReplaceHint, style: hintStyle),
            ),
            TextButton(
              key: const ValueKey('account-change-sign-out'),
              style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => pop(AccountChangeChoice.signOut),
              child: Text(
                l10n.accountChangedSignOut,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// "Synced 3 minutes ago", refreshed every half minute while it is on screen
/// so the relative time does not go stale. A fixed [now] (tests) turns the
/// refresh off.
class _SyncStatus extends StatefulWidget {
  const _SyncStatus({
    required this.busy,
    required this.lastSyncAt,
    required this.now,
  });
  final bool busy;
  final DateTime? lastSyncAt;
  final DateTime? now;

  @override
  State<_SyncStatus> createState() => _SyncStatusState();
}

class _SyncStatusState extends State<_SyncStatus> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    if (widget.now == null) {
      _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && !widget.busy) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = widget.busy
        ? l10n.accountSyncing
        : lastSyncedLabel(
            l10n,
            widget.lastSyncAt,
            widget.now ?? DateTime.now(),
          );
    return Semantics(
      liveRegion: true,
      child: Text(status, key: const ValueKey('account-status')),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

class _ConflictCallout extends StatelessWidget {
  const _ConflictCallout({required this.count, required this.onReview});
  final int count;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return _Callout(
      key: const ValueKey('account-conflicts'),
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      icon: Icons.call_split_rounded,
      title: l10n.accountConflictsTitle(count),
      body: l10n.accountConflictsBody,
      actionLabel: onReview == null ? null : l10n.accountReviewConflicts,
      onAction: onReview,
    );
  }
}

/// A neutral notice: the sync worked but skipped some unusable files.
class _WarningCallout extends StatelessWidget {
  const _WarningCallout({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = syncWarningText(AppLocalizations.of(context), code);
    return _Callout(
      key: const ValueKey('account-warning'),
      background: scheme.surfaceContainerHighest,
      foreground: scheme.onSurface,
      icon: Icons.info_outline_rounded,
      title: text.message,
      body: text.hint,
    );
  }
}

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({
    required this.code,
    required this.action,
    required this.onAction,
    this.suspiciousCount = 0,
  });
  final String code;
  final int suspiciousCount;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = code == _suspiciousCode && suspiciousCount > 0
        ? (
            message: l10n.accountSuspiciousTitle,
            hint: l10n.accountSuspiciousBody(suspiciousCount),
          )
        : syncErrorText(l10n, code);
    return _Callout(
      key: const ValueKey('account-error'),
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      icon: Icons.error_outline_rounded,
      title: text.message,
      body: text.hint,
      actionLabel: onAction == null ? null : action,
      onAction: onAction,
      liveRegion: true,
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    super.key,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.liveRegion = false,
  });
  final Color background, foreground;
  final IconData icon;
  final String title, body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Semantics(
        container: true,
        liveRegion: liveRegion,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(icon, color: foreground)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: foreground,
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onPressed: onAction,
                          child: Text(actionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
