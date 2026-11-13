import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../verse_ui_state.dart' show PlayerSectionMarker;
import 'section_labels.dart';

class SectionMarkerSliderTrackShape extends RoundedRectSliderTrackShape {
  const SectionMarkerSliderTrackShape({
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

typedef SectionLabelCandidate = ({
  double center,
  String label,
  String sectionName,
  double labelWidth,
});

/// The measured seek-bar labels of one section list. Measuring lays out a
/// paragraph per section, so the result is kept until an input that affects
/// it changes; the playback position only reorders the candidates.
class SectionLabelCache {
  List<PlayerSectionMarker>? _markers;
  double? _durationSeconds, _width, _left, _right;
  TextDirection? _textDirection;
  TextScaler? _textScaler;
  Locale? _locale;
  String? _localeName;
  TextStyle? _style;
  List<SectionLabelCandidate>? _candidates;

  List<SectionLabelCandidate>? lookup({
    required List<PlayerSectionMarker> markers,
    required double durationSeconds,
    required double width,
    required double left,
    required double right,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale locale,
    required String localeName,
    required TextStyle style,
  }) =>
      identical(_markers, markers) &&
          _durationSeconds == durationSeconds &&
          _width == width &&
          _left == left &&
          _right == right &&
          _textDirection == textDirection &&
          _textScaler == textScaler &&
          _locale == locale &&
          _localeName == localeName &&
          _style == style
      ? _candidates
      : null;

  void store(
    List<SectionLabelCandidate> candidates, {
    required List<PlayerSectionMarker> markers,
    required double durationSeconds,
    required double width,
    required double left,
    required double right,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale locale,
    required String localeName,
    required TextStyle style,
  }) {
    _candidates = candidates;
    _markers = markers;
    _durationSeconds = durationSeconds;
    _width = width;
    _left = left;
    _right = right;
    _textDirection = textDirection;
    _textScaler = textScaler;
    _locale = locale;
    _localeName = localeName;
    _style = style;
  }
}

List<Widget> sectionMarkerLabelWidgets({
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
  SectionLabelCache? cache,
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
  final locale = Localizations.localeOf(context);
  final candidates =
      cache?.lookup(
        markers: markers,
        durationSeconds: durationSeconds,
        width: width,
        left: left,
        right: right,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
        localeName: l10n.localeName,
        style: style,
      ) ??
      _measureSectionLabels(
        markers: markers,
        durationSeconds: durationSeconds,
        width: width,
        left: left,
        right: right,
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
        style: style,
        l10n: l10n,
      );
  cache?.store(
    candidates,
    markers: markers,
    durationSeconds: durationSeconds,
    width: width,
    left: left,
    right: right,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
    localeName: l10n.localeName,
    style: style,
  );

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

List<SectionLabelCandidate> _measureSectionLabels({
  required List<PlayerSectionMarker> markers,
  required double durationSeconds,
  required double width,
  required double left,
  required double right,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required Locale locale,
  required TextStyle style,
  required AppLocalizations l10n,
}) {
  final trackWidth = math.max(0.0, right - left);
  final maxLabelWidth = trackWidth * .45;
  final candidates = <SectionLabelCandidate>[];
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
      locale: locale,
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
    final measuredWidth = measure.width;
    measure.dispose();
    if (measuredWidth > maxLabelWidth) continue;
    final labelWidth = math.min(measuredWidth, maxLabelWidth);
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
  return candidates;
}
