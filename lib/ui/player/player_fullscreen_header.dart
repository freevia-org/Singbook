import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';

/// Uses the clear areas beside a camera cutout instead of overlaying lyrics.
class PlayerFullscreenHeader extends StatelessWidget {
  const PlayerFullscreenHeader({
    super.key,
    required this.title,
    required this.artist,
    required this.actions,
  });

  final String title;
  final String? artist;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final artistStyle = Theme.of(context).textTheme.bodySmall;
    double lineHeight(TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: style),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final textHeight =
        lineHeight(titleStyle) +
        (artist?.trim().isNotEmpty == true ? lineHeight(artistStyle) : 0) +
        6;
    final bandHeight = math.max(
      48.0,
      math.max(media.viewPadding.top, textHeight),
    );
    final cutouts =
        media.displayFeatures
            .where((feature) => feature.type == DisplayFeatureType.cutout)
            .map((feature) => feature.bounds)
            .where((bounds) => bounds.top < bandHeight && bounds.bottom > 0)
            .toList()
          ..sort((a, b) => a.left.compareTo(b.left));
    final text = Tooltip(
      message: [
        title,
        artist,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
          if (artist?.trim().isNotEmpty == true)
            Text(
              artist!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: artistStyle?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The app shell may already remove a landscape side inset.
        final view = View.of(context);
        final origin = math.min(
          view.viewPadding.left / view.devicePixelRatio,
          math.max(0.0, media.size.width - width),
        );
        final spans = <(double, double)>[];
        var start = 4.0;
        for (final bounds in cutouts) {
          final left = (bounds.left - origin - 6).clamp(4.0, width - 4);
          final right = (bounds.right - origin + 6).clamp(4.0, width - 4);
          if (left > start) spans.add((start, left));
          start = math.max(start, right);
        }
        if (start < width - 4) spans.add((start, width - 4));
        spans.sort((a, b) => (b.$2 - b.$1).compareTo(a.$2 - a.$1));
        final actionWidth = actions.length * 48.0;
        final widest = spans.isEmpty ? (4.0, width - 4) : spans.first;
        final together = widest.$2 - widest.$1 >= actionWidth + 100;
        final other = spans
            .skip(1)
            .where((span) => span.$2 - span.$1 >= actionWidth);
        // With no trustworthy clear area, keep controls below the camera band.
        final fallback =
            (!together && other.isEmpty) ||
            (cutouts.isEmpty && media.viewPadding.top > 0);
        final blockedTop = cutouts
            .where(
              (bounds) =>
                  bounds.top <= 0 && bounds.height < media.size.height / 2,
            )
            .fold(
              media.viewPadding.top,
              (height, bounds) => math.max(height, bounds.bottom),
            );
        final top = fallback ? blockedTop : 0.0;
        final height = fallback ? top + math.max(48.0, textHeight) : bandHeight;
        Widget row() => Row(
          children: [
            Expanded(child: text),
            ...actions,
          ],
        );
        return SizedBox(
          key: const ValueKey('player-fullscreen-header'),
          height: height,
          child: ColoredBox(
            color: colors.surface,
            child: Stack(
              children: [
                if (fallback)
                  Positioned(
                    top: top,
                    bottom: 0,
                    left: 4,
                    right: 4,
                    child: row(),
                  )
                else if (together)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: widest.$1,
                    width: widest.$2 - widest.$1,
                    child: row(),
                  )
                else ...[
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: widest.$1 + 4,
                    width: widest.$2 - widest.$1 - 8,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: text,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: other.first.$1,
                    width: other.first.$2 - other.first.$1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
