# Native Windows acceptance run

Run this only with an agreed build/device slot. Record the exact commit/tree,
build mode, build configuration presence (never its contents), extracted bundle
SHA-256, OS, display scale and window dimensions. A build from this worktree
does not prove that the later combined integration build behaves the same way.

Use a disposable library. If an existing library is present, preserve a full,
consistent backup before changing it; do not reset its database or credentials.
Keep screenshots, build/runtime logs, imported/exported files and hashes in a
unique directory under `artifacts/windows-parity/`.

For the disposable run, create its parent directory and pass an explicit absolute
database path to the extracted executable:

```powershell
& 'E:\acceptance\Singbook\singbook.exe' --library-path 'E:\acceptance\Original fixture library.sqlite'
```

Use the same path on restart. The opt-in path selects a separate local library;
it does not isolate the user's Windows credentials or clipboard. Omitting the flag retains
the normal library location. Missing, relative or duplicate path flags fail
before opening a library, so a malformed command cannot silently use real data.

## Fixture

`test/fixtures/windows/Desktop-stage.cho` is an original synthetic song with
Unicode metadata, chords, repeated choruses and instrumental intro/outro.
Copy it into a Unicode-named acceptance directory for native file-dialog checks.
Its duration is an estimate for lyric scrolling, not an audio recording.

## Workflow and evidence

1. Extract the release ZIP outside the checkout. Launch `Singbook/singbook.exe`
   with the adjacent runtime DLLs and `data/` directory. Capture Songs and source
   identity; confirm no missing-DLL or startup error. A developer machine launch
   alone does not establish clean-machine acceptance.
2. Import the fixture through the native file dialog. Confirm its title, artist,
   Em key and section markers. Cancel a second import without changing songs.
3. Open the player at desktop and narrow window widths. Capture light/dark,
   Ukrainian, RTL and large-text variants using app settings. Check that lyrics,
   section labels, bottom controls, compact edge-aligned popups and menus remain
   readable without clipping. Record actual window dimensions and display scale.
4. Seek with the mouse, use previous/next sections and keyboard shortcuts. Intro
   and outro must consume scrolling time. Space must leave text entry, focused
   sliders/buttons and open menus usable. Change speed and transpose, toggle
   chords and headings from Settings, and collapse/re-expand the controls. Leave
   the song, reopen it and repeat after a full app restart. Verify settings persist
   and highlighting never shifts text.
5. Edit a synthetic copy. Check Ctrl+S, validation and dirty-editor window close:
   cancel preserves the draft; discard exits only after confirmation. Reopen the
   app and check the saved content.
6. Create a synthetic setlist, add the fixture and another original synthetic
   song. Drag whole rows with the mouse, use row menus and check reorder
   persistence. Perform deletion only on test data with any required UI
   confirmation; preserve user items. Verify mobile behavior separately in the
   combined integration run.
7. Export ChordPro, OpenSong setlist, PDF and a full backup through native Save
   As. Check Unicode directory/name, cancel, saved bytes and import round trip
   into another disposable library. Test print and Save to PDF, then cancel a
   print dialog. Compare PDF output and original song/setlist content.
8. Check plain/formatted copy in an existing suitable target application with an
   agreed clipboard slot. Preserve the user's clipboard; synthetic helper tests
   do not establish real paste acceptance.
9. Exercise representative public provider searches with the Windows transport.
   Confirm HTTPS trust and redirects, error recovery, concurrent results and
   final responses after HTTP 103. Save diagnostic status and timing without
   cookies, bearer tokens or credential-bearing URLs.
10. After the Desktop OAuth client is configured, the user performs any required
    account authentication/consent. Verify same-account sync, native Drive folder
    selection and ChordPro import, app restart/silent renewal, offline recovery,
    revoked permission and sign-out against a disposable test library/account.
    Never automate authentication or replace a real remote library for a check.

Record each outcome as passed, failed or not run, with its evidence path.
Do not claim parity while any required area is failed or not run.
