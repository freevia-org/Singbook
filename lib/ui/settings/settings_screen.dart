import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app_version.dart';
import '../library_actions.dart';
import '../localized_labels.dart';
import '../theme/verse_fonts.dart';
import '../theme/verse_theme.dart';
import '../verse_ui_state.dart';
import '../widgets/slider_overlay_boundary.dart';
import '../widgets/singbook_wordmark.dart';
import '../widgets/verse_components.dart' show SingbookMark;
import 'account_section.dart';
import 'lyrics_settings_preview.dart';

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

/// Opens Player settings above the reader without changing its route or song.
Future<void> showPlayerSettings(
  BuildContext context,
  VerseUiController controller,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => _SettingsSectionScreen(
      section: _SettingsSection.player,
      controller: controller,
      backupSection: () => null,
      fromReader: true,
    ),
  ),
);

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
                key: const ValueKey('settings-menu-support'),
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(l10n.aboutSupport),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => launchUrl(
                  Uri.parse('https://freevia.org/singbook/support/'),
                  mode: LaunchMode.externalApplication,
                ),
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
    this.fromReader = false,
  }) : assert(!fromReader || section == _SettingsSection.player);
  final _SettingsSection section;
  final VerseUiController controller;
  final Widget? Function() backupSection;
  final bool fromReader;

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
        (widget.fromReader &&
            widget.section == _SettingsSection.player &&
            state.route == VerseRoute.reader) ||
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

  Widget _fontSizeControl(
    BuildContext context,
    AppLocalizations l10n,
    double fontSize,
  ) {
    final slider = SliderOverlayBoundary(
      child: Slider(
        value: fontSize.clamp(18, 36),
        min: 18,
        max: 36,
        divisions: 9,
        label: fontSize.round().toString(),
        semanticFormatterCallback: (value) => value.round().toString(),
        onChanged: (value) => setState(() => _draggingFontSize = value),
        onChangeEnd: (value) {
          widget.controller.setLyricsFontSize(value);
          setState(() => _draggingFontSize = null);
        },
      ),
    );
    final label = Text(
      l10n.settingsTextSize,
      style: Theme.of(context).textTheme.labelLarge,
    );
    final value = Text(
      fontSize.round().toString(),
      textAlign: TextAlign.center,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 8, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.textScalerOf(context).scale(14) > 19 ||
              constraints.maxWidth < 290) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: label),
                    value,
                  ],
                ),
                slider,
              ],
            );
          }
          return Row(
            children: [
              label,
              const SizedBox(width: 8),
              Expanded(child: slider),
              SizedBox(width: 28, child: value),
            ],
          );
        },
      ),
    );
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
      final contentWidth = MediaQuery.sizeOf(context).width;
      final horizontalInset = contentWidth > 1200
          ? (contentWidth - 1200) / 2 + 16
          : 16.0;
      return Scaffold(
        appBar: AppBar(title: Text(_sectionTitle(l10n, widget.section))),
        body: SafeArea(
          top: false,
          child: ListView(
            key: PageStorageKey('settings-${widget.section.name}'),
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              4,
              horizontalInset,
              28,
            ),
            children: [
              if (widget.section == _SettingsSection.appearance) ...[
                _SettingCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _CompactSettingsGrid(
                        children: [
                          _LabeledDropdown<String>(
                            compact: true,
                            label: l10n.settingsLanguage,
                            selectedLabels: {
                              'system': l10n.settingsSystemShort,
                            },
                            value: state.languageCode ?? 'system',
                            entries: [
                              ('system', l10n.settingsLanguageSystem),
                              for (final locale
                                  in AppLocalizations.supportedLocales)
                                (
                                  locale.languageCode,
                                  _languageNames[locale.languageCode] ??
                                      locale.languageCode,
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
                            compact: true,
                            label: l10n.settingsTheme,
                            selectedLabels: {
                              AppThemeMode.system: l10n.settingsSystemShort,
                            },
                            value: state.darkTheme,
                            entryBuilder: (context, mode, label) =>
                                _ThemeOption(
                                  mode: mode,
                                  label: label,
                                  palette: state.palette,
                                ),
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
                            compact: true,
                            label: l10n.settingsColorPalette,
                            value: state.palette,
                            entryBuilder: (context, palette, label) =>
                                _PaletteOption(palette: palette, label: label),
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
                            compact: true,
                            label: l10n.settingsFont,
                            value: state.fontFamily,
                            entryBuilder: (context, font, label) => Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: verseFontFamily(font),
                              ),
                            ),
                            entries: [
                              ('system', l10n.settingsFontSystem),
                              ('serif', l10n.settingsFontSerif),
                              ('mono', l10n.settingsFontMonospace),
                              ('lora', 'Lora'),
                              ('nunito', 'Nunito'),
                              ('sourceSans', 'Source Sans 3'),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.setFontFamily(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    _fontSizeControl(context, l10n, fontSize),
                  ],
                ),
                const SizedBox(height: 12),
                LyricsSettingsPreview(state: state, fontSize: fontSize),
              ],
              if (widget.section == _SettingsSection.player) ...[
                _SettingCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _LabeledDropdown<String>(
                            compact: true,
                            label: l10n.settingsLyricHighlight,
                            value: state.lyricHighlightStyle,
                            entries: [
                              ('background', l10n.settingsHighlightBackground),
                              (
                                'backgroundUnderline',
                                l10n.settingsHighlightBackgroundUnderline,
                              ),
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
                          const SizedBox(height: 8),
                          _CompactSettingsGrid(
                            children: [
                              _CompactSwitch(
                                label: l10n.editorChordsField,
                                hint: l10n.settingsDefaultShowChordsHint,
                                value: state.showChords,
                                onChanged: controller.setShowChords,
                              ),
                              _CompactSwitch(
                                label: l10n.settingsPlayerSections,
                                hint: l10n.settingsShowSectionsHint,
                                value: state.showSections,
                                onChanged: controller.setShowSections,
                              ),
                              _CompactSwitch(
                                label: l10n.settingsPlayerControls,
                                hint: l10n.settingsShowPlayerControlsHint,
                                value: state.playerControlsExpanded,
                                onChanged: controller.setPlayerControlsExpanded,
                              ),
                              _CompactSwitch(
                                label: l10n.settingsPlayerAutoscroll,
                                hint: l10n.settingsDefaultAutoscrollHint,
                                value: state.autoscrollPreference,
                                onChanged: state.timingMode == 'manual'
                                    ? null
                                    : controller.setAutoscroll,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _LabeledDropdown<String>(
                            compact: true,
                            label: l10n.settingsDefaultTiming,
                            value: state.timingMode,
                            entries: [
                              ('estimated', l10n.playerEstimatedPace),
                              ('timed', l10n.playerTimedLyrics),
                              ('manual', l10n.playerManualScroll),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                controller.setTimingMode(value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LyricsSettingsPreview(state: state),
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
                      subtitle: Text(l10n.settingsClearHistoryConfirm),
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

/// Two columns at ordinary phone sizes; large text keeps full-width controls.
class _CompactSettingsGrid extends StatelessWidget {
  const _CompactSettingsGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 280 &&
              MediaQuery.textScalerOf(context).scale(14) <= 19
          ? 2
          : 1;
      return Column(
        children: [
          for (var i = 0; i < children.length; i += columns) ...[
            if (i != 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j != 0) const SizedBox(width: 10),
                  Expanded(
                    child: i + j < children.length
                        ? children[i + j]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    },
  );
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String label, hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: hint,
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      value: value,
      onChanged: onChanged,
    ),
  );
}

/// A palette sample uses the same surface, ink and accent as the app theme.
class _PaletteOption extends StatelessWidget {
  const _PaletteOption({required this.palette, required this.label});

  final String palette, label;

  @override
  Widget build(BuildContext context) {
    final colors = verseTheme(
      brightness: Theme.of(context).brightness,
      palette: palette,
    ).colorScheme;
    return _AppearanceOption(
      background: colors.surface,
      foreground: colors.onSurface,
      label: label,
      sample: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final color in [colors.primary, colors.tertiary])
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 3),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox(width: 12, height: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.palette,
  });

  final AppThemeMode mode;
  final String label, palette;

  @override
  Widget build(BuildContext context) {
    final dark =
        mode == AppThemeMode.dark ||
        (mode == AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final colors = verseTheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      palette: palette,
    ).colorScheme;
    return _AppearanceOption(
      background: colors.surface,
      foreground: colors.onSurface,
      label: label,
      sample: Icon(
        mode == AppThemeMode.system
            ? Icons.brightness_auto_outlined
            : dark
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        size: 18,
        color: colors.onSurface,
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.background,
    required this.foreground,
    required this.label,
    required this.sample,
  });

  final Color background, foreground;
  final String label;
  final Widget sample;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      border: Border.all(color: foreground.withValues(alpha: .25)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foreground),
          ),
        ),
        const SizedBox(width: 6),
        ExcludeSemantics(child: sample),
      ],
    ),
  );
}

/// A titled dropdown. The visible title is hidden from accessibility and
/// attached as the dropdown's label so it is read together with its value.
class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.compact = false,
    this.selectedLabels = const {},
    this.entryBuilder,
  });
  final String label;
  final T value;
  final List<(T, String)> entries;
  final ValueChanged<T?> onChanged;
  final bool compact;
  final Map<T, String> selectedLabels;
  final Widget Function(BuildContext context, T value, String label)?
  entryBuilder;
  @override
  Widget build(BuildContext context) {
    // A stored value that is not on offer (an old or edited setting) shows the
    // first entry, which is the default, instead of failing or going blank.
    final effective = entries.any((entry) => entry.$1 == value)
        ? value
        : entries.first.$1;
    final dropdown = DropdownButton<T>(
      isExpanded: true,
      isDense: compact,
      value: effective,
      selectedItemBuilder: selectedLabels.isEmpty && entryBuilder == null
          ? null
          : (context) => [
              for (final entry in entries)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    label: entry.$2,
                    excludeSemantics: true,
                    child:
                        entryBuilder?.call(
                          context,
                          entry.$1,
                          selectedLabels[entry.$1] ?? entry.$2,
                        ) ??
                        Text(
                          selectedLabels[entry.$1] ?? entry.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                ),
            ],
      items: entries
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry.$1,
              child:
                  entryBuilder?.call(context, entry.$1, entry.$2) ??
                  Text(entry.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
    if (compact) {
      return Semantics(
        label: label,
        child: InputDecorator(
          decoration: InputDecoration(
            label: ExcludeSemantics(child: Text(label)),
            isDense: true,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 12),
          ),
          child: DropdownButtonHideUnderline(child: dropdown),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Semantics(label: label, child: dropdown),
        ],
      ),
    );
  }
}
