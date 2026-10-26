import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart';

import '../../domain/arrangement.dart' show transposeChord;
import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../library_actions.dart';
import '../player_section_timeline.dart';
import '../settings/settings_screen.dart' show showPlayerSettings;
import '../verse_ui_state.dart';
import '../widgets/slider_overlay_boundary.dart';
import 'player_lyric_line.dart';
import 'player_controls_panel.dart';
import 'player_fullscreen_header.dart';
import '../widgets/subpage_header.dart';
import 'screen_awake.dart';
import 'section_labels.dart';
import 'speed_slider_track.dart';

const _playerPopupBaseWidth = 96.0;

double _playerPopupWidth(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
  final availableWidth = MediaQuery.sizeOf(context).width - 16;
  return (_playerPopupBaseWidth * textScale)
      .clamp(_playerPopupBaseWidth, availableWidth)
      .toDouble();
}

BoxConstraints _playerPopupConstraints(BuildContext context) =>
    BoxConstraints.tightFor(width: _playerPopupWidth(context));

double _speedPopupPanelHeight(BuildContext context) =>
    (MediaQuery.sizeOf(context).height - 64).clamp(220.0, 292.0).toDouble();

String _formatPlaybackSpeed(double speed) {
  final tenths = speed * 10;
  final isTenth = (tenths - tenths.round()).abs() < 0.000001;
  final value = isTenth
      ? speed.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')
      : speed.toStringAsFixed(2);
  return '$value×';
}

int? _keyPitchClass(String? key) {
  if (key == null) return null;
  final match = RegExp(
    r'^\s*([A-G])([#b♯♭]?)',
    caseSensitive: false,
  ).firstMatch(key);
  if (match == null) return null;
  const pitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
  final accidental = match.group(2);
  return (pitches[match.group(1)!.toUpperCase()]! +
          (accidental == '#' || accidental == '♯'
              ? 1
              : accidental == 'b' || accidental == '♭'
              ? -1
              : 0) +
          12) %
      12;
}

String? _transposeKey(VerseUiState state) {
  // The reader key already includes estimates, setlist overrides and transpose.
  if (_keyPitchClass(state.readerKey) != null) return state.readerKey;
  final savedKey = state.song?.key;
  return _keyPitchClass(savedKey) == null
      ? null
      : transposeChord(savedKey!, state.readerTranspose);
}

const _playerDropdownArrow = Icon(Icons.arrow_drop_up_rounded, size: 20);

