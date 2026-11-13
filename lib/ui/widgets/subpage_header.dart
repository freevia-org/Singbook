import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Back button, title and actions shown above screens that replace the tabs.
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.actions = const [],
    this.titleWidget,
    this.onTitleTap,
  });
  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;
  final Widget? titleWidget;
  final VoidCallback? onTitleTap;
  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    // The bar is 52 dp; with large accessibility text one title line is
    // taller than that, so grow with the measured line instead of clipping.
    final measure = TextPainter(
      text: TextSpan(text: 'Ag', style: titleStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = math.max(52.0, measure.height.ceilToDouble());
    measure.dispose();
    final text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
    final displayTitle = onTitleTap == null
        ? text
        : InkWell(
            onTap: onTitleTap,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: text,
            ),
          );
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            IconButton(
              tooltip: AppLocalizations.of(context).navBack,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(child: titleWidget ?? displayTitle),
            ...actions,
          ],
        ),
      ),
    );
  }
}
