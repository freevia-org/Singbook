import '../l10n/generated/app_localizations.dart';
import 'verse_ui_state.dart' show UiNotice;

String localizedMatchReason(AppLocalizations l10n, String? code) {
  if (code == null || code.isEmpty) return '';
  return switch (code) {
    'same_recording' => l10n.searchMatchExact,
    'same_song' => l10n.searchMatchSameSong,
    'arrangement_requires_agreement' ||
    'uncorroborated_arrangement' => l10n.searchMatchNeedsAgreement,
    'incomplete_or_different_lyrics' => l10n.searchMatchDifferentLyrics,
    'identity_mismatch' => l10n.searchMatchUnverified,
    'pending' => l10n.searchProviderPending,
    'combined_sources' => l10n.searchMatchCombinedSources,
    'best_available' => l10n.searchMatchBestAvailable,
    _ =>
      RegExp(r'^[a-z][A-Za-z0-9_]+$').hasMatch(code)
          ? l10n.searchMatchUnverified
          : code,
  };
}

String localizedProviderDescription(AppLocalizations l10n, String value) {
  final descriptions = <String, String Function(AppLocalizations)>{
    'downloadChordProThenImport': (l10n) =>
        l10n.providerDescDownloadChordProThenImport,
    'freeAccountDownloadThenImport': (l10n) =>
        l10n.providerDescFreeAccountDownloadThenImport,
    'publicChordSheets': (l10n) => l10n.providerDescPublicChordSheets,
    'historicalTextPerWorkLicense': (l10n) =>
        l10n.providerDescHistoricalTextPerWorkLicense,
    'licensedCatalog': (l10n) => l10n.providerDescLicensedCatalog,
    'originalSongsCcBy': (l10n) => l10n.providerDescOriginalSongsCcBy,
    'perSongLicense': (l10n) => l10n.providerDescPerSongLicense,
    'recordingMetadataOnly': (l10n) => l10n.providerDescRecordingMetadataOnly,
    'compositionMetadataOnly': (l10n) =>
        l10n.providerDescCompositionMetadataOnly,
    'exactFileArtworkOnly': (l10n) => l10n.providerDescExactFileArtworkOnly,
  };
  final description = descriptions[value];
  if (description != null) return description(l10n);

  final capabilities = <String, String Function(AppLocalizations)>{
    'lyrics': (l10n) => l10n.providerCapabilityLyrics,
    'chords': (l10n) => l10n.providerCapabilityChords,
    'timing': (l10n) => l10n.providerCapabilityTiming,
    'search': (l10n) => l10n.providerCapabilitySearch,
    'metadata': (l10n) => l10n.providerCapabilityMetadata,
    'catalog': (l10n) => l10n.providerCapabilitySearch,
    'lineTiming': (l10n) => l10n.providerCapabilityTiming,
    'wordTiming': (l10n) => l10n.providerCapabilityTiming,
    'fileImport': (l10n) => l10n.actionImport,
  };
  final parts = value.split(' · ');
  if (parts.length > 1 || capabilities.containsKey(value)) {
    final translated = parts
        .map((part) => capabilities[part.trim()]?.call(l10n))
        .whereType<String>()
        .toSet();
    return translated.isEmpty
        ? l10n.providerDescriptionUnknown
        : translated.join(' · ');
  }
  return RegExp(r'^[a-z][A-Za-z0-9_]+$').hasMatch(value)
      ? l10n.providerDescriptionUnknown
      : value;
}

/// Text for a short outcome message (see [UiNotice]).
String noticeMessage(AppLocalizations l10n, UiNotice notice) =>
    switch (notice) {
      UiNotice.songSaved => l10n.searchSaved,
      UiNotice.songSaveFailed => l10n.searchSaveFailed,
      UiNotice.songDeleted => l10n.songDeleted,
      UiNotice.setlistDeleted => l10n.setlistDeleted,
      UiNotice.copied => l10n.settingsCopied,
      UiNotice.historyCleared => l10n.settingsHistoryCleared,
      UiNotice.importSuccess => l10n.settingsImportSuccess,
      UiNotice.importFailed => l10n.settingsImportFailed,
      UiNotice.importUnsupported => l10n.settingsImportUnsupported,
      UiNotice.importTooLarge => l10n.settingsImportTooLarge,
      UiNotice.exportFailed => l10n.settingsExportFailed,
      UiNotice.exportPdfTooLarge => l10n.settingsExportPdfTooLarge,
      UiNotice.timingTooLarge => l10n.settingsTimingTooLarge,
      UiNotice.importDuplicateSongId => l10n.settingsImportDuplicateSongId,
      UiNotice.editorSaved => l10n.editorSaved,
      UiNotice.editorSaveFailed => l10n.editorSaveFailed,
      UiNotice.editorSaveConflict => l10n.editorSaveConflict,
      UiNotice.setlistSaveConflict => l10n.setlistSaveConflict,
      UiNotice.syncSucceeded => l10n.accountSynced,
      UiNotice.syncFailed => l10n.accountSyncFailed,
      UiNotice.syncConflictsFound => l10n.accountNoticeConflicts,
      UiNotice.syncSkipped => l10n.accountNoticeSyncSkipped,
      UiNotice.signedIn => l10n.accountNoticeSignedIn,
      UiNotice.signedOut => l10n.accountNoticeSignedOut,
      UiNotice.genericError => l10n.errorGeneric,
    };

