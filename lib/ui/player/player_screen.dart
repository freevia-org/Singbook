import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../l10n/generated/app_localizations.dart';
import '../format.dart';
import '../library_actions.dart';
import '../player_section_timeline.dart';
import '../verse_ui_state.dart';
import '../widgets/chord_lyrics_line.dart';
import '../widgets/subpage_header.dart';
import 'screen_awake.dart';
import 'section_labels.dart';

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

/// The lyric reader and player: scrolling lyrics, a seek bar with section
/// markers and transport controls.
///
/// Only this screen listens to the playback position, so one-second ticks and
/// scrubbing rebuild the seek bar and the highlighted line, not the app.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.controller, this.screenAwake});
  final VerseUiController controller;

  /// Keeps the display on while playing; [defaultScreenAwake] when null.
  final ScreenAwake? screenAwake;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  final _lyricsScroll = ScrollController();
  final _lineKeys = <String, GlobalKey>{};
  late ValueListenable<PlayerPosition> _position;
  String? _lastLineId;
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
  Size? _lastViewportSize;
  double? _lastTextScale;
  VerseUiController get controller => widget.controller;

  bool _userScrolling = false;
  double? _dragValue;
  bool _awakeHeld = false;
  bool _inForeground = true;
  bool _leaving = false;

  /// The song's real length, or an estimate from the line count that drives
  /// scrolling and the slider when the song has none.
  double _durationOf(VerseUiState state) =>
      state.song?.durationSeconds ??
      (state.songLines.length * 3.4).clamp(90, 600).toDouble();

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
  bool _handleLyricsScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _endManualScrollSoon();
      } else {
        _beginManualScroll();
      }
      return false;
    }
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
        !identical(_pointsLines, lines)) {
      _pointsSections = state.playerSections;
      _pointsLines = lines;
      _sectionPoints =
          state.playerSections
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
    if (!mounted) return;
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
      final charsPerRow = (width / (state.lyricsFontSize * .52)).floor().clamp(
        12,
        120,
      );
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
          estimatedOffset += wraps * state.lyricsFontSize * 1.35 + 12;
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
    unawaited(_applyWakeLock());
    _pruneLineKeys(state.songLines);
    final duration = _durationOf(state);
    final colors = Theme.of(context).colorScheme;
    final lyrics = Center(
      key: const ValueKey('tablet-reader-content'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleLyricsScroll,
          child: ListView.builder(
            controller: _lyricsScroll,
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 32),
            itemCount: state.songLines.length,
            itemBuilder: (context, index) =>
                _lyricLine(context, state, state.songLines[index]),
          ),
        ),
      ),
    );
    Widget controls({required bool compact, double? maxHeight}) {
      final noAudio = Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, compact ? 4 : 8),
        child: Text(
          l10n.playerLyricsOnly,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compact) noAudio,
          if (compact) _transport(context, l10n, state),
          ValueListenableBuilder<PlayerPosition>(
            valueListenable: _position,
            builder: (context, position, _) =>
                _seekBar(context, l10n, state, position, duration),
          ),
          if (!compact) _transport(context, l10n, state),
          if (song.hasChords) _chordControls(l10n, state, compact: compact),
          if (!compact) noAudio,
        ],
      );
      // Large text or a short screen can make the controls taller than the
      // screen; they scroll inside their share so the lyrics stay visible.
      return SafeArea(
        top: false,
        child: compact
            ? SingleChildScrollView(child: content)
            : maxHeight == null
            ? content
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(child: content),
              ),
      );
    }

    final metadata = [
      song.artist,
      song.album,
      if (state.readerKey != null) '${l10n.editorKeyField}: ${state.readerKey}',
      if (state.readerCapo != null)
        '${l10n.editorCapoField}: ${state.readerCapo}',
      if (state.readerTuning != null)
        '${l10n.editorTuningField}: ${state.readerTuning}',
      if (state.readerTempo != null)
        '${l10n.editorTempoField}: ${state.readerTempo}',
    ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLandscape =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 430;
        return Column(
          children: [
            SubpageHeader(
              title: song.title,
              onBack: controller.back,
              actions: [
                IconButton(
                  tooltip: song.favorite
                      ? l10n.songFavoriteRemove
                      : l10n.songFavoriteAdd,
                  onPressed: () => controller.toggleSongFavorite(song.id),
                  icon: Icon(
                    song.favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionEdit,
                  onPressed: () => controller.editSong(song.id),
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.songMenuLabel,
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'info', child: Text(l10n.songInfo)),
                    PopupMenuItem(
                      value: 'add',
                      child: Text(l10n.songAddToSetlist),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Text(l10n.settingsShareSong),
                    ),
                    PopupMenuItem(
                      value: 'share_pdf',
                      child: Text(l10n.settingsSharePdf),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: Text(l10n.settingsCopySong),
                    ),
                    PopupMenuItem(
                      value: 'print',
                      child: Text(l10n.settingsPrintSong),
                    ),
                  ],
                  onSelected: (action) => handleSongMenuAction(
                    context,
                    controller,
                    song.id,
                    action,
                  ),
                ),
              ],
            ),
            if (metadata.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    metadata,
                    maxLines: compactLandscape ? 1 : null,
                    overflow: compactLandscape ? TextOverflow.ellipsis : null,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: Text(
                      [
                        l10n.readerSaved,
                        state.readerSource,
                      ].whereType<String>().join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (state.readerCanCompareVersions)
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: controller.compareCurrentSongVersions,
                          child: Text(
                            l10n.searchCompare,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (compactLandscape)
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: lyrics),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: (constraints.maxWidth * .4)
                          .clamp(300.0, 360.0)
                          .toDouble(),
                      child: controls(compact: true),
                    ),
                  ],
                ),
              )
            else ...[
              Expanded(child: lyrics),
              controls(compact: false, maxHeight: constraints.maxHeight * .4),
            ],
          ],
        );
      },
    );
  }

  Widget _lyricLine(
    BuildContext context,
    VerseUiState state,
    LyricLineData line,
  ) {
    final theme = Theme.of(context);
    final key = _lineKeys.putIfAbsent(line.id, GlobalKey.new);
    if (line.section != null && line.text.trim().isEmpty) {
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
      child: Semantics(
        selected: current,
        child: ChordLyricsLine(
          text: line.text,
          chords: line.chords,
          showChords: state.showChords,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: state.lyricsFontSize,
            height: 1.35,
            fontWeight: current ? FontWeight.w600 : FontWeight.w400,
            color: current ? theme.colorScheme.primary : null,
          ),
          chordStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
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
    final currentSection = _sectionAt(state.playerSections, position.seconds);
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final section = Text(
                currentSection == null
                    ? (state.readerHasTiming
                          ? l10n.playerTimedLyrics
                          : l10n.playerEstimatedPace)
                    : localizedSectionName(l10n, currentSection.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
              final times = Row(
                children: [
                  Text(formatDuration(displayPosition)),
                  if (narrow)
                    const Spacer()
                  else ...[
                    const SizedBox(width: 12),
                    Expanded(child: section),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    !narrow && state.readerDurationEstimated
                        ? l10n.playerEstimatedDuration(
                            formatDuration(displayDuration),
                          )
                        : formatDuration(displayDuration),
                  ),
                ],
              );
              return narrow ? Column(children: [section, times]) : times;
            },
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: _SectionMarkerSliderTrackShape(
              markers: displaySections,
              durationSeconds: displayDuration,
            ),
          ),
          child: SizedBox(
            height: 48,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sliderTheme = SliderTheme.of(context);
                return Stack(
                  children: [
                    Positioned.fill(
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
                    ..._sectionMarkerLabelWidgets(
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
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              Text('0.5×', style: Theme.of(context).textTheme.labelSmall),
              Expanded(
                child: Slider(
                  key: const ValueKey('scroll-speed-slider'),
                  min: .5,
                  max: 2,
                  divisions: 30,
                  value: state.playbackSpeed,
                  label: '${state.playbackSpeed.toStringAsFixed(2)}×',
                  semanticFormatterCallback: (value) =>
                      '${l10n.playerScrollSpeed}, ${value.toStringAsFixed(2)}×',
                  onChanged: controller.setPlaybackSpeed,
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${state.playbackSpeed.toStringAsFixed(2)}×',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _transport(
    BuildContext context,
    AppLocalizations l10n,
    VerseUiState state,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final start = FilledButton.icon(
          key: const ValueKey('start-lyric-scroll'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            minimumSize: const Size(104, 42),
          ),
          onPressed: () async {
            if (!state.isPlaying) {
              if (!state.autoscroll) await controller.setAutoscroll(true);
              if (state.timingMode == 'manual' ||
                  (state.timingMode == 'timed' && !state.readerHasTiming)) {
                await controller.setTimingMode('estimated');
              }
            }
            await _playPause();
          },
          icon: Icon(
            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            state.isPlaying ? l10n.playerPause : l10n.playerPlay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        );
        final controls = <Widget>[
          if (state.playerSections.isNotEmpty || state.activeSetlist != null)
            IconButton(
              tooltip: state.activeSetlist == null
                  ? l10n.playerPreviousSection
                  : state.playerSections.isEmpty
                  ? l10n.playerPreviousSong
                  : l10n.playerPreviousSectionSong,
              onPressed: state.playerSections.isEmpty
                  ? state.activeSetlist == null
                        ? null
                        : controller.previousSong
                  : () => _skipSection(-1),
              onLongPress: state.activeSetlist == null
                  ? null
                  : controller.previousSong,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
          Flexible(child: start),
          if (state.playerSections.isNotEmpty || state.activeSetlist != null)
            IconButton(
              tooltip: state.activeSetlist == null
                  ? l10n.playerNextSection
                  : state.playerSections.isEmpty
                  ? l10n.playerNextSong
                  : l10n.playerNextSectionSong,
              onPressed: state.playerSections.isEmpty
                  ? state.activeSetlist == null
                        ? null
                        : controller.nextSong
                  : () => _skipSection(1),
              onLongPress: state.activeSetlist == null
                  ? null
                  : controller.nextSong,
              icon: const Icon(Icons.skip_next_rounded),
            ),
        ];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: controls,
        );
      },
    ),
  );

  Widget _chordControls(
    AppLocalizations l10n,
    VerseUiState state, {
    bool compact = false,
  }) {
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
    final originalKey = state.song?.key;
    final originalPitch = _keyPitchClass(originalKey);
    final int currentPitch =
        _keyPitchClass(state.readerKey) ?? originalPitch ?? 0;
    final minorKey =
        originalKey != null &&
        RegExp(
          r'^[A-Ga-g][#b♯♭]?\s*(?:m|min|minor)$',
        ).hasMatch(originalKey.trim());
    final keyNames =
        originalKey?.contains('b') == true || originalKey?.contains('♭') == true
        ? flatNames
        : sharpNames;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: InkWell(
              onTap: () => controller.setShowChords(!state.showChords),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: state.showChords,
                    onChanged: (value) =>
                        controller.setShowChords(value ?? false),
                  ),
                  Flexible(
                    child: Text(
                      l10n.readerShowChords,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (state.song?.hasChords == true && originalPitch != null)
            Expanded(
              flex: compact ? 4 : 3,
              child: Semantics(
                label: l10n.readerTranspose,
                child: Tooltip(
                  message: l10n.readerTranspose,
                  child: DropdownButton<int>(
                    key: const ValueKey('pitch-key-dropdown'),
                    value: currentPitch,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.arrow_drop_down),
                    selectedItemBuilder: (context) => [
                      for (var pitch = 0; pitch < 12; pitch++)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            state.readerKey ?? keyNames[pitch],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    items: [
                      for (var pitch = 0; pitch < 12; pitch++)
                        DropdownMenuItem(
                          value: pitch,
                          child: Text(
                            pitch == originalPitch
                                ? '${originalKey!}  ★'
                                : '${keyNames[pitch]}${minorKey ? 'm' : ''}',
                            style: pitch == originalPitch
                                ? TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  )
                                : null,
                          ),
                        ),
                    ],
                    onChanged: (pitch) {
                      if (pitch == null) return;
                      var delta = (pitch - currentPitch + 12) % 12;
                      if (delta > 6) delta -= 12;
                      if (delta != 0) controller.transpose(delta);
                    },
                  ),
                ),
              ),
            )
          else if (state.song?.hasChords == true)
            Expanded(
              flex: compact ? 4 : 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: l10n.readerTransposeSemitones(-1),
                    onPressed: () => controller.transpose(-1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: l10n.readerTransposeSemitones(1),
                    onPressed: () => controller.transpose(1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
        ],
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
  final fontSize = width >= 560 ? 10.0 : 9.0;
  final style = TextStyle(
    color: labelColor,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    height: 1,
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
    final label = width >= 560
        ? sectionName
        : sectionAbbreviation(l10n, marker.name, compact: width < 400);
    final measure = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxLabelWidth);
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
        ({double center, String label, String sectionName, double labelWidth})
      >[];
  for (final candidate in prioritized) {
    final collides = visible.any((existing) {
      final needed = (candidate.labelWidth + existing.labelWidth) / 2 + 5;
      return (candidate.center - existing.center).abs() < needed;
    });
    if (!collides) visible.add(candidate);
  }
  return [
    for (final candidate in visible)
      Positioned(
        left: candidate.center - candidate.labelWidth / 2,
        width: candidate.labelWidth,
        top: 2,
        child: IgnorePointer(
          child: Text(
            candidate.label,
            semanticsLabel: candidate.sectionName,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ),
  ];
}
