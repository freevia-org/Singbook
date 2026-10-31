# Linux desktop

Singbook runs on Linux x64 (GTK 3, X11 and Wayland) with the same library,
ChordPro files and sync protocol as the other desktop apps. Database names and
the `x_verse` payload (timing, source provenance) are unchanged.

## Build

Install the Flutter Linux toolchain (Flutter 3.44.8):

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev imagemagick
```

```bash
flutter build linux --release --dart-define-from-file=config/local.defines.json
```

`config/local.defines.json` is optional and ignored by Git; without it Google
sync and Genius are unavailable. The bundle is
`build/linux/x64/release/bundle/`. Package it (nothing is published):

```bash
scripts/package-linux.sh
```

This writes `Singbook-<version>-<build>-x86_64.AppImage` and
`singbook_<version>-<build>_amd64.deb` to `build/linux-packages/`. CI
(`linux-build` job) builds both, runs the desktop journey under Xvfb, and
uploads them as the `linux-packages` artifact.

## Platform behaviour

| Area | Linux |
| --- | --- |
| SQLite | `sqflite_common_ffi` with the bundled SQLite; library in `databases/verse_library.db` under the XDG data directory (`~/.local/share/...`) |
| Google Drive sync | Same loopback OAuth flow as Windows (system browser, `SINGBOOK_GOOGLE_DESKTOP_CLIENT_ID`); tokens kept in `0600` files under the app data directory, not the OS keyring |
| Export / backup | Save-as dialog (needs `zenity` or `kdialog`) |
| HTTP | Dart `HttpClient` (no Early Hints workaround as on Windows/Apple) |
| Window | Close is vetoable by the app (unsaved edits); player fullscreen |
| Not on Linux | Rich HTML clipboard (plain text is copied), Drive folder picker UI, iCloud, Cronet |

## Store proposals

Flatpak (Flathub; `org.freevia.singbook`, sandbox needs `--share=network`,
`--filesystem=xdg-documents`, portals for file chooser and open-URI, which also
makes the loopback OAuth flow work) and Snap are the natural stores. Neither is
built or published yet.
