import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../application/app_controller.dart';
import '../application/file_actions.dart';
import '../l10n/generated/app_localizations.dart';
import 'account_avatar.dart';
import 'app_controller_adapter.dart';
import 'home/home_screen.dart';
import 'library/editor_screen.dart';
import 'library/setlists_screen.dart';
import 'library/songs_screen.dart';
import 'library_actions.dart';
import 'localized_labels.dart';
import 'player/player_screen.dart';
import 'settings/account_section.dart';
import 'settings/backup_section.dart';
import 'settings/settings_screen.dart';
import 'theme/verse_theme.dart';
import 'verse_ui_state.dart';
import 'widgets/singbook_wordmark.dart';
import 'widgets/adaptive_bottom_navigation.dart';
import 'widgets/verse_components.dart';

class VerseApp extends StatefulWidget {
  const VerseApp({super.key, this.controller});

  /// An application controller to use instead of creating one. The widget does
  /// not dispose a controller it was given.
  final AppController? controller;

  @override
  State<VerseApp> createState() => _VerseAppState();
}

class _VerseAppState extends State<VerseApp> {
  late final AppController _app;
  late final bool _ownsApp;
  late final VerseFileActions _files;
  late final AppControllerAdapter _controller;
  int _syncSettingsRequest = 0;
  bool _initialized = false;
  bool _startupFailed = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Themes depend only on palette and font; cache them so notifications that
  // change neither do not rebuild three ThemeData objects.
  (String, String)? _themeKey;
  late ThemeData _light, _dark;
  late _AppAppearance _appearance;

  @override
  void initState() {
    super.initState();
    _ownsApp = widget.controller == null;
    _app = widget.controller ?? AppController();
    _files = VerseFileActions();
    unawaited(_files.cleanUpShareCache());
    _controller = AppControllerAdapter(
      _app,
      onShareSong: _files.shareSong,
      onShareSongPdf: _files.shareSongPdf,
      onCopySong: _files.copySong,
      onPrintSong: _files.printSong,
      onShareSetlist: (setlist) => _files.shareSetlist(setlist, _app.songs),
      onShareSetlistPdf: (setlist) =>
          _files.shareSetlistPdf(setlist, _app.songs),
      onCopySetlist: (setlist) => _files.copySetlist(setlist, _app.songs),
      onPrintSetlist: (setlist) => _files.printSetlist(setlist, _app.songs),
      onImport: _importSongs,
      onImportSetlist: _importSetlist,
    );
    _appearance = _AppAppearance.of(_controller.state);
    _updateThemes();
    _controller.addListener(_onControllerChanged);
    _start();
  }

  /// Rebuilds the MaterialApp only when something it renders from changed.
  void _onControllerChanged() {
    final next = _AppAppearance.of(_controller.state);
    if (next == _appearance) return;
    setState(() {
      _appearance = next;
      _updateThemes();
    });
  }

  void _updateThemes() {
    final key = (_appearance.palette, _appearance.fontFamily);
    if (key == _themeKey) return;
    _themeKey = key;
    final family = _fontFamily(_appearance.fontFamily);
    _light = verseTheme(
      brightness: Brightness.light,
      palette: _appearance.palette,
      fontFamily: family,
    );
    _dark = verseTheme(
      brightness: Brightness.dark,
      palette: _appearance.palette,
      fontFamily: family,
    );
  }

