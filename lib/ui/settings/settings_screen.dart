import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app_version.dart';
import '../library_actions.dart';
import '../localized_labels.dart';
import '../verse_ui_state.dart';
import '../widgets/slider_overlay_boundary.dart';
import '../widgets/singbook_wordmark.dart';
import '../widgets/verse_components.dart' show SingbookMark;
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

enum _SettingsSection { appearance, player, sources, account }

String _sectionTitle(AppLocalizations l10n, _SettingsSection section) =>
    switch (section) {
      _SettingsSection.appearance => l10n.settingsAppearance,
      _SettingsSection.player => l10n.settingsPlayer,
      _SettingsSection.sources => l10n.settingsSources,
      _SettingsSection.account => l10n.accountTitle,
    };

/// Compact section menu. Each section opens its own settings page.
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
  /// is opened directly and [onSyncFocusConsumed] is called.
  final int syncFocusRequest;
  final VoidCallback? onSyncFocusConsumed;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ValueNotifier<_SettingsSection>? _activeSection;

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
    final request = widget.syncFocusRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // The shell may have opened an account-safety dialog in this frame.
      // Let that decision finish instead of covering it with a settings page.
      final navigator = Navigator.of(context);
      while (mounted) {
        Route<dynamic>? current;
        navigator.popUntil((route) {
          current = route;
          return true;
        });
        final route = current;
        if (route is! PopupRoute<dynamic>) break;
        await route.completed;
      }
      if (!mounted || widget.syncFocusRequest != request) return;
      _openSection(_SettingsSection.account);
      widget.onSyncFocusConsumed?.call();
    });
  }

  void _openSection(_SettingsSection section) {
    final current = _activeSection;
    if (current != null) {
      current.value = section;
      return;
    }
    final active = ValueNotifier(section);
    _activeSection = active;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (context) => ValueListenableBuilder<_SettingsSection>(
              valueListenable: active,
              builder: (context, section, _) => _SettingsSectionScreen(
                key: ValueKey(section),
                section: section,
                controller: widget.controller,
                // Read the shell's latest backup widget after sign-in state changes.
                backupSection: () => mounted ? widget.backupSection : null,
              ),
            ),
          ),
        )
        .whenComplete(() {
          if (identical(_activeSection, active)) _activeSection = null;
          active.dispose();
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          l10n.settingsTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabeledDropdown<String>(
                label: l10n.settingsStartupView,
                value: widget.controller.state.startupSongsView,
                entries: [
                  ('recent', l10n.searchRecentTab),
                  ('library', l10n.songsLibraryView),
                  ('favorites', l10n.searchFavoritesTab),
                  ('online', l10n.searchOnlineTab),
                  ('last', l10n.settingsStartupLastView),
                ],
                onChanged: (value) {
                  if (value != null) {
                    widget.controller.setStartupSongsView(value);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.settingsStartupViewHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              _menu(
                context,
                _SettingsSection.appearance,
                Icons.palette_outlined,
              ),
              _menu(context, _SettingsSection.player, Icons.lyrics_outlined),
              _menu(
                context,
                _SettingsSection.sources,
                Icons.library_music_outlined,
              ),
              _menu(
                context,
                _SettingsSection.account,
                Icons.account_circle_outlined,
              ),
              ListTile(
                key: const ValueKey('settings-menu-about'),
                leading: const SingbookMark(size: 28),
                title: Text(l10n.settingsAbout),
                trailing: _menuArrow(context),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => _AboutScreen(controller: widget.controller),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menu(BuildContext context, _SettingsSection section, IconData icon) =>
      ListTile(
        key: ValueKey('settings-menu-${section.name}'),
        leading: Icon(icon),
        title: Text(_sectionTitle(AppLocalizations.of(context), section)),
        trailing: _menuArrow(context),
        onTap: () => _openSection(section),
      );

  // This Material icon already mirrors automatically in RTL locales.
  Widget _menuArrow(BuildContext context) =>
      const Icon(Icons.chevron_right_rounded);
}

/// About is a regular settings destination, not a modal dialog.
class _AboutScreen extends StatefulWidget {
  const _AboutScreen({required this.controller});

  final VerseUiController controller;

  @override
  State<_AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<_AboutScreen> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_followShellNavigation);
  }

  @override
  void didUpdateWidget(covariant _AboutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_followShellNavigation);
      widget.controller.addListener(_followShellNavigation);
    }
  }

  void _followShellNavigation() {
    final state = widget.controller.state;
    if (_leaving ||
        (state.route == VerseRoute.main &&
            state.activeTab == VerseTab.settings)) {
      return;
    }
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_followShellNavigation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(height: 24),
                  _AboutSection(
                    title: l10n.aboutFindTitle,
                    details: l10n.aboutDetails,
                  ),
                  _AboutSection(
                    title: l10n.aboutKeepTitle,
                    details: l10n.aboutKeepDetails,
                  ),
                  _AboutSection(
                    title: l10n.aboutPlayTitle,
                    details: l10n.aboutPlayDetails,
                  ),
                  _AboutSection(
                    title: l10n.aboutPrivacyTitle,
                    details: l10n.aboutPrivacyDetails,
                  ),
                  Text(
                    l10n.aboutLanguages(
                      AppLocalizations.supportedLocales.length,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      for (final (label, icon, url) in [
                        (
                          l10n.aboutWebsite,
                          Icons.language_outlined,
                          'https://freevia.org/singbook/',
                        ),
                        (
                          l10n.aboutSourceCode,
                          Icons.code_rounded,
                          'https://github.com/freevia-org/Singbook',
                        ),
                        (
                          l10n.settingsPrivacy,
                          Icons.privacy_tip_outlined,
                          'https://freevia.org/singbook/privacy/',
                        ),
                        (
                          l10n.aboutSupport,
                          Icons.support_agent_outlined,
                          'https://freevia.org/singbook/support/',
                        ),
                        (
                          l10n.aboutPublisher,
                          Icons.open_in_new_rounded,
                          'https://freevia.org/',
                        ),
                      ])
                        TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: Icon(icon),
                          label: Text(label),
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
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.details});

  final String title;
  final String details;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 6),
        Text(details),
      ],
    ),
  );
}

