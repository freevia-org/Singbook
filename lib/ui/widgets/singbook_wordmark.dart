import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// The two-tone "Singbook" wordmark; screen readers read the app title once.
Widget singbookWordmark(
  BuildContext context,
  AppLocalizations l10n, {
  Key? key,
  TextStyle? style,
  TextAlign? textAlign,
}) {
  final colors = Theme.of(context).colorScheme;
  final light = colors.brightness == Brightness.light;
  return Semantics(
    label: l10n.appTitle,
    child: ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Sing',
              style: TextStyle(color: light ? colors.primary : colors.onSurface),
            ),
            TextSpan(
              text: 'book',
              style: TextStyle(color: light ? colors.onSurface : colors.primary),
            ),
          ],
        ),
        key: key,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    ),
  );
}
