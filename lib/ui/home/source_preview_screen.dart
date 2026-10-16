import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../verse_ui_state.dart';
import 'source_version_browser.dart';

export 'source_version_widgets.dart';

/// The expanded view shares the same preview, tab selection and saving logic.
class SourcePreviewScreen extends StatelessWidget {
  const SourcePreviewScreen({super.key, required this.controller});
  final VerseUiController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: AppLocalizations.of(context).navClose,
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(AppLocalizations.of(context).searchFullPreview),
    ),
    body: SourceVersionBrowser(
      key: ValueKey(controller.state.comparison?.reference.id),
      controller: controller,
      onOpened: () => Navigator.of(context).pop(),
    ),
  );
}