class _SettingsSectionScreen extends StatefulWidget {
  const _SettingsSectionScreen({
    super.key,
    required this.section,
    required this.controller,
    required this.backupSection,
  });
  final _SettingsSection section;
  final VerseUiController controller;
  final Widget? Function() backupSection;

  @override
  State<_SettingsSectionScreen> createState() => _SettingsSectionScreenState();
}

class _SettingsSectionScreenState extends State<_SettingsSectionScreen> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_followShellNavigation);
  }

  @override
  void didUpdateWidget(covariant _SettingsSectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_followShellNavigation);
      widget.controller.addListener(_followShellNavigation);
    }
  }

  // Account conflict actions navigate to the library in the shell. Dismiss
  // this detail route as well so that destination remains visible.
  void _followShellNavigation() {
    final state = widget.controller.state;
    if (_leaving ||
        (state.route == VerseRoute.main &&
            state.activeTab == VerseTab.settings)) {
      return;
    }
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_followShellNavigation);
    super.dispose();
  }

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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final controller = widget.controller;
      final state = controller.state;
      final fontSize = _draggingFontSize ?? state.lyricsFontSize;
      final backup = widget.backupSection();
      return Scaffold(
        appBar: AppBar(title: Text(_sectionTitle(l10n, widget.section))),
        body: SafeArea(
          top: false,
          child: ListView(
            key: PageStorageKey('settings-${widget.section.name}'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              if (widget.section == _SettingsSection.appearance) ...[
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
                          controller.setLanguage(
                            value == 'system' ? null : value,
                          );
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
                      subtitle: SliderOverlayBoundary(
                        child: Slider(
                          value: fontSize.clamp(18, 36),
                          min: 18,
                          max: 36,
                          divisions: 9,
                          label: fontSize.round().toString(),
                          semanticFormatterCallback: (value) =>
                              value.round().toString(),
                          onChanged: (value) =>
                              setState(() => _draggingFontSize = value),
                          onChangeEnd: (value) {
                            controller.setLyricsFontSize(value);
                            setState(() => _draggingFontSize = null);
                          },
                        ),
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
              ],
              if (widget.section == _SettingsSection.player) ...[
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
                        if (value != null) {
                          controller.setLyricHighlightStyle(value);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: Text(l10n.readerShowChords),
                      subtitle: Text(l10n.settingsDefaultShowChordsHint),
                      value: state.showChords,
                      onChanged: controller.setShowChords,
                    ),
                    SwitchListTile(
                      title: Text(l10n.settingsShowSections),
                      subtitle: Text(l10n.settingsShowSectionsHint),
                      value: state.showSections,
                      onChanged: controller.setShowSections,
                    ),
                    SwitchListTile(
                      title: Text(l10n.settingsShowPlayerControls),
                      subtitle: Text(l10n.settingsShowPlayerControlsHint),
                      value: state.playerControlsExpanded,
                      onChanged: controller.setPlayerControlsExpanded,
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
              ],
              if (widget.section == _SettingsSection.sources) ...[
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
                          localizedProviderDescription(
                            l10n,
                            provider.description,
                          ),
                        ),
                        value: provider.enabled,
                        onChanged: (value) =>
                            controller.setProviderEnabled(provider.id, value),
                      ),
                    ],
                  ],
                ),
              ],
              if (widget.section == _SettingsSection.account) ...[
                AccountSection(controller: controller),
                ?backup,
                _SettingCard(
                  children: [
                    ListTile(
                      key: const ValueKey('settings-clear-history'),
                      leading: const Icon(Icons.history_rounded),
                      title: Text(l10n.settingsClearHistory),
                      onTap: () => confirmClearHistory(context, controller),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
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
