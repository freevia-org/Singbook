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
      if (code != null)
        _ErrorCallout(
          code: code,
          action: null,
          onAction: null,
        ),
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
            state.syncBusy
                ? l10n.accountWorking
                : l10n.accountSignInWithGoogle,
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
    final status = state.syncBusy
        ? l10n.accountSyncing
        : lastSyncedLabel(l10n, state.lastSyncAt, now ?? DateTime.now());
    final hasConflictCopies = state.songs.any((song) => song.isConflictCopy);
    return [
      ListTile(
        key: const ValueKey('account-signed-in'),
        leading: const Icon(Icons.account_circle_outlined),
        title: Text(state.accountName ?? l10n.accountTitle),
        subtitle: Semantics(
          liveRegion: true,
          child: Text(status, key: const ValueKey('account-status')),
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
          action: _errorActionLabel(l10n, code),
          onAction: _errorAction(context, code),
        ),
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
    if (code == 'account_changed') return l10n.accountChooseAction;
    if (_signInAgainCodes.contains(code)) return l10n.accountSignInAgain;
    return l10n.actionRetry;
  }

  VoidCallback? _errorAction(BuildContext context, String code) {
    if (_noRetryCodes.contains(code)) return null;
    if (code == 'account_changed') {
      return () => showAccountChangeDialog(context, controller);
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

/// Which way the person resolved an account change.
enum AccountChangeChoice { merge, replace, signOut }

/// Asks how to continue after a different Google account signed in, then
/// applies the choice. Returns the choice, or null when dismissed.
Future<AccountChangeChoice?> showAccountChangeDialog(
  BuildContext context,
  VerseUiController controller,
) async {
  final choice = await showDialog<AccountChangeChoice>(
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
              child: Text(l10n.accountChangedMerge, textAlign: TextAlign.center),
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

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({
    required this.code,
    required this.action,
    required this.onAction,
  });
  final String code;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = syncErrorText(l10n, code);
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