  Future<void> _start() async {
    if (mounted && _startupFailed) setState(() => _startupFailed = false);
    try {
      await _controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _startupFailed = true);
    }
  }

  void _openSyncSettings() {
    setState(() => _syncSettingsRequest++);
    _controller.setTab(VerseTab.settings);
  }

  void _consumeSyncSettingsRequest() {
    if (_syncSettingsRequest == 0 || !mounted) return;
    setState(() => _syncSettingsRequest = 0);
  }

  Future<void> _importSongs() => _import(ImportIntent.songs);

  Future<void> _importSetlist() => _import(ImportIntent.setlists);

  Future<void> _import(ImportIntent intent) async {
    final picked = await _files.pickDocument();
    if (picked == null) return;
    await _app.importDocument(picked, intent: intent);
    _controller.postNotice(UiNotice.importSuccess);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    if (_ownsApp) _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = switch (_appearance.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
    final languageCode = _appearance.languageCode;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Singbook',
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: mode,
      locale: languageCode == null ? null : Locale(languageCode),
      localizationsDelegates: singbookLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final brightness = switch (mode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => platformBrightness,
        };
        final colors =
            (brightness == Brightness.dark ? _dark : _light).colorScheme;
        final dark = brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: colors.surface,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: colors.surface,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: !_initialized
          ? _startupFailed
                ? _StartupError(onRetry: _start)
                : const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SingbookMark(size: 56),
                          SizedBox(height: 18),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ],
                      ),
                    ),
                  )
          : VerseAppShell(
              backupController: _app,
              controller: _controller,
              files: _files,
              syncFocusRequest: _syncSettingsRequest,
              onOpenSyncSettings: _openSyncSettings,
              onSyncFocusConsumed: _consumeSyncSettingsRequest,
            ),
    );
  }
}

/// Supplies [base]'s localizations in English for locales it has no data for.
/// Flutter ships no Material or Cupertino strings for Maltese, and without a
/// delegate for the type every text field and chip in the app would throw.
class _EnglishFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const _EnglishFallbackDelegate(this._base);
  final LocalizationsDelegate<T> _base;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) =>
      _base.load(_base.isSupported(locale) ? locale : const Locale('en'));

  @override
  bool shouldReload(covariant _EnglishFallbackDelegate<T> old) => false;
}

/// The app's localization delegates: its own strings, then Flutter's, with an
/// English fallback behind the Material and Cupertino ones.
const singbookLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  _EnglishFallbackDelegate<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  ),
  _EnglishFallbackDelegate<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  ),
];

/// Picks the app locale: an exact match, then a language match, and otherwise
/// English. Flutter's default would fall back to the first supported locale,
/// which is Arabic in the generated list.
Locale resolveAppLocale(Locale? locale, Iterable<Locale> supported) {
  if (locale != null) {
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode &&
          candidate.scriptCode == locale.scriptCode &&
          candidate.countryCode == locale.countryCode) {
        return candidate;
      }
    }
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) return candidate;
    }
  }
  return const Locale('en');
}

/// The parts of [VerseUiState] the MaterialApp itself renders from.
@immutable
class _AppAppearance {
  const _AppAppearance(
    this.palette,
    this.fontFamily,
    this.themeMode,
    this.languageCode,
  );
  factory _AppAppearance.of(VerseUiState state) => _AppAppearance(
    state.palette,
    state.fontFamily,
    state.darkTheme,
    state.languageCode,
  );
  final String palette, fontFamily;
  final AppThemeMode themeMode;
  final String? languageCode;

  @override
  bool operator ==(Object other) =>
      other is _AppAppearance &&
      other.palette == palette &&
      other.fontFamily == fontFamily &&
      other.themeMode == themeMode &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(palette, fontFamily, themeMode, languageCode);
}

String _fontFamily(String font) => switch (font) {
  'serif' => 'serif',
  'mono' => 'monospace',
  _ => 'sans-serif',
};

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_rounded, size: 42),
              const SizedBox(height: 16),
              Text(l10n.startupErrorTitle, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
            ],
          ),
        ),
      ),
    );
  }
}

class VerseAppShell extends StatefulWidget {
  const VerseAppShell({
    super.key,
    required this.controller,
    required this.files,
    this.backupController,
    this.syncFocusRequest = 0,
    this.onOpenSyncSettings = _ignoreSyncSettingsRequest,
    this.onSyncFocusConsumed = _ignoreSyncSettingsRequest,
  });
  final VerseUiController controller;
  final VerseFileActions files;
  final AppController? backupController;
  final int syncFocusRequest;
  final VoidCallback onOpenSyncSettings;
  final VoidCallback onSyncFocusConsumed;

