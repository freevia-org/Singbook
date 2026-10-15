import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../verse_ui_state.dart';
import '../widgets/subpage_header.dart';

/// Song editor. Reports unsaved changes through
/// [VerseUiController.setEditorDirty] so the shell can ask before discarding
/// them, and requires a title before saving.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.controller, required this.onBack});
  final VerseUiController controller;

  /// Leaves the editor (the shell confirms first when there are changes).
  final VoidCallback onBack;
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final SongEditorData _initial;
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  late final TextEditingController _key;
  late final TextEditingController _capo;
  late final TextEditingController _tuning;
  late final TextEditingController _tempo;
  late final TextEditingController _duration;
  late final TextEditingController _body;
  late final List<TextEditingController> _all;
  bool _titleMissing = false;
  bool _saving = false;
  bool _reportedDirty = false;

  @override
  void initState() {
    super.initState();
    _initial =
        widget.controller.state.editor ??
        const SongEditorData(songId: '', isNew: true);
    _title = TextEditingController(text: _initial.title);
    _artist = TextEditingController(text: _initial.artist);
    _album = TextEditingController(text: _initial.album);
    _key = TextEditingController(text: _initial.key);
    _capo = TextEditingController(text: _initial.capo);
    _tuning = TextEditingController(text: _initial.tuning);
    _tempo = TextEditingController(text: _initial.tempo);
    _duration = TextEditingController(text: _initial.duration);
    _body = TextEditingController(text: _initial.body);
    _all = [
      _title,
      _artist,
      _album,
      _key,
      _capo,
      _tuning,
      _tempo,
      _duration,
      _body,
    ];
    for (final controller in _all) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _all) {
      controller
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  bool get _dirty =>
      _title.text != _initial.title ||
      _artist.text != _initial.artist ||
      _album.text != _initial.album ||
      _key.text != _initial.key ||
      _capo.text != _initial.capo ||
      _tuning.text != _initial.tuning ||
      _tempo.text != _initial.tempo ||
      _duration.text != _initial.duration ||
      _body.text != _initial.body;

  void _onChanged() {
    final dirty = _dirty;
    if (dirty != _reportedDirty) {
      _reportedDirty = dirty;
      widget.controller.setEditorDirty(dirty);
    }
    if (_titleMissing && _title.text.trim().isNotEmpty) {
      setState(() => _titleMissing = false);
    }
  }

  String _safeHeader(String value) =>
      value.replaceAll(RegExp(r'[\r\n{}]'), ' ').trim();

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _titleMissing = true);
      return;
    }
    _saving = true;
    try {
      await widget.controller.saveLyricsEdit(
        [
          '{title: ${_safeHeader(_title.text)}}',
          '{artist: ${_safeHeader(_artist.text)}}',
          '{album: ${_safeHeader(_album.text)}}',
          '{key: ${_safeHeader(_key.text)}}',
          '{capo: ${_safeHeader(_capo.text)}}',
          '{tuning: ${_safeHeader(_tuning.text)}}',
          '{tempo: ${_safeHeader(_tempo.text)}}',
          '{duration: ${_safeHeader(_duration.text)}}',
          '',
          _body.text,
        ].join('\n'),
      );
    } finally {
      _saving = false;
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    double width, {
    String? errorText,
  }) => SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleError = _titleMissing ? l10n.editorFieldRequired : null;
    return Column(
      children: [
        SubpageHeader(
          title: l10n.editorTitle,
          onBack: widget.onBack,
          actions: [
            IconButton(
              tooltip: l10n.actionSave,
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 700) {
                final metadataWidth = (constraints.maxWidth * .42)
                    .clamp(300.0, 380.0)
                    .toDouble();
                final fieldWidth = metadataWidth - 56;
                return Row(
                  key: const ValueKey('tablet-editor-split'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: metadataWidth,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 16, 28),
                        children: [
                          Column(
                            children: [
                              _field(
                                _title,
                                l10n.editorTitleField,
                                fieldWidth,
                                errorText: titleError,
                              ),
                              _field(
                                _artist,
                                l10n.editorArtistField,
                                fieldWidth,
                              ),
                              _field(_album, l10n.editorAlbumField, fieldWidth),
                              _field(_key, l10n.editorKeyField, fieldWidth),
                              _field(_capo, l10n.editorCapoField, fieldWidth),
                              _field(
                                _tuning,
                                l10n.editorTuningField,
                                fieldWidth,
                              ),
                              _field(_tempo, l10n.editorTempoField, fieldWidth),
                              _field(
                                _duration,
                                l10n.editorDurationField,
                                fieldWidth,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l10n.editorLyricsHint,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _body,
                                expands: true,
                                minLines: null,
                                maxLines: null,
                                textAlignVertical: TextAlignVertical.top,
                                autocorrect: false,
                                keyboardType: TextInputType.multiline,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      height: 1.55,
                                    ),
                                decoration: InputDecoration(
                                  hintText: l10n.editorLyricsHint,
                                  alignLabelWithHint: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              final fieldWidth = (constraints.maxWidth - 52) / 2;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _field(
                        _title,
                        l10n.editorTitleField,
                        fieldWidth,
                        errorText: titleError,
                      ),
                      _field(_artist, l10n.editorArtistField, fieldWidth),
                      _field(_album, l10n.editorAlbumField, fieldWidth),
                      _field(_key, l10n.editorKeyField, fieldWidth),
                      _field(_capo, l10n.editorCapoField, fieldWidth),
                      _field(_tuning, l10n.editorTuningField, fieldWidth),
                      _field(_tempo, l10n.editorTempoField, fieldWidth),
                      _field(_duration, l10n.editorDurationField, fieldWidth),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Text(
                      l10n.editorLyricsHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextField(
                    controller: _body,
                    minLines: 12,
                    maxLines: 24,
                    textAlignVertical: TextAlignVertical.top,
                    autocorrect: false,
                    keyboardType: TextInputType.multiline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.55,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.editorLyricsHint,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
