import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../library_actions.dart';
import '../verse_ui_state.dart';
import '../widgets/subpage_header.dart';

final _secondsPattern = RegExp(r'^\d+(\.\d+)?$');
final _minutesSecondsPattern = RegExp(r'^\d+:[0-5]?\d(\.\d+)?$');

/// Whether [value] is a duration the song format understands: empty, plain
/// seconds ("225" or "225.5") or minutes and seconds ("3:45"). Anything else
/// would be stored as text and break code that expects a number.
bool isValidEditorDuration(String value) {
  final text = value.trim();
  return text.isEmpty ||
      _secondsPattern.hasMatch(text) ||
      _minutesSecondsPattern.hasMatch(text);
}

/// Whether [value] is empty or a non-negative number (tempo, capo).
bool isValidEditorNumber(String value) {
  final text = value.trim();
  return text.isEmpty || _secondsPattern.hasMatch(text);
}

/// Song editor. Reports unsaved changes through
/// [VerseUiController.setEditorDirty] so the shell can ask before discarding
/// them, and requires a title before saving.
class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });
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
  late String _initialBody;
  bool _templateInitialized = false;
  final _metadataScroll = ScrollController();
  bool _titleMissing = false;
  bool _showFieldErrors = false;
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
    _initialBody = _initial.body;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templateInitialized) return;
    _templateInitialized = true;
    if (!_initial.isNew || _initial.body.isNotEmpty) return;
    final l10n = AppLocalizations.of(context);
    _initialBody = [
      '{start_of_intro}',
      '[C] [G/B] [Am] [F]',
      '{end_of_intro}',
      '',
      '{start_of_verse: 1}',
      l10n.editorExampleVerse,
      '{end_of_verse}',
      '',
      '{start_of_chorus}',
      l10n.editorExampleChorus,
      '{end_of_chorus}',
      '',
      '{start_of_bridge}',
      l10n.editorExampleBridge,
      '{end_of_bridge}',
    ].join('\n');
    // Treat the initial example as a clean draft; opening or changing the
    // locale must never overwrite edits or cause a discard prompt on its own.
    _body.text = _initialBody;
  }

  @override
  void dispose() {
    _metadataScroll.dispose();
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
      _body.text != _initialBody;

  void _onChanged() {
    final dirty = _dirty;
    if (dirty != _reportedDirty) {
      _reportedDirty = dirty;
      widget.controller.setEditorDirty(dirty);
    }
    if (_titleMissing && _title.text.trim().isNotEmpty) {
      setState(() => _titleMissing = false);
    }
    // Re-check the numeric fields as they are corrected after a failed save.
    if (_showFieldErrors) setState(() {});
  }

  // A value that was already stored (and so already unreadable) is not blocked
  // again; only text the person changed must be valid.
  bool _durationInvalid() =>
      _duration.text != _initial.duration &&
      !isValidEditorDuration(_duration.text);
  bool _numberInvalid(TextEditingController field, String initial) =>
      field.text != initial && !isValidEditorNumber(field.text);
  bool get _hasFieldErrors =>
      _durationInvalid() ||
      _numberInvalid(_tempo, _initial.tempo) ||
      _numberInvalid(_capo, _initial.capo);

  String _safeHeader(String value) =>
      value.replaceAll(RegExp(r'[\r\n{}]'), ' ').trim();

  Future<void> _delete() async {
    if (_saving || _initial.isNew || _initial.songId.isEmpty) return;
    setState(() => _saving = true);
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      if (!mounted) return;
      await confirmDeleteSong(context, widget.controller, _initial.songId);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _titleMissing = true);
      return;
    }
    if (_hasFieldErrors) {
      setState(() => _showFieldErrors = true);
      return;
    }
    _saving = true;
    setState(() {});
    // Return to the reader with the full viewport. Keeping the multiline
    // editor focused leaves a landscape phone with too little height for the
    // reader controls while the Android keyboard is still open.
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      // Android can animate the IME out while the saved reader is being built.
      // Let the inset update first so the reader lays out against the full height.
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
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
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  KeyEventResult _handleWindowsKey(FocusNode node, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    if (defaultTargetPlatform == TargetPlatform.windows &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyS &&
        keyboard.isControlPressed &&
        !keyboard.isAltPressed &&
        !keyboard.isMetaPressed &&
        !keyboard.isShiftPressed &&
        ModalRoute.of(context)?.isCurrent != false) {
      unawaited(_save());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  InputDecoration _decoration(
    String label, {
    String? errorText,
    String? hintText,
    bool compact = false,
  }) => InputDecoration(
    labelText: label,
    errorText: errorText,
    hintText: hintText,
    isDense: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: EdgeInsets.symmetric(
      horizontal: compact ? 6 : 10,
      vertical: 12,
    ),
    border: const OutlineInputBorder(),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? errorText,
    String? hintText,
    TextInputType? keyboardType,
    bool numeric = false,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
    textCapitalization: numeric
        ? TextCapitalization.none
        : TextCapitalization.sentences,
    decoration: _decoration(
      label,
      errorText: errorText,
      hintText: hintText,
      compact: true,
    ),
  );

  // An identity-only value cannot collide with imported or entered text.
  static final _customChoice = Object();
  static const _keys = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
    'Cm',
    'C#m',
    'Dm',
    'D#m',
    'Em',
    'Fm',
    'F#m',
    'Gm',
    'G#m',
    'Am',
    'Bbm',
    'Bm',
  ];
  static const _tunings = [
    'E A D G B E',
    'D A D G B E',
    'D G C F A D',
    'C G C F A D',
    'D A D G A D',
    'D G D G B D',
    'D A D F# A D',
    'C G C G C E',
  ];

  Widget _choice(
    TextEditingController controller,
    String label,
    List<String> options, {
    bool tuning = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final values = ['', ...options];
    if (!values.contains(controller.text)) values.add(controller.text);
    String display(String value) {
      if (value.isEmpty) return l10n.playerChordsNone;
      if (tuning && value == _tunings.first) return l10n.editorStandardTuning;
      return !tuning && options.contains(value)
          ? value.replaceAll('#', '♯').replaceAll('b', '♭')
          : value;
    }

    return InputDecorator(
      decoration: _decoration(label, compact: true),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Object>(
          key: ValueKey('editor-${tuning ? 'tuning' : 'key'}-input'),
          value: controller.text,
          isDense: true,
          iconSize: 18,
          isExpanded: true,
          menuMaxHeight: 320,
          items: [
            for (final value in values)
              DropdownMenuItem<Object>(
                value: value,
                child: Text(
                  display(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            DropdownMenuItem<Object>(
              value: _customChoice,
              child: Text(l10n.editorCustomValue),
            ),
          ],
          onChanged: (value) async {
            if (value == null) return;
            if (identical(value, _customChoice)) {
              final entered = await showDialog<String>(
                context: context,
                builder: (_) => _MetadataValueDialog(
                  label: label,
                  initialValue: controller.text,
                ),
              );
              if (!mounted || entered == null) return;
              setState(() => controller.text = entered);
            } else if (value is String) {
              setState(() => controller.text = value);
            }
          },
        ),
      ),
    );
  }

  Widget _row(List<({Widget child, int flex})> fields) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < fields.length; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(flex: fields[index].flex, child: fields[index].child),
      ],
    ],
  );

  Widget _metadata(BuildContext context, double width) {
    final l10n = AppLocalizations.of(context);
    final title = _field(
      _title,
      l10n.editorTitleField,
      errorText: _titleMissing ? l10n.editorFieldRequired : null,
    );
    final artist = _field(_artist, l10n.editorArtistField);
    final album = _field(_album, l10n.editorAlbumField);
    final key = _choice(_key, l10n.editorKeyField, _keys);
    final tuning = _choice(
      _tuning,
      l10n.editorTuningField,
      _tunings,
      tuning: true,
    );
    final capo = _field(
      _capo,
      l10n.editorCapoField,
      numeric: true,
      keyboardType: TextInputType.number,
      errorText: _showFieldErrors && _numberInvalid(_capo, _initial.capo)
          ? l10n.editorNumberInvalid
          : null,
    );
    final tempo = _field(
      _tempo,
      l10n.editorTempoField,
      numeric: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      errorText: _showFieldErrors && _numberInvalid(_tempo, _initial.tempo)
          ? l10n.editorNumberInvalid
          : null,
    );
    final duration = _field(
      _duration,
      l10n.editorDurationField,
      numeric: true,
      keyboardType: TextInputType.datetime,
      hintText: '3:45',
      errorText: _showFieldErrors && _durationInvalid()
          ? l10n.editorDurationInvalid
          : null,
    );
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final comfortableWidth = width / scale.clamp(1.0, 3.0);
    final rows = <Widget>[];
    if (comfortableWidth >= 700) {
      rows.addAll([
        _row([
          (child: title, flex: 4),
          (child: album, flex: 1),
          (child: artist, flex: 4),
        ]),
        _row([
          (child: key, flex: 2),
          (child: tuning, flex: 2),
          (child: capo, flex: 1),
          (child: tempo, flex: 2),
          (child: duration, flex: 2),
        ]),
      ]);
    } else if (comfortableWidth >= 300) {
      rows.addAll([
        _row([(child: title, flex: 2), (child: album, flex: 1)]),
        _row([(child: artist, flex: 2), (child: tuning, flex: 1)]),
        _row([
          (child: key, flex: 4),
          (child: capo, flex: 3),
          (child: tempo, flex: 4),
          (child: duration, flex: 5),
        ]),
      ]);
    } else if (comfortableWidth >= 220) {
      // Give longer labels and large text room instead of shrinking the type.
      rows.addAll([
        title,
        _row([(child: album, flex: 1), (child: artist, flex: 2)]),
        _row([(child: key, flex: 2), (child: tuning, flex: 2)]),
        _row([
          (child: capo, flex: 1),
          (child: tempo, flex: 1),
          (child: duration, flex: 2),
        ]),
      ]);
    } else {
      rows.addAll([
        title,
        album,
        artist,
        key,
        tuning,
        _row([(child: capo, flex: 1), (child: tempo, flex: 1)]),
        duration,
      ]);
    }
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          rows[index],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = Column(
      children: [
        SubpageHeader(
          title: l10n.editorTitle,
          onBack: widget.onBack,
          actions: [
            IconButton(
              tooltip: defaultTargetPlatform == TargetPlatform.windows
                  ? '${l10n.actionSave} (Ctrl+S)'
                  : l10n.actionSave,
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
            ),
            if (!_initial.isNew && _initial.songId.isNotEmpty)
              PopupMenuButton<String>(
                tooltip: l10n.songMenuLabel,
                enabled: !_saving,
                itemBuilder: (_) =>
                    buildLibraryActionMenu(l10n, actions: const {'delete'}),
                onSelected: (_) => _delete(),
              ),
          ],
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .46,
                      ),
                      child: Scrollbar(
                        controller: _metadataScroll,
                        child: SingleChildScrollView(
                          controller: _metadataScroll,
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: _metadata(context, constraints.maxWidth),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('editor-lyrics-input'),
                        controller: _body,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        autocorrect: false,
                        keyboardType: TextInputType.multiline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                        decoration: _decoration(
                          l10n.editorLyricsField,
                          hintText: l10n.editorLyricsHint,
                        ).copyWith(alignLabelWithHint: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return Focus(
      autofocus: defaultTargetPlatform == TargetPlatform.windows,
      onKeyEvent: _handleWindowsKey,
      child: content,
    );
  }
}

class _MetadataValueDialog extends StatefulWidget {
  const _MetadataValueDialog({required this.label, required this.initialValue});
  final String label, initialValue;
  @override
  State<_MetadataValueDialog> createState() => _MetadataValueDialogState();
}

class _MetadataValueDialogState extends State<_MetadataValueDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.actionDone),
        ),
      ],
    );
  }
}
