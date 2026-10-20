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
    final text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
        height: 52,
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
