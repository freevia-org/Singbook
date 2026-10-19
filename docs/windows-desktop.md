# Windows desktop preview

Singbook uses the existing Flutter app and song/library formats on Windows.
The Windows runner is generated from Flutter's standard desktop template. The
local SQLite backend uses `sqflite_common_ffi`; its database lives below the
per-user application-support directory as `databases/verse_library.db`.
This backend and path selection apply only to Windows. Existing Android, iOS,
macOS and Linux database factories and default paths are preserved.

## Development

Use Flutter 3.44.8 and Visual Studio 2022 with the **Desktop development with
C++** workload and Windows 10 SDK. From the repository root:

```powershell
flutter pub get
flutter run -d windows
```

To build a local debug bundle:

```powershell
flutter build windows --debug
```

The executable is under `build/windows/x64/runner/Debug/` with Flutter's
runtime DLLs and `data/` directory beside it. The Windows CI job compiles this
debug bundle on `windows-latest`.

## Current scope

Local library, search, player, ChordPro import/export, printing and plain-text
copy use the same app logic and formats as mobile. Windows Drive sync is not
configured yet: the current Google Sign-In plugin has no Windows implementation
and the app currently enables that auth only on Android and iOS. Do not treat a
Windows build as cloud-sync parity. A follow-up desktop OAuth implementation
needs the installed-app browser flow with PKCE, token refresh and secure token
storage before Drive sync can be enabled.

Rich HTML clipboard copy currently falls back to plain text on Windows. The
Windows runner does not yet provide the app's Android rich-clipboard channel.
