import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app_version.dart';
import '../library_actions.dart';
import '../localized_labels.dart';
import '../verse_ui_state.dart';
import '../widgets/singbook_wordmark.dart';
import '../widgets/verse_components.dart';
import 'account_section.dart';

/// Native names keep the language picker understandable regardless of the
/// currently selected app language.
const _languageNames = <String, String>{
  'ar': 'العربية',
  'bg': 'Български',
  'cs': 'Čeština',
  'da': 'Dansk',
  'de': 'Deutsch',
  'el': 'Ελληνικά',
  'en': 'English',
  'es': 'Español',
  'et': 'Eesti',
  'fi': 'Suomi',
  'fr': 'Français',
  'ga': 'Gaeilge',
  'hi': 'हिन्दी',
  'hr': 'Hrvatski',
  'hu': 'Magyar',
  'id': 'Bahasa Indonesia',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'lt': 'Lietuvių',
  'lv': 'Latviešu',
  'mt': 'Malti',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'pt': 'Português',
  'ro': 'Română',
  'ru': 'Русский',
  'sk': 'Slovenčina',
  'sl': 'Slovenščina',
  'sv': 'Svenska',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'vi': 'Tiếng Việt',
  'zh': '中文',
};

/// Appearance, player, sources, import, account and about settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    this.backupSection,
    this.syncFocusRequest = 0,
    this.onSyncFocusConsumed,
  });
  final VerseUiController controller;
  final Widget? backupSection;

  /// Incremented when the shell's cloud button is tapped; the account section
  /// is scrolled into view and [onSyncFocusConsumed] is called.
  final int syncFocusRequest;
  final VoidCallback? onSyncFocusConsumed;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _syncSectionKey = GlobalKey();

  /// Text size while the slider is being dragged; saved when the drag ends.
  double? _draggingFontSize;
  bool _refreshingSources = false;
  bool? _sourceRefreshSucceeded;

  Future<void> _refreshSources() async {
    setState(() {
      _refreshingSources = true;
      _sourceRefreshSucceeded = null;
    });
    var success = false;
    try {
      success = await widget.controller.refreshSources();
    } catch (_) {
      // Keep the current source list and offer a retry.
    }
    if (!mounted) return;
    setState(() {
      _refreshingSources = false;
      _sourceRefreshSucceeded = success;
    });
  }

  @override
  void initState() {
    super.initState();
    _focusSyncSection();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncFocusRequest != oldWidget.syncFocusRequest) {
      _focusSyncSection();
    }
  }

  void _focusSyncSection() {
    if (widget.syncFocusRequest == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The list builds every section (see cacheExtent below), so the key has
      // a context even when the account section is far below the viewport.
      final target = _syncSectionKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 280),
          alignment: .08,
        );
      }
      widget.onSyncFocusConsumed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    final state = controller.state;
    final fontSize = _draggingFontSize ?? state.lyricsFontSize;
    return ListView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(10000),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          l10n.settingsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        VerseSectionLabel(l10n.settingsAppearance),
        _SettingCard(
          children: [
            _LabeledDropdown<String>(
              label: l10n.settingsLanguage,
              value: state.languageCode ?? 'system',
              entries: [
                ('system', l10n.settingsLanguageSystem),
                ('en', _languageNames['en']!),
                ('bg', _languageNames['bg']!),
                ('uk', _languageNames['uk']!),
                ...AppLocalizations.supportedLocales
                    .where(
                      (locale) => !const {
                        'en',
                        'bg',
                        'uk',
                      }.contains(locale.languageCode),
                    )
                    .map(
                      (locale) => (
                        locale.languageCode,
                        _languageNames[locale.languageCode] ??
                            locale.languageCode,
                      ),
                    ),
              ],
              onChanged: (value) {
                if (value != null) {
                  controller.setLanguage(value == 'system' ? null : value);
                }
              },
            ),
            _LabeledDropdown<AppThemeMode>(
              label: l10n.settingsTheme,
              value: state.darkTheme,
              entries: [
                (AppThemeMode.system, l10n.settingsThemeSystem),
                (AppThemeMode.light, l10n.settingsThemeLight),
                (AppThemeMode.dark, l10n.settingsThemeDark),
              ],
              onChanged: (value) {
                if (value != null) controller.setThemeMode(value);
              },
            ),
            _LabeledDropdown<String>(
              label: l10n.settingsColorPalette,
              value: state.palette,
              entries: [
                ('navy', l10n.settingsPaletteNavy),
                ('sage', l10n.settingsPaletteSage),
                ('ocean', l10n.settingsPaletteOcean),
                ('clay', l10n.settingsPaletteClay),
                ('plum', l10n.settingsPalettePlum),
              ],
              onChanged: (value) {
                if (value != null) controller.setPalette(value);
              },
            ),
            _LabeledDropdown<String>(
              label: l10n.settingsFont,
              value: state.fontFamily,
              entries: [
                ('system', l10n.settingsFontSystem),
                ('serif', l10n.settingsFontSerif),
                ('mono', l10n.settingsFontMonospace),
              ],
              onChanged: (value) {
                if (value != null) controller.setFontFamily(value);
              },
            ),
            ListTile(
              title: Text(l10n.settingsTextSize),
              subtitle: Slider(
                value: fontSize.clamp(18, 36),
                min: 18,
                max: 36,
                divisions: 9,
                label: fontSize.round().toString(),
                semanticFormatterCallback: (value) => value.round().toString(),
                onChanged: (value) => setState(() => _draggingFontSize = value),
                onChangeEnd: (value) {
                  controller.setLyricsFontSize(value);
                  setState(() => _draggingFontSize = null);
                },
              ),
            ),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  l10n.settingsLyricsPreviewExample,
                  style: TextStyle(fontSize: fontSize, height: 1.3),
                ),
              ),
            ),
          ],
        ),
        VerseSectionLabel(l10n.settingsPlayer),
        _SettingCard(
          children: [
            _LabeledDropdown<String>(
              label: l10n.settingsLyricHighlight,
              value: state.lyricHighlightStyle,
              entries: [
                (
                  'backgroundUnderline',
                  l10n.settingsHighlightBackgroundUnderline,
                ),
                ('background', l10n.settingsHighlightBackground),
                ('underline', l10n.settingsHighlightUnderline),
                ('contrast', l10n.settingsHighlightContrast),
                ('none', l10n.settingsHighlightNone),
              ],
              onChanged: (value) {
                if (value != null) controller.setLyricHighlightStyle(value);
              },
            ),
            SwitchListTile(
              title: Text(l10n.settingsDefaultShowChords),
              subtitle: Text(l10n.settingsDefaultShowChordsHint),
              value: state.showChords,
              onChanged: controller.setShowChords,
            ),
            SwitchListTile(
              title: Text(l10n.settingsDefaultAutoscroll),
              subtitle: Text(l10n.settingsDefaultAutoscrollHint),
              // In manual timing the effective value is always off, so the
              // switch is disabled instead of silently ignoring taps; the
              // hint below already explains that it is not used.
              value: state.autoscrollPreference,
              onChanged: state.timingMode == 'manual'
                  ? null
                  : controller.setAutoscroll,
            ),
            _LabeledDropdown<String>(
              label: l10n.settingsDefaultTiming,
              value: state.timingMode,
              entries: [
                ('estimated', l10n.playerEstimatedPace),
                ('timed', l10n.playerTimedLyrics),
                ('manual', l10n.playerManualScroll),
              ],
              onChanged: (value) {
                if (value != null) controller.setTimingMode(value);
              },
            ),
          ],
        ),
        VerseSectionLabel(l10n.settingsSources),
        _SettingCard(
          children: [
            ListTile(
              key: const ValueKey('refresh-source-list'),
              leading: const Icon(Icons.refresh_rounded),
              title: Text(l10n.settingsSourceRefresh),
              subtitle: _refreshingSources
                  ? Text(l10n.loading)
                  : _sourceRefreshSucceeded == null
                  ? null
                  : Semantics(
                      liveRegion: true,
                      child: Text(
                        _sourceRefreshSucceeded!
                            ? l10n.actionDone
                            : l10n.actionRetry,
                      ),
                    ),
              trailing: _refreshingSources
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _refreshingSources ? null : _refreshSources,
            ),
            for (final provider in state.providers) ...[
              SwitchListTile(
                title: Text(provider.name),
                subtitle: Text(
                  localizedProviderDescription(l10n, provider.description),
                ),
                value: provider.enabled,
                onChanged: (value) =>
                    controller.setProviderEnabled(provider.id, value),
              ),
            ],
          ],
        ),
        if (widget.backupSection != null) widget.backupSection!,
        VerseSectionLabel(l10n.accountTitle, key: _syncSectionKey),
        AccountSection(controller: controller),
        VerseSectionLabel(l10n.settingsAbout),
        _SettingCard(
          children: [
            ListTile(
              leading: const SingbookMark(size: 38),
              title: Text(l10n.settingsAbout),
              subtitle: Text(l10n.aboutDescription),
              onTap: () => _showAbout(context, l10n),
            ),
            ListTile(
              title: Text(l10n.settingsClearHistory),
              onTap: () => confirmClearHistory(context, controller),
            ),
          ],
        ),
      ],
    );
  }

  void _showAbout(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SingbookMark(size: 88),
            const SizedBox(height: 16),
            singbookWordmark(
              context,
              l10n,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'SingbookSerif',
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aboutMadeForSinging,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(l10n.aboutDescription, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.aboutDetails, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://freevia.org/singbook/privacy/'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: Text(l10n.settingsPrivacy),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://freevia.org/singbook/support/'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.support_agent_outlined),
                  label: Text(l10n.aboutSupport),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.appVersion(singbookVersion),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).actionDone),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(child: Column(children: children));
}

/// A titled dropdown. The visible title is hidden from accessibility and
/// attached as the dropdown's label so it is read together with its value.
class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<(T, String)> entries;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) {
    // A stored value that is not on offer (an old or edited setting) shows the
    // first entry, which is the default, instead of failing or going blank.
    final effective = entries.any((entry) => entry.$1 == value)
        ? value
        : entries.first.$1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Semantics(
            label: label,
            child: DropdownButton<T>(
              isExpanded: true,
              value: effective,
              items: entries
                  .map(
                    (entry) => DropdownMenuItem<T>(
                      value: entry.$1,
                      child: Text(
                        entry.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