/// The lyric reader and player: scrolling lyrics, a seek bar with section
/// markers and transport controls.
///
/// Only this screen listens to the playback position, so one-second ticks and
/// scrubbing rebuild the seek bar and the highlighted line, not the app.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
    this.screenAwake,
    this.fullScreen = false,
    this.onFullScreenChanged,
  }) : assert(!fullScreen || onFullScreenChanged != null);
  final VerseUiController controller;
  final bool fullScreen;
  final ValueChanged<bool>? onFullScreenChanged;

  /// Keeps the display on while playing; [defaultScreenAwake] when null.
  final ScreenAwake? screenAwake;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  final _lyricsScroll = ScrollController();
  final _controlsScroll = ScrollController();
  final _speedPopupAnchorKey = GlobalKey();
  final _lineKeys = <String, GlobalKey>{};
  late ValueListenable<PlayerPosition> _position;
  String? _lastLineId;
  double _speedPopupOffsetX = 0;
  String? _lastSongId;
  String? _currentLineId;
  double _lastProgress = 0;
  bool _instantSeek = false;
  bool _manualLyricsScroll = false;
  Timer? _manualScrollIdle;
  int _selectedIndex = -1;
  List<LyricLineData>? _keyedLines;
  List<(int, double)>? _sectionPoints;
  List<PlayerSectionMarker>? _pointsSections;
  List<LyricLineData>? _pointsLines;
  String? _pointsTimingMode;
  double? _pointsDuration;
  Size? _lastViewportSize;
  double? _lastTextScale;
  VerseUiController get controller => widget.controller;

  bool _userScrolling = false;
  double? _dragValue;
  bool _awakeHeld = false;
  bool _inForeground = true;
  bool _leaving = false;
  double _lyricsHorizontalDragDistance = 0;
  final _lyricsPointers = <int, Offset>{};
  double? _lyricsFontSizeDraft;
  double _lyricsPinchStartDistance = 0;
  double _lyricsPinchStartSize = 24;
  bool _lyricsPinchUsed = false;
  int _lyricsFontSizeRevision = 0;

  double get _lyricsFontSize =>
      _lyricsFontSizeDraft ?? controller.state.lyricsFontSize;

  double get _lyricsPointerDistance {
    final points = _lyricsPointers.values.take(2).toList();
    return points.length == 2 ? (points[0] - points[1]).distance : 0;
  }

  void _startLyricsPinch() {
    // An older asynchronous button save must not clear this gesture's draft.
    _lyricsFontSizeRevision++;
    _lyricsPinchUsed = true;
    _lyricsHorizontalDragDistance = 0;
    _lyricsPinchStartDistance = _lyricsPointerDistance;
    _lyricsPinchStartSize = _lyricsFontSize;
    setState(() {});
  }

  void _lyricsPointerDown(PointerDownEvent event) {
    if (_lyricsPointers.isEmpty) _lyricsPinchUsed = false;
    _lyricsPointers[event.pointer] = event.localPosition;
    if (_lyricsPointers.length == 2) _startLyricsPinch();
  }

  void _lyricsPointerMove(PointerMoveEvent event) {
    if (!_lyricsPointers.containsKey(event.pointer)) return;
    _lyricsPointers[event.pointer] = event.localPosition;
    if (_lyricsPointers.length < 2 || _lyricsPinchStartDistance < 1) return;
    final size =
        (_lyricsPinchStartSize *
                _lyricsPointerDistance /
                _lyricsPinchStartDistance)
            .clamp(18.0, 36.0);
    setState(() => _lyricsFontSizeDraft = size);
  }

  void _lyricsPointerEnd(PointerEvent event) {
    final wasPinching = _lyricsPointers.length >= 2;
    _lyricsPointers.remove(event.pointer);
    if (!wasPinching) return;
    if (_lyricsPointers.length >= 2) {
      _startLyricsPinch();
    } else {
      setState(() {});
      final size = _lyricsFontSizeDraft;
      if (size != null) _saveLyricsFontSize(size);
    }
  }

  void _saveLyricsFontSize(double size) {
    final value = size.clamp(18.0, 36.0);
    final revision = ++_lyricsFontSizeRevision;
    setState(() => _lyricsFontSizeDraft = value);
    unawaited(
      controller.setLyricsFontSize(value).whenComplete(() {
        if (mounted && revision == _lyricsFontSizeRevision) {
          setState(() => _lyricsFontSizeDraft = null);
        }
      }),
    );
  }

  final ValueNotifier<double?> _playbackSpeedDraft = ValueNotifier<double?>(
    null,
  );
  String? _playbackSpeedDraftSongId;
  double? _playbackSpeedDraftDuration;
  VerseUiController? _playbackSpeedDraftController;
  bool _playbackSpeedPointerActive = false;
  bool _playbackSpeedPointerCanceled = false;
  int? _playbackSpeedPointerId;
  int _playbackSpeedDraftRevision = 0;
  int _playbackSpeedInteractionEpoch = 0;

  void _setControlsExpanded(bool expanded) {
    if (controller.state.playerControlsExpanded == expanded) return;
    unawaited(controller.setPlayerControlsExpanded(expanded));
  }

  /// The adapter's resolved duration is shared with its clock and highlighting.
  double _durationOf(VerseUiState state) =>
      state.song?.durationSeconds ?? estimateChartDuration(state.songLines);

  bool _isStandardTuning(String? tuning) {
    if (tuning == null) return false;
    final normalized = tuning.trim().toLowerCase();
    if (const {
      'standard',
      'standard tuning',
      'e standard',
      'e standard tuning',
    }.contains(normalized)) {
      return true;
    }
    final noteList = normalized.replaceFirst(
      RegExp(r'^(?:standard(?:\s+tuning)?|e\s+standard(?:\s+tuning)?)\s*:?\s*'),
      '',
    );
    final notes = RegExp(r'[A-Ga-g][#b♯♭]?')
        .allMatches(noteList)
        .map((match) => match.group(0)!.toUpperCase())
        .join(',');
    return notes == 'E,A,D,G,B,E';
  }

  ScreenAwake get _screenAwake => widget.screenAwake ?? defaultScreenAwake;

  /// Holds the wake lock exactly while the song plays and the app is in front.
  /// Plugin failures (unsupported platform, tests) never reach the player.
  Future<void> _applyWakeLock() async {
    final want = !_leaving && _inForeground && controller.state.isPlaying;
    if (want == _awakeHeld) return;
    _awakeHeld = want;
    try {
      if (want) {
        await _screenAwake.enable();
      } else {
        await _screenAwake.disable();
      }
    } catch (error) {
      debugPrint('Screen wake lock unavailable: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    _applyWakeLock();
  }

  /// Play, or play again from the start when the song has finished.
  Future<void> _playPause() async {
    final state = controller.state;
    final duration = _durationOf(state);
    if (!state.isPlaying &&
        duration > 0 &&
        _position.value.seconds >= duration - .05) {
      _instantSeek = true;
      await controller.seek(0);
    }
    await controller.playPause();
  }

  Future<void> _togglePlayback() async {
    final state = controller.state;
    if (!state.isPlaying) {
      if (!state.autoscroll) await controller.setAutoscroll(true);
      if (state.timingMode == 'manual' ||
          (state.timingMode == 'timed' && !state.readerHasTiming)) {
        await controller.setTimingMode('estimated');
      }
    }
    await _playPause();
  }

  KeyEventResult _handleDesktopKey(FocusNode node, KeyEvent event) {
    if (widget.fullScreen &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        ModalRoute.of(context)?.isCurrent != false) {
      widget.onFullScreenChanged?.call(false);
      return KeyEventResult.handled;
    }
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        isMacOS;
    if (!isDesktop ||
        event is! KeyDownEvent ||
        ModalRoute.of(context)?.isCurrent == false) {
      return KeyEventResult.ignored;
    }
    final focused = FocusManager.instance.primaryFocus?.context;
    // Text entry and focused sliders retain their own keyboard behavior.
    if (focused?.findAncestorStateOfType<EditableTextState>() != null ||
        focused?.findAncestorWidgetOfExactType<Slider>() != null) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final optionSection =
        isMacOS &&
        keyboard.isAltPressed &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed &&
        (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight);
    if (keyboard.isShiftPressed || (keyboard.isAltPressed && !optionSection)) {
      return KeyEventResult.ignored;
    }
    final modified = keyboard.isControlPressed || keyboard.isMetaPressed;
    final key = event.logicalKey;
    if (isMacOS &&
        keyboard.isControlPressed &&
        keyboard.isMetaPressed &&
        key == LogicalKeyboardKey.keyF) {
      widget.onFullScreenChanged?.call(!widget.fullScreen);
      return KeyEventResult.handled;
    }
    if (!isMacOS && !modified && key == LogicalKeyboardKey.f11) {
      widget.onFullScreenChanged?.call(true);
      return KeyEventResult.handled;
    }
    if (!modified && key == LogicalKeyboardKey.space) {
      unawaited(_togglePlayback());
      return KeyEventResult.handled;
    }
    final backward =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp;
    final forward =
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown;
    if (backward || forward) {
      if (optionSection ||
          (!isMacOS && keyboard.isControlPressed && !keyboard.isMetaPressed)) {
        _skipSection(backward ? -1 : 1);
      } else if (modified || keyboard.isAltPressed) {
        return KeyEventResult.ignored;
      } else {
        controller.seek(
          (_position.value.seconds + (backward ? -5 : 5))
              .clamp(0.0, _durationOf(controller.state))
              .toDouble(),
        );
      }
      return KeyEventResult.handled;
    }
    if (!modified &&
        (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end)) {
      controller.seek(
        key == LogicalKeyboardKey.home ? 0 : _durationOf(controller.state),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _shortcutHint(String label, String shortcut) {
    if (shortcut.isEmpty) return label;
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return '$label (${shortcut.replaceFirst('Ctrl+', '⌥')})';
    }
    return defaultTargetPlatform == TargetPlatform.windows
        ? '$label ($shortcut)'
        : label;
  }

  void _skipSection(int direction) {
    final state = controller.state;
    final target = playerSectionSkipTarget(
      markers: state.playerSections,
      progressSeconds: _position.value.seconds,
      durationSeconds: _durationOf(state),
      direction: direction,
    );
    if (target != null) controller.seek(target);
  }

  void _previousTransportAction(VerseUiState state) {
    if (state.activeSetlist != null &&
        (state.playerSections.isEmpty || state.progressSeconds <= 2)) {
      unawaited(controller.previousSong());
      return;
    }
    _skipSection(-1);
  }

  void _nextTransportAction(VerseUiState state) {
    if (state.activeSetlist != null &&
        (state.playerSections.isEmpty ||
            state.progressSeconds >= _durationOf(state) - .05)) {
      unawaited(controller.nextSong());
      return;
    }
    _skipSection(1);
  }

  void _handleLyricsHorizontalDragEnd(DragEndDetails details) {
    final distance = _lyricsHorizontalDragDistance;
    _lyricsHorizontalDragDistance = 0;
    if (_lyricsPinchUsed || controller.state.activeSetlist == null) return;
    final velocity = details.primaryVelocity ?? 0;
    final longEnough = distance.abs() >= 72;
    final quickEnough = distance.abs() >= 32 && velocity.abs() >= 450;
    if (!longEnough && !quickEnough) return;
    if (distance < 0) {
      unawaited(controller.nextSong());
    } else {
      unawaited(controller.previousSong());
    }
  }

  PlayerSectionMarker? _sectionAt(
    List<PlayerSectionMarker> markers,
    double progress,
  ) {
    if (markers.isEmpty) return null;
    return markers.lastWhere(
      (marker) => marker.startSeconds <= progress + .5,
      orElse: () => markers.first,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _position = controller.playerPosition..addListener(_onPosition);
    _lastSongId = controller.state.song?.id;
    _lastProgress = _position.value.seconds;
    _currentLineId = _position.value.currentLineId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewport = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (_lastViewportSize != null &&
        (_lastViewportSize != viewport || _lastTextScale != textScale)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLine(immediate: true);
      });
    }
    _lastViewportSize = viewport;
    _lastTextScale = textScale;
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _clearPlaybackSpeedDraft();
      _lyricsPointers.clear();
      _lyricsFontSizeDraft = null;
      _lyricsFontSizeRevision++;
      _position.removeListener(_onPosition);
      _position = widget.controller.playerPosition..addListener(_onPosition);
    }
    _syncWithPosition();
  }

  void _onPosition() {
    if (!mounted) return;
    final lineId = _position.value.currentLineId;
    if (lineId != _currentLineId) setState(() => _currentLineId = lineId);
    _syncWithPosition();
  }

  /// Resets per-song state and scrolls to the playing line when it changed.
  void _syncWithPosition() {
    final state = controller.state;
    final position = _position.value;
    if (state.song?.id != _lastSongId) {
      _clearPlaybackSpeedDraft();
      _lastSongId = state.song?.id;
      _lastLineId = null;
      _lastProgress = position.seconds;
      _selectedIndex = -1;
      _lineKeys.clear();
    }
    final lineId = position.currentLineId;
    final progressChanged = position.seconds != _lastProgress;
    _lastProgress = position.seconds;
    if (state.autoscroll &&
        lineId != null &&
        (lineId != _lastLineId || (_instantSeek && progressChanged))) {
      _lastLineId = lineId;
      final immediate = _instantSeek;
      _instantSeek = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_manualLyricsScroll) {
          _scrollToCurrentLine(immediate: immediate);
        }
      });
    }
  }

  void _beginManualScroll() {
    _userScrolling = true;
    _manualLyricsScroll = true;
    _manualScrollIdle?.cancel();
  }

  /// Keeps autoscroll from pulling the lyrics back for a moment after the
  /// finger lifts and a fling settles.
  void _endManualScrollSoon() {
    _userScrolling = false;
    _manualScrollIdle?.cancel();
    _manualScrollIdle = Timer(const Duration(milliseconds: 700), () {
      _manualLyricsScroll = false;
    });
  }

  /// Follows the person's own scrolling - drags, flings that carry on after
  /// release, and wheel or scrollbar moves - and, when autoscroll is on, moves
  /// the playback position to the line in the middle. Autoscroll never fights
  /// it; with autoscroll off the lyrics scroll freely without seeking.
  bool _seekShortChartEndpoint(double delta) {
    if (delta == 0 || !_lyricsScroll.hasClients || !controller.state.autoscroll)
      return false;
    final metrics = _lyricsScroll.position;
    if (metrics.maxScrollExtent - metrics.minScrollExtent > .5) return false;
    final state = controller.state;
    final index = delta > 0
        ? state.songLines.lastIndexWhere((line) => line.text.trim().isNotEmpty)
        : state.songLines.indexWhere((line) => line.text.trim().isNotEmpty);
    if (index < 0) return false;
    _beginManualScroll();
    controller.seek(_progressForLineIndex(index, state));
    _endManualScrollSoon();
    return true;
  }

  bool _handleLyricsScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _endManualScrollSoon();
      } else {
        _beginManualScroll();
      }
      return false;
    }
    if (notification is OverscrollNotification &&
        _seekShortChartEndpoint(notification.overscroll))
      return false;
    if (notification is! ScrollUpdateNotification) return false;
    if (notification.dragDetails != null) _beginManualScroll();
    if (!_userScrolling) return false;
    final state = controller.state;
    if (state.songLines.isEmpty || !state.autoscroll) return false;

    final selectedIndex = _lineNearestCenter(notification, state.songLines);
    if (selectedIndex >= 0) {
      _selectedIndex = selectedIndex;
      final target = _progressForLineIndex(selectedIndex, state);
      if ((target - _position.value.seconds).abs() >= .25) {
        controller.seek(target);
      }
    }
    return false;
  }

  /// Finds the line closest to the viewport center. Lines move monotonically
  /// down the screen, so the search starts at the previous result and walks
  /// toward the center instead of measuring every line on every event.
  int _lineNearestCenter(
    ScrollUpdateNotification notification,
    List<LyricLineData> lines,
  ) {
    final metrics = notification.metrics;
    // The first/last lyric must remain reachable even when the viewport is
    // taller than the chart or the center falls in trailing whitespace.
    if (metrics.pixels <= metrics.minScrollExtent + .5) {
      final first = lines.indexWhere((line) => line.text.trim().isNotEmpty);
      return first < 0 ? 0 : first;
    }
    if (metrics.pixels >= metrics.maxScrollExtent - .5) {
      final last = lines.lastIndexWhere((line) => line.text.trim().isNotEmpty);
      return last < 0 ? lines.length - 1 : last;
    }
    final fractionIndex = metrics.maxScrollExtent > 0
        ? ((metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0) *
                  (lines.length - 1))
              .round()
        : -1;
    final viewport = notification.context?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize) {
      return fractionIndex;
    }
    final top = viewport.localToGlobal(Offset.zero).dy;
    final center = top + viewport.size.height / 2;

    /// Signed distance from the viewport center, or null if not built.
    double? offsetAt(int index) {
      final render = _lineKeys[lines[index].id]?.currentContext
          ?.findRenderObject();
      if (render is! RenderBox || !render.attached || !render.hasSize) {
        return null;
      }
      return render.localToGlobal(Offset(0, render.size.height / 2)).dy -
          center;
    }

    var index = _selectedIndex >= 0 && _selectedIndex < lines.length
        ? _selectedIndex
        : (fractionIndex < 0 ? 0 : fractionIndex);
    var found = offsetAt(index);
    if (found == null && fractionIndex >= 0) {
      index = fractionIndex;
      found = offsetAt(index);
    }
    if (found == null) return fractionIndex;
    var offset = found;
    while (true) {
      final next = index + (offset > 0 ? -1 : 1);
      if (next < 0 || next >= lines.length) break;
      final nextOffset = offsetAt(next);
      if (nextOffset == null || nextOffset.abs() >= offset.abs()) break;
      index = next;
      offset = nextOffset;
    }
    return offset.abs() <= viewport.size.height / 2 ? index : fractionIndex;
  }

  double _progressForLineIndex(int lineIndex, VerseUiState state) {
    final lines = state.songLines;
    if (lines.length < 2) return 0;
    final duration = _durationOf(state);
    if (!identical(_pointsSections, state.playerSections) ||
        !identical(_pointsLines, lines) ||
        _pointsTimingMode != state.timingMode ||
        _pointsDuration != duration) {
      _pointsSections = state.playerSections;
      _pointsLines = lines;
      _pointsTimingMode = state.timingMode;
      _pointsDuration = duration;
      final estimated = state.timingMode == 'estimated'
          ? estimatedLineStartTimes(lines, duration)
          : const <String, double>{};
      _sectionPoints =
          state.timingMode == 'estimated'
                ? [
                    for (var index = 0; index < lines.length; index++)
                      if (estimated[lines[index].id] case final seconds?)
                        (index, seconds),
                  ]
                : state.playerSections
                      .map(
                        (marker) => (
                          lines.indexWhere((line) => line.id == marker.lineId),
                          marker.startSeconds,
                        ),
                      )
                      .where((point) => point.$1 >= 0)
                      .toList()
            ..sort((a, b) => a.$1.compareTo(b.$1));
    }
    var beforeIndex = 0;
    var beforeTime = 0.0;
    var afterIndex = lines.length - 1;
    var afterTime = duration;
    for (final point in _sectionPoints!) {
      if (point.$1 <= lineIndex) {
        beforeIndex = point.$1;
        beforeTime = point.$2;
      } else {
        afterIndex = point.$1;
        afterTime = point.$2;
        break;
      }
    }
    if (afterIndex <= beforeIndex) return beforeTime.clamp(0, duration);
    final fraction = (lineIndex - beforeIndex) / (afterIndex - beforeIndex);
    return (beforeTime + (afterTime - beforeTime) * fraction).clamp(
      0.0,
      duration,
    );
  }

  void _scrollToCurrentLine({bool immediate = false}) {
    if (!mounted || _lyricsPointers.length >= 2) return;
    final state = controller.state;
    final lineId = _position.value.currentLineId;
    if (!state.autoscroll || lineId == null) return;
    final lineContext = _lineKeys[lineId]?.currentContext;
    if (lineContext != null) {
      Scrollable.ensureVisible(
        lineContext,
        duration: immediate ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        alignment: .4,
      );
    } else if (_lyricsScroll.hasClients) {
      final index = state.songLines.indexWhere((line) => line.id == lineId);
      if (index < 0) return;
      final width = MediaQuery.sizeOf(context).width.clamp(0.0, 960.0) - 56;
      final fontSize = _lyricsFontSizeDraft ?? state.lyricsFontSize;
      final charsPerRow = (width / (fontSize * .52)).floor().clamp(12, 120);
      var estimatedOffset = 18.0;
      for (final line in state.songLines.take(index)) {
        if (line.isBlank) {
          estimatedOffset += 15;
        } else if (line.section != null) {
          estimatedOffset += 44;
        } else {
          final wraps = (line.text.characters.length / charsPerRow)
              .ceil()
              .clamp(1, 40);
          estimatedOffset += wraps * fontSize * 1.35 + 12;
        }
      }
      final target =
          (estimatedOffset - _lyricsScroll.position.viewportDimension * .4)
              .clamp(0, _lyricsScroll.position.maxScrollExtent)
              .toDouble();
      final scroll = immediate
          ? Future<void>.sync(() => _lyricsScroll.jumpTo(target))
          : _lyricsScroll.animateTo(
              target,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOut,
            );
      scroll.then((_) {
        if (!mounted) return;
        final targetContext = _lineKeys[lineId]?.currentContext;
        if (targetContext != null && targetContext.mounted) {
          Scrollable.ensureVisible(
            targetContext,
            duration: immediate
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: .4,
          );
          return;
        }
        // The text-based estimate missed (wrapping differs from the guess), so
        // place the line by its share of the measured scroll extent and then
        // align it precisely once it has been built.
        if (!_lyricsScroll.hasClients || state.songLines.isEmpty) return;
        final position = _lyricsScroll.position;
        final share = (index + .5) / state.songLines.length;
        final refined =
            (share * (position.maxScrollExtent + position.viewportDimension) -
                    position.viewportDimension * .4)
                .clamp(0.0, position.maxScrollExtent);
        _lyricsScroll.jumpTo(refined);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final built = _lineKeys[lineId]?.currentContext;
          if (mounted && built != null && built.mounted) {
            Scrollable.ensureVisible(
              built,
              duration: Duration.zero,
              alignment: .4,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaving = true;
    _applyWakeLock();
    _position.removeListener(_onPosition);
    _manualScrollIdle?.cancel();
    _lyricsScroll.dispose();
    _controlsScroll.dispose();
    _playbackSpeedDraft.dispose();
    super.dispose();
  }

  /// Drops keys of lines that no longer exist (another song, edited lyrics).
  void _pruneLineKeys(List<LyricLineData> lines) {
    if (identical(_keyedLines, lines)) return;
    _keyedLines = lines;
    final ids = {for (final line in lines) line.id};
    _lineKeys.removeWhere((id, _) => !ids.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final l10n = AppLocalizations.of(context);
    final song = state.song;
    if (song == null) return const SizedBox.shrink();
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    _schedulePopupOffset(_speedPopupAnchorKey, alignRight: !isRtl);
    unawaited(_applyWakeLock());
    _pruneLineKeys(state.songLines);
    final duration = _durationOf(state);
    final colors = Theme.of(context).colorScheme;
    Widget playerPanel(
      Widget child, {
      required bool header,
      bool side = false,
    }) => DecoratedBox(
      key: ValueKey(header ? 'player-header-panel' : 'player-controls-panel'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: header
            ? Border(bottom: BorderSide(color: colors.outlineVariant))
            : BorderDirectional(
                top: BorderSide(color: colors.outlineVariant),
                start: side
                    ? BorderSide(color: colors.outlineVariant)
                    : BorderSide.none,
              ),
      ),
      child: child,
    );
    final desktopFontControls = switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };
    Widget lyrics() => Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent)
          _seekShortChartEndpoint(event.scrollDelta.dy);
      },
      onPointerDown: _lyricsPointerDown,
      onPointerMove: _lyricsPointerMove,
      onPointerUp: _lyricsPointerEnd,
      onPointerCancel: _lyricsPointerEnd,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: state.activeSetlist == null
            ? null
            : (_) => _lyricsHorizontalDragDistance = 0,
        onHorizontalDragUpdate: state.activeSetlist == null
            ? null
            : (details) => _lyricsHorizontalDragDistance += details.delta.dx,
        onHorizontalDragEnd: state.activeSetlist == null
            ? null
            : _handleLyricsHorizontalDragEnd,
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                key: const ValueKey('tablet-reader-content'),
                builder: (context, constraints) {
                  final centeredInset = math.max(
                    0.0,
                    (constraints.maxWidth - 960) / 2,
                  );
                  // Keep the text column centered, but let the scroll viewport
                  // and its single scrollbar reach the outside of the pane.
                  return Scrollbar(
                    key: const ValueKey('player-lyrics-scrollbar'),
                    controller: _lyricsScroll,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleLyricsScroll,
                        child: ListView.builder(
                          key: const ValueKey('player-lyrics-scroll'),
                          controller: _lyricsScroll,
                          physics: _lyricsPointers.length >= 2
                              ? const NeverScrollableScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsetsDirectional.fromSTEB(
                            centeredInset + 28,
                            widget.fullScreen ? 0 : 18,
                            centeredInset + 28,
                            // Let the final lyric reach the same center anchor
                            // used to select playback position while scrolling.
                            state.autoscroll
                                ? math.max(32.0, constraints.maxHeight / 2)
                                : 32,
                          ),
                          itemCount: state.songLines.length,
                          itemBuilder: (context, index) => _lyricLine(
                            context,
                            state,
                            state.songLines[index],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Material(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (desktopFontControls) ...[
                      IconButton(
                        key: const ValueKey('player-decrease-font-size'),
                        tooltip: '${l10n.settingsTextSize} −',
                        onPressed: _lyricsFontSize <= 18
                            ? null
                            : () => _saveLyricsFontSize(_lyricsFontSize - 2),
                        icon: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('A'),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('player-increase-font-size'),
                        tooltip: '${l10n.settingsTextSize} +',
                        onPressed: _lyricsFontSize >= 36
                            ? null
                            : () => _saveLyricsFontSize(_lyricsFontSize + 2),
                        icon: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('A'),
                            Icon(Icons.keyboard_arrow_up_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                    if (widget.onFullScreenChanged != null)
                      IconButton(
                        key: ValueKey(
                          widget.fullScreen
                              ? 'player-exit-fullscreen'
                              : 'player-enter-fullscreen',
                        ),
                        constraints: const BoxConstraints.tightFor(
                          width: 48,
                          height: 48,
                        ),
                        tooltip: widget.fullScreen
                            ? l10n.playerExitFullScreen
                            : l10n.playerFullScreen,
                        onPressed: () => widget.onFullScreenChanged?.call(
                          !widget.fullScreen,
                        ),
                        icon: Icon(
                          widget.fullScreen
                              ? Icons.close_fullscreen_rounded
                              : Icons.open_in_full_rounded,
                        ),
                      ),
                    IconButton(
                      key: const ValueKey('player-settings-button'),
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      tooltip: l10n.settingsPlayer,
                      onPressed: () => showPlayerSettings(context, controller),
                      icon: const Icon(Icons.settings_outlined, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Widget controls({
      required bool compact,
      double? maxHeight,
    }) => LayoutBuilder(
      builder: (context, controlConstraints) {
        final style = DefaultTextStyle.of(
          context,
        ).style.copyWith(fontSize: 20, fontWeight: FontWeight.w600);
        Size labelSize(String label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: Localizations.localeOf(context),
          )..layout();
          final size = Size(
            painter.width.ceilToDouble() + 2,
            painter.height.ceilToDouble() + 2,
          );
          painter.dispose();
          return size;
        }

        final keySize = labelSize(
          state.showChords
              ? _transposeKey(state) ?? l10n.unknownValue
              : l10n.searchChordsUnavailable,
        );
        final speedSize = labelSize(_formatPlaybackSpeed(state.playbackSpeed));
        final sideWidth = math.max(
          64.0,
          math.max(keySize.width, speedSize.width) + 36,
        );
        final hasNavigation =
            state.playerSections.isNotEmpty || state.activeSetlist != null;
        final playPainter = TextPainter(
          text: TextSpan(
            text: state.isPlaying ? l10n.playerPause : l10n.playerPlay,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(height: kTextHeightNone),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
        )..layout();
        final playWidth = math.max(
          104.0,
          playPainter.width.ceilToDouble() + 48,
        );
        // Keep the compact row at least 48 dp, but let actual font metrics
        // grow it for large text and fallback scripts instead of clipping.
        final rowHeight = math.max(
          48.0,
          math.max(
            math.max(keySize.height, speedSize.height),
            playPainter.height.ceilToDouble() + 8,
          ),
        );
        playPainter.dispose();
        final minimumWidth =
            sideWidth * 2 + (hasNavigation ? 80 : 0) + playWidth + 8;
        final stackActions =
            compact && minimumWidth > controlConstraints.maxWidth;
        final stackedMinimumWidth =
            math.max(sideWidth * 2, (hasNavigation ? 96.0 : 0.0) + playWidth) +
            8;
        final rowWidth = math.max(
          controlConstraints.maxWidth,
          stackActions ? stackedMinimumWidth : minimumWidth,
        );
        final transport = SizedBox(
          width: rowWidth,
          height: rowHeight * (stackActions ? 2 : 1),
          child: _transport(
            context,
            l10n,
            state,
            inlineChords: song.hasChords,
            showSpeed: true,
            stackActions: stackActions,
            rowHeight: rowHeight,
            sideSlotWidth: sideWidth,
            chordSlotWidth: sideWidth,
          ),
        );
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<PlayerPosition>(
              valueListenable: _position,
              builder: (context, position, _) =>
                  _seekBar(context, l10n, state, position, duration),
            ),
            // Stack narrow landscape controls before using horizontal scroll
            // as a fallback for panes too small even for the two-row layout.
            if (rowWidth > controlConstraints.maxWidth)
              SingleChildScrollView(
                key: const ValueKey('player-transport-horizontal-scroll'),
                scrollDirection: Axis.horizontal,
                child: transport,
              )
            else
              transport,
          ],
        );
        final canScroll = compact || maxHeight != null;
        final body = canScroll
            ? ConstrainedBox(
                constraints: maxHeight == null
                    ? const BoxConstraints()
                    : BoxConstraints(maxHeight: maxHeight),
                child: Scrollbar(
                  controller: _controlsScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _controlsScroll,
                    reverse: true,
                    child: content,
                  ),
                ),
              )
            : content;
        return playerPanel(
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [if (compact) Flexible(child: body) else body],
            ),
          ),
          header: false,
          side: compact,
        );
      },
    );

    final metadata = [
      if (state.readerKey != null && !state.readerKeyEstimated)
        '${l10n.editorKeyField}: ${state.readerKey}',
      song.artist,
      song.album,
      if (state.readerCapo != null)
        '${l10n.editorCapoField}: ${state.readerCapo}',
      if (state.readerTuning != null && !_isStandardTuning(state.readerTuning))
        '${l10n.editorTuningField}: ${state.readerTuning}',
      if (state.readerTempo != null)
        '${l10n.editorTempoField}: ${state.readerTempo}',
    ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');

    List<Widget> songActions() => [
      IconButton(
        tooltip: song.favorite ? l10n.songFavoriteRemove : l10n.songFavoriteAdd,
        onPressed: () => controller.toggleSongFavorite(song.id),
        icon: Icon(
          song.favorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
        ),
      ),
      if (widget.onFullScreenChanged == null)
        IconButton(
          tooltip: l10n.actionEdit,
          onPressed: () => controller.editSong(song.id),
          icon: const Icon(Icons.edit_outlined),
        ),
      PopupMenuButton<String>(
        tooltip: l10n.songMenuLabel,
        icon: const Icon(Icons.more_horiz_rounded),
        itemBuilder: (_) => [
          ...buildLibraryActionMenu(
            l10n,
            timedLyricsChecked: state.timingMode == 'timed',
            actions: {
              ...songLibraryActions,
              if (state.readerCanCompareVersions) 'compare',
              if (state.readerTimingAvailable || state.readerHasTiming)
                'timed-lyrics',
            },
          ),
        ],
        onSelected: (action) {
          if (action == 'compare') {
            controller.compareCurrentSongVersions();
          } else if (action == 'timed-lyrics') {
            controller.setTimingMode(
              state.timingMode == 'timed' ? 'estimated' : 'timed',
            );
          } else {
            handleSongMenuAction(context, controller, song.id, action);
          }
        },
      ),
    ];

    Widget landscapeHeader() => SafeArea(
      left: true,
      right: true,
      top: false,
      bottom: false,
      child: PlayerFullscreenHeader(
        key: const ValueKey('player-landscape-header'),
        title: song.title,
        artist: song.artist,
        actions: widget.fullScreen
            ? const <Widget>[]
            : [
                IconButton(
                  tooltip: l10n.navBack,
                  onPressed: controller.back,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                ...songActions(),
              ],
      ),
    );

    Widget songHeader() {
      if (widget.fullScreen) {
        return PlayerFullscreenHeader(
          title: song.title,
          artist: song.artist,
          actions: const [],
        );
      }
      return playerPanel(
        Column(
          children: [
            SubpageHeader(
              title: song.title,
              onBack: controller.back,
              actions: songActions(),
            ),
            if (metadata.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (state.readerSource?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    state.readerSource!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        header: true,
        side: false,
      );
    }

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final compactLandscape =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 480;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        final shortPortrait =
            constraints.maxHeight < 600 &&
            constraints.maxWidth <= constraints.maxHeight;
        return Column(
          children: [
            if (!widget.fullScreen)
              if (compactLandscape) landscapeHeader() else songHeader(),
            Expanded(
              child: PlayerControlsPanel(
                expanded: !widget.fullScreen && state.playerControlsExpanded,
                hideHandle: widget.fullScreen,
                onChanged: _setControlsExpanded,
                expandLabel: l10n.playerExpandControls,
                collapseLabel: l10n.playerCollapseControls,
                side: compactLandscape,
                sideHeader: null,
                sideWidth: compactLandscape
                    ? (constraints.maxWidth * .4).clamp(200.0, 360.0).toDouble()
                    : null,
                collapsedAction: null,
                lyrics: lyrics(),
                controls: compactLandscape
                    ? SizedBox(
                        width: (constraints.maxWidth * .4)
                            .clamp(200.0, 360.0)
                            .toDouble(),
                        child: controls(compact: true),
                      )
                    : controls(
                        compact: false,
                        maxHeight: largeText || shortPortrait
                            ? (constraints.maxHeight * .4)
                                  .clamp(180.0, 320.0)
                                  .toDouble()
                            : null,
                      ),
              ),
            ),
          ],
        );
      },
    );
    return Focus(
      key: const ValueKey('player-keyboard-focus'),
      autofocus:
          widget.fullScreen ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux,
      onKeyEvent: _handleDesktopKey,
      child: Column(
        children: [
          Expanded(key: const ValueKey('player-body'), child: content),
        ],
      ),
    );
  }

  void _schedulePopupOffset(GlobalKey anchorKey, {required bool alignRight}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = anchorKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      final screenWidth = MediaQuery.sizeOf(context).width;
      const inset = 8.0;
      final offset = alignRight
          ? screenWidth - inset - rect.right
          : inset - rect.left;
      final current = _speedPopupOffsetX;
      if ((offset - current).abs() < .5) return;
      setState(() {
        _speedPopupOffsetX = offset;
      });
    });
  }

  Widget _lyricLine(
    BuildContext context,
    VerseUiState state,
    LyricLineData line,
  ) {
    final theme = Theme.of(context);
    final key = _lineKeys.putIfAbsent(line.id, GlobalKey.new);
    if (line.section != null && line.text.trim().isEmpty) {
      if (!state.showSections) return SizedBox.shrink(key: key);
      return Padding(
        key: key,
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          localizedSectionName(
            AppLocalizations.of(context),
            line.section!.replaceAll(RegExp(r'[\[\]{}:]'), ''),
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (line.isBlank) return SizedBox(height: 15, key: key);
    final current = _currentLineId == line.id;
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: PlayerLyricLine(
        line: line,
        state: state,
        current: current,
        fontSize: _lyricsFontSizeDraft ?? state.lyricsFontSize,
      ),
    );
  }

  Widget _seekBar(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
    PlayerPosition position,
    double duration,
  ) {
    final speed = state.playbackSpeed;
    final displayDuration = duration / speed;
    final displayPosition = position.seconds / speed;
    final displaySections = [
      for (final marker in state.playerSections)
        PlayerSectionMarker(
          name: marker.name,
          lineId: marker.lineId,
          startSeconds: marker.startSeconds / speed,
        ),
    ];
    final maxValue = displayDuration > 0 ? displayDuration : 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: _SectionMarkerSliderTrackShape(
              markers: displaySections,
              durationSeconds: displayDuration,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktopTimeline = constraints.maxWidth >= 560;
              final compactDesktopTimeline =
                  desktopTimeline &&
                  (defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.linux);
              final sliderTheme = SliderTheme.of(context);
              return SizedBox(
                height: desktopTimeline && !compactDesktopTimeline ? 64 : 48,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: desktopTimeline ? 16 : 0,
                      child: SliderOverlayBoundary(
                        child: Slider(
                          key: const ValueKey('player-seek-slider'),
                          min: 0,
                          max: maxValue,
                          // While the thumb is held, clock ticks must not move it.
                          value: (_dragValue ?? displayPosition)
                              .clamp(0, maxValue)
                              .toDouble(),
                          semanticFormatterCallback: (value) {
                            final sourceSection = _sectionAt(
                              state.playerSections,
                              value * speed,
                            );
                            return '${sourceSection == null ? l10n.playerCurrentSection : localizedSectionName(l10n, sourceSection.name)}, '
                                '${formatDuration(value)}';
                          },
                          onChangeStart: (value) => _dragValue = value,
                          onChanged: (value) {
                            _dragValue = value;
                            _instantSeek = true;
                            controller.seek(value * speed);
                          },
                          onChangeEnd: (_) => _dragValue = null,
                        ),
                      ),
                    ),
                    ..._sectionMarkerLabelWidgets(
                      context: context,
                      markers: displaySections,
                      durationSeconds: displayDuration,
                      progressSeconds: displayPosition,
                      width: constraints.maxWidth,
                      textDirection: Directionality.of(context),
                      labelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      sliderTheme: sliderTheme,
                      textScaler: MediaQuery.textScalerOf(context),
                      l10n: l10n,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final times = Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(formatDuration(displayPosition)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Semantics(
                        label: state.readerDurationEstimated
                            ? l10n.playerEstimatedDuration(
                                formatDuration(displayDuration),
                              )
                            : formatDuration(displayDuration),
                        child: ExcludeSemantics(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(formatDuration(displayDuration)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
              return times;
            },
          ),
        ),
      ],
    );
  }

  Widget _speedControl(AppLocalizations l10n, VerseUiState state) {
    final popupWidth = _playerPopupWidth(context);
    final panelHeight = _speedPopupPanelHeight(context);
    final labelWidth = (popupWidth * .43).clamp(34.0, 68.0).toDouble();
    return KeyedSubtree(
      key: _speedPopupAnchorKey,
      child: PopupMenuButton<double>(
        key: const ValueKey('scroll-speed-toggle'),
        tooltip: l10n.playerScrollSpeed,
        position: PopupMenuPosition.over,
        offset: Offset(_speedPopupOffsetX, -(panelHeight + 14)),
        constraints: _playerPopupConstraints(context),
        menuPadding: EdgeInsets.zero,
        onCanceled: _clearPlaybackSpeedDraft,
        itemBuilder: (_) => [
          SliderPopupMenuItem<double>(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: SizedBox(
              key: const ValueKey('scroll-speed-panel'),
              width: popupWidth - 8,
              height: panelHeight,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) => ValueListenableBuilder<double?>(
                  valueListenable: _playbackSpeedDraft,
                  builder: (context, draftSpeed, _) {
                    final currentState = controller.state;
                    final duration = _durationOf(currentState);
                    final speed = draftSpeed ?? controller.state.playbackSpeed;
                    final interactionEpoch = _playbackSpeedInteractionEpoch;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 2,
                            children: [
                              Semantics(
                                label: currentState.readerDurationEstimated
                                    ? l10n.playerEstimatedDuration(
                                        formatDuration(duration / speed),
                                      )
                                    : formatDuration(duration / speed),
                                child: ExcludeSemantics(
                                  child: Text(
                                    formatDuration(duration / speed),
                                    key: const ValueKey(
                                      'scroll-speed-duration',
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: labelWidth,
                                height: double.infinity,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('2×'),
                                    Text('1.5×'),
                                    Text('1×'),
                                    Text('0.5×'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      overlayShape:
                                          SliderComponentShape.noOverlay,
                                      trackShape:
                                          const FineSpeedSliderTrackShape(),
                                      inactiveTickMarkColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: .55),
                                      activeTickMarkColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                    child: Listener(
                                      onPointerDown:
                                          _onPlaybackSpeedPointerDown,
                                      onPointerUp: _onPlaybackSpeedPointerUp,
                                      onPointerCancel:
                                          _onPlaybackSpeedPointerCancel,
                                      child: Slider(
                                        key: const ValueKey(
                                          'scroll-speed-slider',
                                        ),
                                        min: .5,
                                        max: 2,
                                        value: speed,
                                        label: _formatPlaybackSpeed(speed),
                                        semanticFormatterCallback: (value) {
                                          final durationLabel = formatDuration(
                                            duration / value,
                                          );
                                          final accessibleDuration =
                                              currentState
                                                  .readerDurationEstimated
                                              ? l10n.playerEstimatedDuration(
                                                  durationLabel,
                                                )
                                              : durationLabel;
                                          return '${l10n.playerScrollSpeed}, ${_formatPlaybackSpeed(value)}, $accessibleDuration';
                                        },
                                        onChangeStart: (value) {
                                          if (interactionEpoch !=
                                              _playbackSpeedInteractionEpoch) {
                                            return;
                                          }
                                          _beginPlaybackSpeedDraft(value);
                                        },
                                        onChanged: (value) {
                                          if (interactionEpoch !=
                                              _playbackSpeedInteractionEpoch) {
                                            return;
                                          }
                                          _updatePlaybackSpeedDraft(value);
                                        },
                                        onChangeEnd: (value) {
                                          if (interactionEpoch !=
                                              _playbackSpeedInteractionEpoch) {
                                            return;
                                          }
                                          _commitPlaybackSpeedDraft(value);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        child: ValueListenableBuilder<double?>(
          valueListenable: _playbackSpeedDraft,
          builder: (context, draftSpeed, _) {
            // Preview the same ratio as the popup throughout the gesture.
            // The existing completion/cancel handlers still own persistence.
            final speed = _playbackSpeedDraftIsCurrent()
                ? draftSpeed!
                : state.playbackSpeed;
            final label = _formatPlaybackSpeed(speed);
            return Semantics(
              key: const ValueKey('scroll-speed-toggle-label'),
              label: '${l10n.playerScrollSpeed}, $label',
              button: true,
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          key: const ValueKey('scroll-speed-value'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          softWrap: false,
                        ),
                        _playerDropdownArrow,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _beginPlaybackSpeedDraft(double speed) {
    if (!mounted) return;
    _playbackSpeedPointerCanceled = false;
    _playbackSpeedDraftRevision++;
    final state = controller.state;
    _playbackSpeedDraftController = controller;
    _playbackSpeedDraftSongId = state.song?.id;
    _playbackSpeedDraftDuration = _durationOf(state);
    _playbackSpeedDraft.value = speed;
  }

  void _onPlaybackSpeedPointerDown(PointerDownEvent event) {
    if (_playbackSpeedPointerActive &&
        event.pointer != _playbackSpeedPointerId) {
      return;
    }
    _playbackSpeedPointerId = event.pointer;
    _playbackSpeedPointerActive = true;
    _playbackSpeedPointerCanceled = false;
  }

  void _onPlaybackSpeedPointerUp(PointerUpEvent event) {
    if (event.pointer != _playbackSpeedPointerId) return;
    _playbackSpeedPointerId = null;
    _playbackSpeedPointerActive = false;
  }

  void _onPlaybackSpeedPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _playbackSpeedPointerId) return;
    _playbackSpeedPointerId = null;
    _playbackSpeedPointerActive = false;
    _playbackSpeedPointerCanceled = true;
    _clearPlaybackSpeedDraft(preservePointerCancellation: true);
  }

  bool _playbackSpeedDraftIsCurrent() {
    final state = controller.state;
    return _playbackSpeedDraft.value != null &&
        identical(_playbackSpeedDraftController, controller) &&
        _playbackSpeedDraftSongId == state.song?.id &&
        _playbackSpeedDraftDuration == _durationOf(state);
  }

  void _updatePlaybackSpeedDraft(double speed) {
    if (_playbackSpeedPointerCanceled) return;
    if (_playbackSpeedDraft.value == null) {
      _beginPlaybackSpeedDraft(speed);
      if (!_playbackSpeedPointerActive) _commitPlaybackSpeedDraft(speed);
      return;
    }
    if (!_playbackSpeedDraftIsCurrent()) {
      _clearPlaybackSpeedDraft();
      return;
    }
    _playbackSpeedDraft.value = speed;
    if (!_playbackSpeedPointerActive) _commitPlaybackSpeedDraft(speed);
  }

  void _clearPlaybackSpeedDraft({bool preservePointerCancellation = false}) {
    final revision = ++_playbackSpeedDraftRevision;
    _playbackSpeedInteractionEpoch++;
    _playbackSpeedDraftSongId = null;
    _playbackSpeedDraftDuration = null;
    _playbackSpeedDraftController = null;
    _playbackSpeedPointerId = null;
    if (!preservePointerCancellation) {
      _playbackSpeedPointerActive = false;
      _playbackSpeedPointerCanceled = false;
    }

    void clearVisualDraft() {
      if (!mounted || revision != _playbackSpeedDraftRevision) return;
      if (_playbackSpeedDraft.value != null) _playbackSpeedDraft.value = null;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => clearVisualDraft());
    } else {
      clearVisualDraft();
    }
  }

  void _commitPlaybackSpeedDraft(double speed) {
    if (_playbackSpeedPointerCanceled || !_playbackSpeedDraftIsCurrent()) {
      _clearPlaybackSpeedDraft();
      return;
    }
    if (_playbackSpeedPointerActive) {
      final revision = _playbackSpeedDraftRevision;
      scheduleMicrotask(() {
        if (!mounted || revision != _playbackSpeedDraftRevision) return;
        if (_playbackSpeedPointerCanceled || !_playbackSpeedDraftIsCurrent()) {
          _clearPlaybackSpeedDraft();
          return;
        }
        _finishPlaybackSpeedDraft(speed);
      });
      return;
    }
    _finishPlaybackSpeedDraft(speed);
  }

  void _finishPlaybackSpeedDraft(double speed) {
    if (!_playbackSpeedDraftIsCurrent()) {
      _clearPlaybackSpeedDraft();
      return;
    }
    _clearPlaybackSpeedDraft();
    unawaited(controller.setPlaybackSpeed(speed));
  }

  Widget _transport(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state, {
    required bool inlineChords,
    required bool showSpeed,
    required bool stackActions,
    required double rowHeight,
    required double sideSlotWidth,
    required double chordSlotWidth,
    Widget? trailingAction,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final isRtl = direction == TextDirection.rtl;
        final hasNavigation =
            state.playerSections.isNotEmpty || state.activeSetlist != null;
        final hasActionSlot = showSpeed || trailingAction != null;
        final centerWidth = stackActions
            ? constraints.maxWidth
            : constraints.maxWidth - (sideSlotWidth * 2);
        final playLabel = state.isPlaying ? l10n.playerPause : l10n.playerPlay;
        final playLabelPainter = TextPainter(
          text: TextSpan(
            text: playLabel,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(height: kTextHeightNone),
          ),
          textDirection: direction,
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
        )..layout();
        final navigationWidth = stackActions ? 96.0 : 80.0;
        final playWidth = centerWidth - (hasNavigation ? navigationWidth : 0);
        final playHorizontalPadding =
            ((playWidth - 32 - playLabelPainter.width) / 2)
                .clamp(4.0, 12.0)
                .toDouble();
        playLabelPainter.dispose();
        final start = FilledButton.icon(
          key: const ValueKey('start-lyric-scroll'),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: playHorizontalPadding,
              vertical: 4,
            ),
            minimumSize: Size(104, rowHeight),
            visualDensity: stackActions ? VisualDensity.standard : null,
          ),
          onPressed: _togglePlayback,
          icon: Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            playLabel,
            // Natural metrics preserve tall fallback-script glyphs.
            style: const TextStyle(height: kTextHeightNone),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        );
        final controls = <Widget>[
          if (state.playerSections.isNotEmpty || state.activeSetlist != null)
            IconButton(
              visualDensity: stackActions
                  ? VisualDensity.standard
                  : VisualDensity.compact,
              constraints: stackActions
                  ? const BoxConstraints(minWidth: 48, minHeight: 48)
                  : null,
              tooltip: _shortcutHint(
                state.activeSetlist == null
                    ? l10n.playerPreviousSection
                    : state.playerSections.isEmpty
                    ? l10n.playerPreviousSong
                    : l10n.playerPreviousSectionSong,
                state.playerSections.isEmpty ? '' : 'Ctrl+←',
              ),
              onPressed: state.activeSetlist == null
                  ? () => _skipSection(-1)
                  : () => _previousTransportAction(state),
              onLongPress: state.activeSetlist == null
                  ? null
                  : controller.previousSong,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
          Flexible(
            child:
                defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.macOS
                ? Tooltip(
                    message: _shortcutHint(
                      state.isPlaying ? l10n.playerPause : l10n.playerPlay,
                      'Space',
                    ),
                    child: start,
                  )
                : start,
          ),
          if (state.playerSections.isNotEmpty || state.activeSetlist != null)
            IconButton(
              visualDensity: stackActions
                  ? VisualDensity.standard
                  : VisualDensity.compact,
              constraints: stackActions
                  ? const BoxConstraints(minWidth: 48, minHeight: 48)
                  : null,
              tooltip: _shortcutHint(
                state.activeSetlist == null
                    ? l10n.playerNextSection
                    : state.playerSections.isEmpty
                    ? l10n.playerNextSong
                    : l10n.playerNextSectionSong,
                state.playerSections.isEmpty ? '' : 'Ctrl+→',
              ),
              onPressed: state.activeSetlist == null
                  ? () => _skipSection(1)
                  : () => _nextTransportAction(state),
              onLongPress: state.activeSetlist == null
                  ? null
                  : controller.nextSong,
              icon: const Icon(Icons.skip_next_rounded),
            ),
        ];
        final chordSlot = SizedBox(
          width: stackActions
              ? math
                    .min(
                      chordSlotWidth,
                      math.max(48.0, constraints.maxWidth - sideSlotWidth),
                    )
                    .toDouble()
              : sideSlotWidth,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: inlineChords
                ? _chordControls(l10n, state)
                : const SizedBox.shrink(),
          ),
        );
        final transportSlot = Expanded(
          child: Row(
            textDirection: direction,
            mainAxisAlignment: MainAxisAlignment.center,
            children: controls,
          ),
        );
        final actionSlot = SizedBox(
          width: sideSlotWidth,
          child: Row(
            textDirection: TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showSpeed) Flexible(child: _speedControl(l10n, state)),
              ?trailingAction,
            ],
          ),
        );
        final transportRow = Row(
          textDirection: direction,
          mainAxisAlignment: MainAxisAlignment.center,
          children: controls,
        );
        if (stackActions) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inlineChords || hasActionSlot)
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    textDirection: TextDirection.ltr,
                    children: isRtl
                        ? [
                            if (hasActionSlot) actionSlot,
                            const Spacer(),
                            if (inlineChords) chordSlot,
                          ]
                        : [
                            if (inlineChords) chordSlot,
                            const Spacer(),
                            if (hasActionSlot) actionSlot,
                          ],
                  ),
                ),
              SizedBox(height: rowHeight, child: transportRow),
            ],
          );
        }
        if (!inlineChords && !hasActionSlot) {
          return SizedBox(height: rowHeight, child: transportRow);
        }
        return Row(
          textDirection: TextDirection.ltr,
          children: isRtl
              ? [actionSlot, transportSlot, chordSlot]
              : [chordSlot, transportSlot, actionSlot],
        );
      },
    ),
  );

  Widget _chordControls(AppLocalizations l10n, VerseUiState state) {
    const sharpNames = [
      'C',
      'C♯',
      'D',
      'D♯',
      'E',
      'F',
      'F♯',
      'G',
      'G♯',
      'A',
      'A♯',
      'B',
    ];
    const flatNames = [
      'C',
      'D♭',
      'D',
      'E♭',
      'E',
      'F',
      'G♭',
      'G',
      'A♭',
      'A',
      'B♭',
      'B',
    ];
    final currentKey = _transposeKey(state);
    final savedKey = state.song?.key;
    final originalKey = _keyPitchClass(savedKey) != null
        ? savedKey
        : currentKey == null
        ? null
        : transposeChord(currentKey, -state.readerTranspose);
    final originalPitch = _keyPitchClass(originalKey);
    final currentPitch = _keyPitchClass(currentKey);
    // Menu spelling and quality follow the effective key, including overrides.
    final keyStyle = currentKey;
    final minorKey =
        keyStyle != null &&
        RegExp(
          r'^[A-Ga-g][#b♯♭]?\s*(?:m|min|minor)$',
        ).hasMatch(keyStyle.trim());
    final keyNames =
        keyStyle?.contains('b') == true || keyStyle?.contains('♭') == true
        ? flatNames
        : sharpNames;
    final originalLabel = _keyPitchClass(savedKey) != null
        ? savedKey
        : originalPitch == null
        ? null
        : '${keyNames[originalPitch]}${minorKey ? 'm' : ''}';
    final displayedKey = state.showChords
        ? currentKey ?? l10n.unknownValue
        : l10n.searchChordsUnavailable;
    return PopupMenuButton<String>(
      key: const ValueKey('pitch-key-dropdown'),
      tooltip: state.readerKeyEstimated
          ? '${l10n.playerEstimatedKey}: $displayedKey'
          : l10n.readerTranspose,
      position: PopupMenuPosition.over,
      constraints: _playerPopupConstraints(context),
      menuPadding: EdgeInsets.zero,
      initialValue: !state.showChords
          ? 'no-chords'
          : currentPitch == null
          ? null
          : 'pitch-$currentPitch',
      onSelected: (action) async {
        final latest = controller.state;
        if (latest.song?.id != state.song?.id) return;
        if (action == 'no-chords') {
          await controller.setShowChords(false);
          return;
        }
        if (action == 'edit-key') {
          final song = latest.song;
          if (song != null) await controller.editSong(song.id);
          return;
        }
        final latestPitch = _keyPitchClass(_transposeKey(latest));
        if (latestPitch == null) return;
        final targetPitch = int.parse(action.substring('pitch-'.length));
        // A key choice also leaves lyrics-only mode, including the current key.
        if (!latest.showChords) await controller.setShowChords(true);
        if (controller.state.song?.id != state.song?.id) return;
        if (targetPitch == latestPitch) return;
        var delta = (targetPitch - latestPitch + 12) % 12;
        if (targetPitch == (latestPitch - latest.readerTranspose) % 12) {
          // Restore the untransposed reader key, including a tritone offset.
          delta = -latest.readerTranspose;
        } else if (delta > 6) {
          delta -= 12;
        }
        if (delta != 0) await controller.transpose(delta);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const ValueKey('transpose-no-chords'),
          value: 'no-chords',
          child: Semantics(
            selected: !state.showChords,
            child: Text(l10n.searchChordsUnavailable),
          ),
        ),
        const PopupMenuDivider(),
        if (currentPitch != null)
          for (var pitch = 0; pitch < 12; pitch++)
            PopupMenuItem(
              key: ValueKey('transpose-pitch-$pitch'),
              value: 'pitch-$pitch',
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Semantics(
                selected: state.showChords && pitch == currentPitch,
                child: Text(
                  pitch == originalPitch
                      ? '$originalLabel  ★'
                      : '${keyNames[pitch]}${minorKey ? 'm' : ''}',
                  style: pitch == originalPitch
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        )
                      : null,
                ),
              ),
            ),
        if (currentPitch == null)
          PopupMenuItem(
            value: 'edit-key',
            child: Text(
              '${l10n.actionEdit} · ${l10n.editorKeyField}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      child: Semantics(
        key: const ValueKey('pitch-key-dropdown-label'),
        label: state.readerKeyEstimated
            ? '${l10n.readerTranspose}, ${l10n.playerEstimatedKey}: $displayedKey'
            : '${l10n.readerTranspose}, $displayedKey',
        button: true,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayedKey,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _playerDropdownArrow,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionMarkerSliderTrackShape extends RoundedRectSliderTrackShape {
  const _SectionMarkerSliderTrackShape({
    required this.markers,
    required this.durationSeconds,
  });

  final List<PlayerSectionMarker> markers;
  final double durationSeconds;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );
    if (markers.isEmpty || durationSeconds <= 0) return;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final color =
        Color.lerp(
          sliderTheme.activeTrackColor ?? const Color(0xFF777777),
          sliderTheme.inactiveTrackColor ?? const Color(0xFFBBBBBB),
          .45,
        ) ??
        sliderTheme.thumbColor ??
        const Color(0xFFFFFFFF);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final marker in markers) {
      final fraction = (marker.startSeconds / durationSeconds).clamp(0.0, 1.0);
      final x = textDirection == TextDirection.rtl
          ? trackRect.right - trackRect.width * fraction
          : trackRect.left + trackRect.width * fraction;
      context.canvas.drawCircle(Offset(x, trackRect.center.dy), 2.2, paint);
    }
  }
}

List<Widget> _sectionMarkerLabelWidgets({
  required BuildContext context,
  required List<PlayerSectionMarker> markers,
  required double durationSeconds,
  required double progressSeconds,
  required double width,
  required TextDirection textDirection,
  required Color labelColor,
  required SliderThemeData sliderTheme,
  required TextScaler textScaler,
  required AppLocalizations l10n,
}) {
  if (markers.isEmpty ||
      durationSeconds <= 0 ||
      !width.isFinite ||
      width <= 0) {
    return const [];
  }
  final thumbWidth = (sliderTheme.thumbShape ?? const RoundSliderThumbShape())
      .getPreferredSize(true, false)
      .width;
  final overlayWidth =
      (sliderTheme.overlayShape ?? const RoundSliderOverlayShape())
          .getPreferredSize(true, false)
          .width;
  final inset = sliderTheme.padding == null
      ? math.max(thumbWidth, overlayWidth) / 2
      : 0.0;
  final left = inset;
  final right = width - inset;
  final trackWidth = math.max(0.0, right - left);
  if (trackWidth <= 0) return const [];
  final progressFraction = (progressSeconds / durationSeconds).clamp(0.0, 1.0);
  final thumbX = textDirection == TextDirection.rtl
      ? right - trackWidth * progressFraction
      : left + trackWidth * progressFraction;
  // Timeline cues are secondary, but they still need to read comfortably at
  // desktop scale. Keep compact layouts denser while honoring text scaling.
  final fontSize = width >= 560 ? 13.0 : 10.0;
  // Match the inherited typeface when measuring. Measuring with the default
  // font and then painting with the app's display font made the Positioned
  // label narrower than its rendered text, so Flutter ellipsized headings.
  final style = DefaultTextStyle.of(context).style.merge(
    TextStyle(
      color: labelColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1,
    ),
  );
  final maxLabelWidth = trackWidth * .45;
  final candidates =
      <
        ({double center, String label, String sectionName, double labelWidth})
      >[];
  for (final marker in markers) {
    final fraction = (marker.startSeconds / durationSeconds).clamp(0.0, 1.0);
    final x = textDirection == TextDirection.rtl
        ? right - trackWidth * fraction
        : left + trackWidth * fraction;
    final sectionName = localizedSectionName(l10n, marker.name);
    var label = width >= 560
        ? sectionName
        : sectionAbbreviation(l10n, marker.name, compact: width < 400);
    final measure = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: Localizations.localeOf(context),
      maxLines: 1,
      ellipsis: '…',
    )..layout();
    if (measure.width > maxLabelWidth) {
      label = sectionAbbreviation(l10n, marker.name, compact: width < 400);
      measure.text = TextSpan(text: label, style: style);
      measure.layout();
    }
    // A partial cue is not useful. Keep only complete labels that fit; the
    // active section's full heading and timeline semantics remain available.
    if (measure.width > maxLabelWidth) continue;
    final labelWidth = math.min(measure.width, maxLabelWidth);
    final center = x
        .clamp(left + labelWidth / 2, right - labelWidth / 2)
        .toDouble();
    candidates.add((
      center: center,
      label: label,
      sectionName: sectionName,
      labelWidth: labelWidth,
    ));
  }

  // Keep labels above the line and leave breathing room between them. When
  // sections are densely packed, show the labels nearest the playhead first.
  final prioritized = [...candidates]
    ..sort(
      (a, b) => (a.center - thumbX).abs().compareTo((b.center - thumbX).abs()),
    );
  final visible =
      <
        ({
          double center,
          String label,
          String sectionName,
          double labelWidth,
          int row,
        })
      >[];
  for (final candidate in prioritized) {
    final rowCount = width >= 560 ? 2 : 1;
    for (var row = 0; row < rowCount; row++) {
      final collides = visible.any((existing) {
        if (existing.row != row) return false;
        final needed = (candidate.labelWidth + existing.labelWidth) / 2 + 5;
        return (candidate.center - existing.center).abs() < needed;
      });
      if (collides) continue;
      visible.add((
        center: candidate.center,
        label: candidate.label,
        sectionName: candidate.sectionName,
        labelWidth: candidate.labelWidth,
        row: row,
      ));
      break;
    }
  }
  return [
    for (final candidate in visible)
      Positioned(
        left: candidate.center - candidate.labelWidth / 2,
        width: candidate.labelWidth,
        top: 2 + candidate.row * 14,
        child: IgnorePointer(
          child: Text(
            candidate.label,
            semanticsLabel: candidate.sectionName,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: style,
          ),
        ),
      ),
  ];
}