  @override
  State<VerseAppShell> createState() => _VerseAppShellState();
}

void _ignoreSyncSettingsRequest() {}

class _VerseAppShellState extends State<VerseAppShell>
    with WidgetsBindingObserver {
  StreamSubscription<UiNotice>? _notices;
  Timer? _exitBackTimer;
  bool _exitBackArmed = false;

  /// The account-change dialog was shown for the current `account_changed`
  /// stop; cleared when the stop is resolved so it can appear again.
  bool _accountChangePrompted = false, _remoteDeletionsPrompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.onAppResumed();
  }

  @override
  void didUpdateWidget(covariant VerseAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) _subscribe();
  }

  void _subscribe() {
    _notices?.cancel();
    _notices = widget.controller.notices.listen(_showNotice);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notices?.cancel();
    _exitBackTimer?.cancel();
    super.dispose();
  }

  void _showNotice(UiNotice notice) {
    if (!mounted) return;
    if (notice == UiNotice.songSaved &&
        widget.controller.state.route == VerseRoute.reader) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(noticeMessage(AppLocalizations.of(context), notice)),
        ),
      );
  }

  bool _backInFlight = false;

  void _disarmExitBack() {
    _exitBackTimer?.cancel();
    _exitBackTimer = null;
    if (!_exitBackArmed || !mounted) return;
    setState(() => _exitBackArmed = false);
  }

  /// Goes back, first asking whether unsaved editor changes may be discarded.
  Future<void> _requestBack() async {
    if (_backInFlight) return;
    _backInFlight = true;
    try {
      await _goBack();
    } finally {
      _backInFlight = false;
    }
  }

  Future<void> _goBack() async {
    final state = widget.controller.state;
    if (state.route == VerseRoute.main &&
        state.activeTab == VerseTab.home &&
        state.homeListMode == HomeListMode.online &&
        state.comparison != null) {
      widget.controller.changeSearchSong();
      return;
    }
    if (state.route == VerseRoute.main && state.activeTab != VerseTab.home) {
      _disarmExitBack();
      widget.controller.setTab(VerseTab.home);
      return;
    }
    if (state.route == VerseRoute.main && state.activeTab == VerseTab.home) {
      final l10n = AppLocalizations.of(context);
      if (_exitBackArmed) {
        // PopScope now allows the platform back action to exit the root route.
        return;
      }
      setState(() => _exitBackArmed = true);
      _exitBackTimer?.cancel();
      _exitBackTimer = Timer(const Duration(seconds: 2), _disarmExitBack);
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.appExitBackAgain),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }
    if (state.route == VerseRoute.editor && state.editorDirty) {
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      if (!await confirmDiscardEdits(context)) return;
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
    }
    await widget.controller.back();
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.controller, builder: _buildShell);

  void _promptAccountChange(VerseUiState state) {
    final changed = state.syncErrorCode == 'account_changed';
    if (!changed) {
      _accountChangePrompted = false;
      return;
    }
    if (_accountChangePrompted) return;
    _accountChangePrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showAccountChangeDialog(context, widget.controller);
    });
  }

  /// Asks once per occurrence what to do when the cloud no longer lists items
  /// this device synced before.
  void _promptRemoteDeletions(VerseUiState state) {
    if (state.syncErrorCode != 'remote_listing_suspicious' ||
        !state.syncSignedIn) {
      _remoteDeletionsPrompted = false;
      return;
    }
    if (_remoteDeletionsPrompted) return;
    _remoteDeletionsPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showRemoteDeletionsDialog(context, widget.controller);
    });
  }

  /// The header cloud button: its icon and spoken label follow the sync state.
  Widget _cloudButton(AppLocalizations l10n, VerseUiState state) {
    final scheme = Theme.of(context).colorScheme;
    final failed = state.syncReady && state.syncErrorCode != null;
    final String tooltip;
    final Widget icon;
    if (!state.syncReady) {
      tooltip = l10n.accountTitle;
      icon = const Icon(Icons.cloud_off_outlined);
    } else if (!state.syncSignedIn) {
      tooltip = failed ? l10n.accountStatusError : l10n.accountStatusSignedOut;
      icon = _badged(const Icon(Icons.cloud_outlined), failed, scheme);
    } else {
      tooltip = state.syncBusy
          ? l10n.accountStatusSyncing
          : failed
          ? l10n.accountStatusError
          : state.lastSyncAt != null
          ? l10n.accountStatusSynced
          : l10n.accountStatusSignedIn;
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          AccountAvatar(photoUrl: state.accountPhotoUrl, size: 32),
          if (state.syncBusy)
            Positioned(
              right: -2,
              bottom: -2,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                  backgroundColor: scheme.surface,
                ),
              ),
            )
          else if (failed)
            Positioned(
              right: -1,
              top: -1,
              child: DecoratedBox(
                key: const ValueKey('cloud-status-error'),
                decoration: BoxDecoration(
                  color: scheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: const SizedBox(width: 10, height: 10),
              ),
            ),
        ],
      );
    }
    return IconButton(
      key: const ValueKey('cloud-button'),
      tooltip: tooltip,
      onPressed: widget.onOpenSyncSettings,
      icon: icon,
    );
  }

  Widget _badged(Widget icon, bool show, ColorScheme scheme) => show
      ? Badge(smallSize: 10, backgroundColor: scheme.error, child: icon)
      : icon;

  List<Widget> _mainHeaderActions(AppLocalizations l10n, VerseUiState state) {
    final actions = <Widget>[];
    switch (state.activeTab) {
      case VerseTab.songs:
        actions.addAll([
          PopupMenuButton<String>(
            key: const ValueKey('header-overflow-menu'),
            tooltip: l10n.navMore,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'new-song') {
                unawaited(widget.controller.createSong());
              } else if (value == 'import-chordpro') {
                unawaited(widget.controller.importChordPro());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new-song',
                child: Text(l10n.menuTypeNewSong),
              ),
              PopupMenuItem(
                value: 'import-chordpro',
                child: Text(l10n.settingsImportChordPro),
              ),
            ],
          ),
        ]);
      case VerseTab.setlists:
        actions.addAll([
          IconButton.filledTonal(
            key: const ValueKey('add-header-button'),
            tooltip: l10n.setlistCreate,
            onPressed: () =>
                widget.controller.createSetlist(name: l10n.setlistCreate),
            icon: const Icon(Icons.add_rounded),
          ),
          PopupMenuButton<String>(
            key: const ValueKey('header-overflow-menu'),
            tooltip: l10n.navMore,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'import-setlist') {
                unawaited(widget.controller.importSetlist());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import-setlist',
                child: Text('${l10n.settingsImportSetlist} (.osts)'),
              ),
            ],
          ),
        ]);
      case VerseTab.home:
      case VerseTab.settings:
        break;
    }
    actions.add(_cloudButton(l10n, state));
    actions.add(const SizedBox(width: 8));
    return actions;
  }

  Widget _buildShell(BuildContext context, Widget? _) {
    final controller = widget.controller;
    final state = controller.state;
    final l10n = AppLocalizations.of(context);
    _promptAccountChange(state);
    _promptRemoteDeletions(state);
    final size = MediaQuery.sizeOf(context);
    final navigationTextScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final comparisonMode =
        state.route == VerseRoute.main &&
        state.activeTab == VerseTab.home &&
        state.homeListMode == HomeListMode.online &&
        state.comparison != null;
    final homeRoot =
        state.route == VerseRoute.main && state.activeTab == VerseTab.home;
    if (!homeRoot && _exitBackArmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _exitBackArmed) _disarmExitBack();
      });
    }
    // Navigation follows available width so portrait tablets keep the rail.
    // A compact landscape phone gets it too, but only when the four rail
    // destinations (which do not scroll) fit under the app bar.
    final railHeight = 54 + 8 + 4 * (56 + 20 * navigationTextScale);
    final availableNavigationHeight =
        size.height -
        MediaQuery.paddingOf(context).vertical -
        MediaQuery.viewInsetsOf(context).bottom;
    final useRail =
        (size.width >= 600 || (size.width >= 500 && size.height <= 600)) &&
        availableNavigationHeight >= railHeight;
    return PopScope(
      canPop: homeRoot && !comparisonMode && _exitBackArmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestBack();
      },
      child: Scaffold(
        appBar: state.route == VerseRoute.main
            ? AppBar(
                toolbarHeight: 48,
                titleSpacing: 16,
                leading: comparisonMode
                    ? BackButton(onPressed: controller.changeSearchSong)
                    : null,
                title: comparisonMode
                    ? Text(l10n.searchCompare)
                    : Row(
                        children: [
                          const SingbookMark(size: 36, excludeSemantics: true),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: singbookWordmark(
                                      context,
                                      l10n,
                                      key: const ValueKey('appbar-brand-title'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontFamily: 'SingbookSerif',
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -.25,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                actions: comparisonMode
                    ? null
                    : _mainHeaderActions(l10n, state),
              )
            : null,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              if (state.route == VerseRoute.main && useRail && !comparisonMode)
                NavigationRail(
                  key: const ValueKey('tablet-navigation-rail'),
                  selectedIndex: state.activeTab.index,
                  onDestinationSelected: (index) =>
                      controller.setTab(VerseTab.values[index]),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.search_rounded),
                      label: Text(l10n.navHome),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.music_note_rounded),
                      label: Text(l10n.navSongs),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.queue_music_rounded),
                      label: Text(l10n.navSetlists),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(l10n.navSettings),
                    ),
                  ],
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    key: const ValueKey('tablet-content-frame'),
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _body(context, state),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            state.route == VerseRoute.main && !useRail && !comparisonMode
            ? AdaptiveBottomNavigation(
                selectedIndex: state.activeTab.index,
                onSelected: (index) =>
                    controller.setTab(VerseTab.values[index]),
                labels: [
                  l10n.navHome,
                  l10n.navSongs,
                  l10n.navSetlists,
                  l10n.navSettings,
                ],
                icons: const [
                  Icons.search_rounded,
                  Icons.music_note_rounded,
                  Icons.queue_music_rounded,
                  Icons.tune_rounded,
                ],
              )
            : null,
      ),
    );
  }

  Widget _body(BuildContext context, VerseUiState state) {
    final controller = widget.controller;
    switch (state.route) {
      case VerseRoute.reader:
        return PlayerScreen(controller: controller);
      case VerseRoute.editor:
        return EditorScreen(
          key: ValueKey('editor-${state.editor?.songId}'),
          controller: controller,
          onBack: _requestBack,
        );
      case VerseRoute.setlistDetail:
        return SetlistDetailScreen(controller: controller);
      case VerseRoute.main:
        break;
    }
    return switch (state.activeTab) {
      VerseTab.home => VerseHomeScreen(controller: controller, state: state),
      VerseTab.songs => SongsScreen(controller: controller),
      VerseTab.setlists => SetlistsScreen(controller: controller),
      VerseTab.settings => SettingsScreen(
        backupSection: widget.backupController == null
            ? null
            : BackupSection(
                controller: widget.backupController!,
                files: widget.files,
                syncConnected: state.syncSignedIn,
              ),
        controller: controller,
        syncFocusRequest: widget.syncFocusRequest,
        onSyncFocusConsumed: widget.onSyncFocusConsumed,
      ),
    };
  }
}