/// A human explanation of a sync failure and what to do about it.
typedef SyncErrorText = ({String message, String hint});

/// Maps a sync error code to localized text. Unknown codes read as a generic
/// failure; raw exception text is never shown.
SyncErrorText syncErrorText(AppLocalizations l10n, String? code) =>
    switch (code) {
      'not_configured' => (
        message: l10n.syncErrorNotConfigured,
        hint: l10n.syncErrorNotConfiguredHint,
      ),
      'folder_picker_unavailable' => (
        message: l10n.syncErrorFolderPickerUnavailable,
        hint: l10n.syncErrorFolderPickerUnavailableHint,
      ),
      'folder_picker_failed' || 'folder_not_selected' => (
        message: l10n.syncErrorFolderPickerUnavailable,
        hint: l10n.syncErrorFolderPickerUnavailableHint,
      ),
      'drive_folder_missing' => (
        message: l10n.syncErrorDriveFolderMissing,
        hint: l10n.syncErrorDriveFolderMissingHint,
      ),
      'visible_folder_required' => (
        message: l10n.syncErrorVisibleFolderRequired,
        hint: l10n.syncErrorVisibleFolderRequiredHint,
      ),
      'drive_file_authorization_required' => (
        message: l10n.syncErrorDriveFileAuthorization,
        hint: l10n.syncErrorDriveFileAuthorizationHint,
      ),
      'folder_migration_incomplete' || 'invalid_drive_folder' => (
        message: l10n.syncErrorFolderMigration,
        hint: l10n.syncErrorFolderMigrationHint,
      ),
      'not_signed_in' => (
        message: l10n.syncErrorNotSignedIn,
        hint: l10n.syncErrorNotSignedInHint,
      ),
      'authorization_required' => (
        message: l10n.syncErrorAuthorizationRequired,
        hint: l10n.syncErrorAuthorizationRequiredHint,
      ),
      'access_denied' => (
        message: l10n.syncErrorAccessDenied,
        hint: l10n.syncErrorAccessDeniedHint,
      ),
      'rate_limited' => (
        message: l10n.syncErrorRateLimited,
        hint: l10n.syncErrorRateLimitedHint,
      ),
      'storage_full' => (
        message: l10n.syncErrorStorageFull,
        hint: l10n.syncErrorStorageFullHint,
      ),
      'network' => (
        message: l10n.syncErrorNetwork,
        hint: l10n.syncErrorNetworkHint,
      ),
      'account_changed' => (
        message: l10n.syncErrorAccountChanged,
        hint: l10n.syncErrorAccountChangedHint,
      ),
      'remote_library_too_large' => (
        message: l10n.syncErrorRemoteLibraryTooLarge,
        hint: l10n.syncErrorRemoteLibraryTooLargeHint,
      ),
      'remote_listing_suspicious' => (
        message: l10n.syncErrorRemoteListingSuspicious,
        hint: l10n.syncErrorRemoteListingSuspiciousHint,
      ),
      'remote_changed' => (
        message: l10n.syncErrorRemoteChanged,
        hint: l10n.syncErrorRemoteChangedHint,
      ),
      'invalid_local_data' => (
        message: l10n.syncErrorInvalidLocalData,
        hint: l10n.syncErrorInvalidLocalDataHint,
      ),
      'no_account_change' => (
        message: l10n.syncErrorNoAccountChange,
        hint: l10n.syncErrorNoAccountChangeHint,
      ),
      'sign_in_failed' => (
        message: l10n.syncErrorSignInFailed,
        hint: l10n.syncErrorSignInFailedHint,
      ),
      _ => (message: l10n.syncErrorGeneric, hint: l10n.syncErrorGenericHint),
    };

/// Neutral explanation of the file a successful sync skipped (see
/// `VerseUiState.syncWarningCode`); it is not a failure.
SyncErrorText syncWarningText(AppLocalizations l10n, String? code) => (
  message: l10n.accountSyncWarningTitle,
  hint: switch (code) {
    'remote_file_too_large' ||
    'local_file_too_large' => l10n.accountSyncWarningTooLarge,
    'invalid_remote_data' ||
    'invalid_local_data' => l10n.accountSyncWarningInvalid,
    _ => l10n.accountSyncWarningBody,
  },
);

/// "Synced 5 minutes ago" / "Never synced".
String lastSyncedLabel(AppLocalizations l10n, DateTime? at, DateTime now) {
  if (at == null) return l10n.accountNeverSynced;
  final age = now.difference(at);
  if (age.inMinutes < 1) return l10n.accountSyncedJustNow;
  if (age.inHours < 1) return l10n.accountSyncedMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return l10n.accountSyncedHoursAgo(age.inHours);
  return l10n.accountSyncedDaysAgo(age.inDays);
}
