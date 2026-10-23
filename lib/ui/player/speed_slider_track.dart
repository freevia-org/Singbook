import 'package:flutter/material.dart';

/// Shows 0.1 speed reference marks on a continuous 0.5–2.0 slider.
///
/// These marks are visual only: the slider remains free to select values
/// between them when its divisions are unset.
class FineSpeedSliderTrackShape extends RoundedRectSliderTrackShape {
  const FineSpeedSliderTrackShape();

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
    final trackHeight = sliderTheme.trackHeight ?? 0;
    if (trackHeight <= 0) return;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (trackRect.width <= 0) return;

    final activeColor = ColorTween(
      begin: sliderTheme.disabledActiveTickMarkColor ?? Colors.white30,
      end: sliderTheme.activeTickMarkColor ?? Colors.white70,
    ).evaluate(enableAnimation)!;
    final inactiveColor = ColorTween(
      begin: sliderTheme.disabledInactiveTickMarkColor ?? Colors.black12,
      end: sliderTheme.inactiveTickMarkColor ?? Colors.black26,
    ).evaluate(enableAnimation)!;
    final paint = Paint();
    final isLtr = textDirection == TextDirection.ltr;
    // Sixteen marks cover 0.5, 0.6, …, 2.0 over fifteen equal intervals.
    for (var index = 0; index <= 15; index++) {
      final fraction = index / 15;
      final x =
          trackRect.left + trackRect.width * (isLtr ? fraction : 1 - fraction);
      final active = isLtr ? x <= thumbCenter.dx : x >= thumbCenter.dx;
      paint.color = active ? activeColor : inactiveColor;
      context.canvas.drawCircle(
        Offset(x, trackRect.center.dy),
        trackHeight / 4,
        paint,
      );
    }
  }
}
