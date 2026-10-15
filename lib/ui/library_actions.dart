import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import 'format.dart';
import 'localized_labels.dart';
import 'verse_ui_state.dart';

/// Menu, dialog and sheet flows shared by the song, setlist and reader
/// screens. They talk to the UI controller only; outcomes are reported through
/// [VerseUiController.notices].

Future<void> handleSongMenuAction(
  BuildContext context,
  VerseUiController controller,
  String id,
  String action,
) async {
  switch (action) {
    case 'edit':
      await controller.editSong(id);
    case 'add':
      await showAddSongToSetlist(context, controller, id);
    case 'info':
      await showSongInfo(context, controller, id);
    case 'share':
      await controller.shareSong(id);
    case 'share_pdf':
      await controller.shareSongPdf(id);
    case 'copy':
      await controller.copySongChordPro(id);
    case 'print':
      await controller.printSong(id);
    case 'delete':
      await confirmDeleteSong(context, controller, id);
  }
}

Future<void> handleSetlistAction(
  BuildContext context,
  VerseUiController controller,
  String id,
  String action,
) async {
  switch (action) {
    case 'share':
      await controller.shareSetlist(id);
    case 'share_pdf':
      await controller.shareSetlistPdf(id);
    case 'print':
      await controller.printSetlist(id);
    case 'copy':
      await controller.copySetlist(id);
    case 'duplicate':
      final l10n = AppLocalizations.of(context);
      final name = controller.state.setlists
          .where((item) => item.id == id)
          .map((item) => item.title)
          .firstOrNull;
      await controller.duplicateSetlist(
        id,
        copyName: name == null ? null : l10n.setlistCopyName(name),
      );
    case 'edit':
      await controller.editSetlist(id);
    case 'delete':
      await _confirmDeleteSetlist(context, controller, id);
  }
}

Future<void> _confirmDeleteSetlist(
  BuildContext context,
  VerseUiController controller,
  String id,
) async {
  final l10n = AppLocalizations.of(context);
  final yes = await _confirm(
    context,
    title: l10n.setlistDeleteConfirmTitle,
    message: l10n.setlistDeleteConfirmMessage,
    confirmLabel: l10n.actionDelete,
    cancelLabel: l10n.actionCancel,
  );
  if (yes == true) await controller.deleteSetlist(id);
}

Future<void> confirmDeleteSong(
  BuildContext context,
  VerseUiController controller,
  String id,
) async {
  final l10n = AppLocalizations.of(context);
  final yes = await _confirm(
    context,
    title: l10n.songDeleteConfirmTitle,
    message: l10n.songDeleteConfirmMessage,
    confirmLabel: l10n.actionDelete,
    cancelLabel: l10n.actionCancel,
  );
  if (yes == true) await controller.deleteSong(id);
}

Future<void> confirmClearHistory(
  BuildContext context,
  VerseUiController controller,
) async {
  final l10n = AppLocalizations.of(context);
  final yes = await _confirm(
    context,
    title: l10n.settingsClearHistory,
    message: l10n.settingsClearHistoryConfirm,
    confirmLabel: l10n.actionClear,
    cancelLabel: l10n.actionCancel,
  );
  if (yes == true) controller.clearHistory();
}

/// Asks whether unsaved editor changes may be discarded.
Future<bool> confirmDiscardEdits(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final yes = await _confirm(
    context,
    title: l10n.editorUnsavedTitle,
    message: l10n.editorUnsavedMessage,
    confirmLabel: l10n.actionDiscard,
    cancelLabel: l10n.editorKeepEditing,
  );
  return yes == true;
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
  ),
);

/// Adds [songId] to a setlist chosen by the person. Without any setlist, one
/// is created (with the localized default name) and the song is added to it.
Future<void> showAddSongToSetlist(
  BuildContext context,
  VerseUiController controller,
  String songId,
) async {
  final l10n = AppLocalizations.of(context);
  final choices = controller.state.setlists;
  if (choices.isEmpty) {
    await controller.createSetlist(name: l10n.setlistCreate, songId: songId);
    return;
  }
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.songAddToSetlist,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final item in choices)
            ListTile(
              title: Text(item.title),
              trailing: const Icon(Icons.add_rounded),
              onTap: () => Navigator.pop(context, item.id),
            ),
        ],
      ),
    ),
  );
  if (chosen != null) await controller.addSongToSetlist(songId, chosen);
}

/// Lets the person pick several songs to append to [setlistId].
Future<void> showAddSongsToSetlist(
  BuildContext context,
  VerseUiController controller,
  String setlistId,
) async {
  final l10n = AppLocalizations.of(context);
  final chosenSongs = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SongPickerSheet(
      songs: controller.state.songs,
      title: l10n.setlistAddSongs,
    ),
  );
  if (chosenSongs == null) return;
  for (final songId in chosenSongs) {
    await controller.addSongToSetlist(songId, setlistId);
  }
}

