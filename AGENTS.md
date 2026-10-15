# Singbook contributor instructions

This repository contains the Flutter mobile app. The Dart package is `singbook`
and the Android application ID and iOS bundle ID are `org.freevia.singbook`.
Earlier test installs used `org.freevia.verse`; preserve their data and use
explicit library export/import when moving to the release app. Keep existing
database names and `x_verse` ChordPro payloads, timing, and provenance compatible.

## Development

- Localize user-facing strings in the ARBs under `lib/l10n`. Regenerate Dart
  output with `flutter gen-l10n` after integrating the source translations.
- Preserve themes, text scaling, accessibility, RTL behavior, phone/tablet
  layouts, and portrait/landscape support.
- Use `scripts/build-android.ps1` for Android builds. Keep ignored local
  credentials, signing files, generated outputs, and caches out of commits
  and messages.

## Subagents and shared work

- Use subagents for substantial independent tasks when parallel work helps.
  Prefer Luna for bounded implementation, investigation, and review, following
  the user's model preference. Keep one coordinator responsible for integration.
- Give each agent a concrete objective, relevant interfaces, acceptance criteria,
  file ownership, and resource limits. Do not include secrets. Further delegation
  needs the coordinator's assignment.
- Inspect `git status` before editing. Treat pre-existing changes as another
  contributor's work until ownership is clear. Never reset, clean, overwrite,
  or stash shared work without coordination.
- Keep one writer per file and one owner per device/build output directory.
  Reviewers send findings to the owner rather than making competing edits.
  Use isolated worktrees when independent builds or edits require them.
- Coordinate model/interface changes and localization regeneration before
  combining dependent work. Do not duplicate an already completed investigation.
- Report changed files, base commit, validation results, limitations, and whether
  work is ready. Distinguish local preparation from integrated or installed work.
  Explicitly lift temporary file/build/device reservations after handoff.
- Stage only owned, reviewed files. Avoid blanket staging in dirty shared
  checkouts. Do not commit another session's unfinished work.

## Integration and validation

- Use the public repository's current history. Older local Singbook histories
  predate the public repository recreation: port bounded changes onto clean
  history rather than merging or pushing those old refs.
- Review actual diffs and resolve overlaps while preserving accepted behavior.
  Agent reports alone are not sufficient integration evidence.
- Run focused meaningful checks, then appropriate combined checks. Repeat them
  when subsequent changes invalidate results; avoid redundant broad runs.
- Inspect fresh screenshots for visual changes, including compact screens,
  large text, localization, themes, and relevant orientations. Widget geometry
  tests do not replace visual review.
- Keep source commits, test evidence, and built artifacts traceable. Do not
  overwrite verified artifacts with stale or overlapping builds.
- Report actual checks and material limitations. Account for outstanding
  delegated work before claiming completion.

## Android devices

- Run `adb devices` first and reuse the existing emulator when available.
- Coordinate physical-device use with its current owner. Preserve app data;
  do not uninstall or clear a physical app to work around an install failure.
- Serialize operations sharing build directories or device state. Do not stop
  unrelated processes or reset an ADB server used by another session.