class _SongPickerSheet extends StatefulWidget {
  const _SongPickerSheet({required this.songs, required this.title});
  final List<SongCardData> songs;
  final String title;
  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _query = TextEditingController();
  final _selected = <String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needle = _query.text.trim().toLowerCase();
    final songs = widget.songs
        .where(
          (song) => '${song.title} ${song.artist} ${song.album ?? ''}'
              .toLowerCase()
              .contains(needle),
        )
        .toList();
    final height = MediaQuery.sizeOf(context).height * .9;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.navClose,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: songs.isEmpty
                  ? Center(child: Text(l10n.songsEmptySearch))
                  : ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return CheckboxListTile(
                          value: _selected.contains(song.id),
                          title: Text(song.title),
                          subtitle: song.artist.isEmpty
                              ? null
                              : Text(song.artist),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              _selected.add(song.id);
                            } else {
                              _selected.remove(song.id);
                            }
                          }),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          _selected.toList(growable: false),
                        ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('${l10n.setlistAddSongs} (${_selected.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edits the key and capo used for one setlist entry. [name] and [notes] are
/// text typed in the setlist form that must be saved together with the change.
Future<void> editEntryOverrides(
  BuildContext context,
  VerseUiController controller,
  String setlistId,
  SetlistEntryData entry, {
  String? name,
  String? notes,
}) async {
  final l10n = AppLocalizations.of(context);
  var key = entry.keyOverride ?? '';
  var capo = entry.capoOverride ?? '';
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.setlistEntryOverride),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: key,
            decoration: InputDecoration(labelText: l10n.editorKeyField),
            onChanged: (value) => key = value,
          ),
          TextFormField(
            initialValue: capo,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.editorCapoField),
            onChanged: (value) => capo = value,
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
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
  if (saved != true) return;
  await controller.saveSetlistEntryOverrides(
    setlistId,
    entry.id,
    key: key,
    capo: capo,
    name: name,
    notes: notes,
  );
}

Future<void> showSongInfo(
  BuildContext context,
  VerseUiController controller,
  String id,
) async {
  final info = controller.songInfo(id);
  if (info == null) return;
  final l10n = AppLocalizations.of(context);
  final labels = <(String, String)>[
    ('album', l10n.editorAlbumField),
    ('key', l10n.editorKeyField),
    ('capo', l10n.editorCapoField),
    ('tuning', l10n.editorTuningField),
    ('tempo', l10n.editorTempoField),
    ('timeSignature', l10n.editorTimeSignatureField),
    ('durationSeconds', l10n.editorDurationField),
    ('language', l10n.editorLanguageField),
    ('year', l10n.editorYearField),
    ('composer', l10n.editorComposerField),
    ('lyricist', l10n.editorLyricistField),
    ('copyright', l10n.editorCopyrightField),
    ('license', l10n.editorLicenseField),
  ];
  final fields = <(String, Object?)>[
    for (final label in labels)
      (
        label.$2,
        label.$1 == 'durationSeconds' && info.fields[label.$1] is num
            ? formatDuration((info.fields[label.$1] as num).toDouble())
            : info.fields[label.$1],
      ),
  ].where((entry) => entry.$2 != null && entry.$2.toString().isNotEmpty);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.navBack,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text(
                l10n.songInfo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          Text(info.title, style: Theme.of(context).textTheme.headlineSmall),
          if (info.artist.isNotEmpty)
            Text(info.artist, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final field in fields)
            ListTile(
              dense: true,
              title: Text(field.$1),
              subtitle: Text('${field.$2}'),
            ),
          if (info.sources.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                l10n.songInfoSources,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final source in info.sources)
              ListTile(
                dense: true,
                leading: const Icon(Icons.source_outlined),
                title: Text(source.providerName),
                subtitle: Text(
                  [
                    source.attribution,
                    if (source.matchReason != null &&
                        source.matchReason!.isNotEmpty)
                      localizedMatchReason(l10n, source.matchReason),
                  ].where((part) => part.isNotEmpty).join(' · '),
                ),
                trailing: _httpUri(source.url) == null
                    ? null
                    : const Icon(Icons.open_in_new_rounded),
                onTap: _httpUri(source.url) == null
                    ? null
                    : () => launchUrl(
                        _httpUri(source.url)!,
                        mode: LaunchMode.externalApplication,
                      ),
              ),
          ],
        ],
      ),
    ),
  );
}

Uri? _httpUri(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
    return null;
  }
  return uri;
}
